package domain

import "time"

// Face represents a known person in the system
type Face struct {
	Name   string `json:"name"`
	Images int    `json:"images"`
}

// RecognitionResult represents the response from face recognition API
type RecognitionResult struct {
	Success       bool             `json:"success"`
	FacesDetected int              `json:"faces_detected"`
	Faces         []RecognizedFace `json:"faces"`
}

// RecognizedFace represents a single recognized face
type RecognizedFace struct {
	Name       string       `json:"name"`
	Confidence float64      `json:"confidence"`
	Location   FaceLocation `json:"location"`
}

// FaceLocation represents the bounding box of a face
type FaceLocation struct {
	Top    int `json:"top"`
	Right  int `json:"right"`
	Bottom int `json:"bottom"`
	Left   int `json:"left"`
}

// AttendanceRecord represents a single attendance entry
type AttendanceRecord struct {
	ID         string    `json:"id"`
	Name       string    `json:"name"`
	Confidence float64   `json:"confidence"`
	Timestamp  time.Time `json:"timestamp"`
	Status     string    `json:"status"` // "authorized" or "unauthorized"
}

// AttendanceResponse represents the response sent to Arduino
type AttendanceResponse struct {
	Success    bool    `json:"success"`
	Authorized bool    `json:"authorized"`
	Name       string  `json:"name,omitempty"`
	Confidence float64 `json:"confidence,omitempty"`
	Message    string  `json:"message"`
	Action     string  `json:"action"` // "open_door" or "keep_closed"
}

// SSEMessage represents a server-sent event message
type SSEMessage struct {
	Event string           `json:"event"`
	Data  AttendanceRecord `json:"data"`
}
