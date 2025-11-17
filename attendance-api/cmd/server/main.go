package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"attendance-api/internal/client"
	"attendance-api/internal/config"
	"attendance-api/internal/handler"
	"attendance-api/internal/service"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	faceClient := client.NewFaceRecognitionClient(cfg.FaceAPI.URL, cfg.FaceAPI.Timeout)
	attendanceService, err := service.NewAttendanceService(faceClient, cfg.Attendance.DBPath)
	if err != nil {
		log.Fatalf("Failed to initialize attendance service: %v", err)
	}
	defer attendanceService.Close()

	h := handler.NewHandler(faceClient, attendanceService, cfg)

	mux := http.NewServeMux()
	mux.HandleFunc("/api/faces", h.ListFaces)
	mux.HandleFunc("/api/faces/upload", h.UploadFaces)
	mux.HandleFunc("/api/attendance", h.RecordAttendance)
	mux.HandleFunc("/api/attendance/stream", h.AttendanceStream)
	mux.HandleFunc("/api/attendance/recent", h.GetRecentAttendance)
	mux.HandleFunc("/api/attendance/stats", h.GetAttendanceStats)
	mux.HandleFunc("/health", healthCheck)

	server := &http.Server{
		Addr:         fmt.Sprintf("%s:%s", cfg.Server.Host, cfg.Server.Port),
		Handler:      loggingMiddleware(corsMiddleware(mux)),
		ReadTimeout:  25 * time.Second,
		WriteTimeout: 0, // Disable write timeout for SSE streaming
		IdleTimeout:  120 * time.Second,
	}

	go func() {
		log.Printf("Starting server on %s", server.Addr)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, `{"status":"ok","service":"Attendance API"}`)
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.RequestURI, time.Since(start))
	})
}
