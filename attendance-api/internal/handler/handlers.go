package handler

import (
	"attendance-api/internal/client"
	"attendance-api/internal/config"
	"attendance-api/internal/service"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

type Handler struct {
	faceClient        *client.FaceRecognitionClient
	attendanceService *service.AttendanceService
	config            *config.Config
}

func NewHandler(faceClient *client.FaceRecognitionClient, attendanceService *service.AttendanceService, cfg *config.Config) *Handler {
	return &Handler{
		faceClient:        faceClient,
		attendanceService: attendanceService,
		config:            cfg,
	}
}

func (h *Handler) ListFaces(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	faces, err := h.faceClient.GetFaces(r.Context())
	if err != nil {
		fmt.Printf("ERROR: Failed to get faces: %v\n", err)
		h.jsonError(w, "Failed to get faces", http.StatusInternalServerError)
		return
	}

	h.jsonResponse(w, map[string]interface{}{
		"success": true,
		"count":   len(faces),
		"faces":   faces,
	}, http.StatusOK)
}

func (h *Handler) UploadFaces(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	fmt.Printf("DEBUG: Starting face upload\n")

	if err := r.ParseMultipartForm(h.config.Upload.MaxMemory); err != nil {
		fmt.Printf("ERROR: Failed to parse multipart form: %v\n", err)
		h.jsonError(w, "Failed to parse form", http.StatusBadRequest)
		return
	}

	name := r.FormValue("name")
	if name == "" {
		fmt.Printf("ERROR: Name is missing\n")
		h.jsonError(w, "Name is required", http.StatusBadRequest)
		return
	}

	fmt.Printf("DEBUG: Name=%s\n", name)

	files := r.MultipartForm.File["images"]
	if len(files) == 0 {
		fmt.Printf("ERROR: No images in request\n")
		h.jsonError(w, "At least one image is required", http.StatusBadRequest)
		return
	}

	fmt.Printf("DEBUG: Received %d images\n", len(files))

	var images [][]byte
	var filenames []string

	for _, fileHeader := range files {
		if fileHeader.Size > h.config.Upload.MaxUploadSize {
			fmt.Printf("ERROR: File %s too large: %d bytes\n", fileHeader.Filename, fileHeader.Size)
			h.jsonError(w, fmt.Sprintf("File %s exceeds maximum size of 5MB", fileHeader.Filename), http.StatusBadRequest)
			return
		}

		file, err := fileHeader.Open()
		if err != nil {
			fmt.Printf("ERROR: Failed to open file %s: %v\n", fileHeader.Filename, err)
			h.jsonError(w, "Failed to open file", http.StatusInternalServerError)
			return
		}
		defer file.Close()

		data, err := io.ReadAll(file)
		if err != nil {
			fmt.Printf("ERROR: Failed to read file %s: %v\n", fileHeader.Filename, err)
			h.jsonError(w, "Failed to read file", http.StatusInternalServerError)
			return
		}

		images = append(images, data)
		filenames = append(filenames, fileHeader.Filename)
	}

	fmt.Printf("DEBUG: Calling face API to add face...\n")

	if err := h.faceClient.AddFace(r.Context(), name, images, filenames); err != nil {
		fmt.Printf("ERROR: Failed to add face: %v\n", err)
		h.jsonError(w, fmt.Sprintf("Failed to add face: %v", err), http.StatusInternalServerError)
		return
	}

	fmt.Printf("DEBUG: Successfully added face for %s\n", name)

	h.jsonResponse(w, map[string]interface{}{
		"success":      true,
		"message":      fmt.Sprintf("Successfully added %d image(s) for %s", len(images), name),
		"name":         name,
		"images_added": len(images),
	}, http.StatusCreated)
}

func (h *Handler) RecordAttendance(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if err := r.ParseMultipartForm(h.config.Upload.MaxMemory); err != nil {
		h.jsonError(w, "Failed to parse form", http.StatusBadRequest)
		return
	}

	file, fileHeader, err := r.FormFile("image")
	if err != nil {
		h.jsonError(w, "Image is required", http.StatusBadRequest)
		return
	}
	defer file.Close()

	if fileHeader.Size > h.config.Upload.MaxUploadSize {
		h.jsonError(w, "File exceeds maximum size of 5MB", http.StatusBadRequest)
		return
	}

	imageData, err := io.ReadAll(file)
	if err != nil {
		h.jsonError(w, "Failed to read image", http.StatusInternalServerError)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), h.config.FaceAPI.Timeout)
	defer cancel()

	response, err := h.attendanceService.RecordAttendance(ctx, imageData, fileHeader.Filename)
	if err != nil {
		fmt.Printf("Attendance error: %v\n", err)
	}

	statusCode := http.StatusOK
	if response != nil {
		h.jsonResponse(w, response, statusCode)
	} else {
		h.jsonError(w, "Failed to process attendance", http.StatusInternalServerError)
	}
}

func (h *Handler) AttendanceStream(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "Streaming not supported", http.StatusInternalServerError)
		return
	}

	messageChan := h.attendanceService.Subscribe()
	defer h.attendanceService.Unsubscribe(messageChan)

	ctx := r.Context()

	for {
		select {
		case <-ctx.Done():
			return
		case msg := <-messageChan:
			data, err := json.Marshal(msg.Data)
			if err != nil {
				continue
			}

			fmt.Fprintf(w, "event: %s\n", msg.Event)
			fmt.Fprintf(w, "data: %s\n\n", data)
			flusher.Flush()
		}
	}
}

func (h *Handler) GetRecentAttendance(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	limit := 50
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if parsed, err := fmt.Sscanf(limitStr, "%d", &limit); err == nil && parsed == 1 {
			if limit > 1000 {
				limit = 1000
			}
		}
	}

	records, err := h.attendanceService.GetRecentAttendance(limit)
	if err != nil {
		h.jsonError(w, "Failed to get attendance records", http.StatusInternalServerError)
		return
	}

	h.jsonResponse(w, map[string]interface{}{
		"success": true,
		"count":   len(records),
		"records": records,
	}, http.StatusOK)
}

func (h *Handler) GetAttendanceStats(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	stats, err := h.attendanceService.GetAttendanceStats()
	if err != nil {
		h.jsonError(w, "Failed to get statistics", http.StatusInternalServerError)
		return
	}

	h.jsonResponse(w, map[string]interface{}{
		"success": true,
		"stats":   stats,
	}, http.StatusOK)
}

func (h *Handler) jsonResponse(w http.ResponseWriter, data interface{}, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

func (h *Handler) jsonError(w http.ResponseWriter, message string, statusCode int) {
	h.jsonResponse(w, map[string]interface{}{
		"success": false,
		"error":   message,
	}, statusCode)
}
