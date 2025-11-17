package service

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"

	"attendance-api/internal/client"
	"attendance-api/internal/domain"

	"github.com/google/uuid"
	_ "github.com/mattn/go-sqlite3"
)

type SSEClient struct {
	id      string
	channel chan domain.SSEMessage
	active  bool
}

type AttendanceService struct {
	faceClient *client.FaceRecognitionClient
	db         *sql.DB
	mu         sync.RWMutex
	clients    map[string]*SSEClient
	ctx        context.Context
	cancel     context.CancelFunc
}

func NewAttendanceService(faceClient *client.FaceRecognitionClient, dbPath string) (*AttendanceService, error) {
	// Ensure directory exists
	dir := filepath.Dir(dbPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create directory: %w", err)
	}

	// Open database
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	ctx, cancel := context.WithCancel(context.Background())

	service := &AttendanceService{
		faceClient: faceClient,
		db:         db,
		clients:    make(map[string]*SSEClient),
		ctx:        ctx,
		cancel:     cancel,
	}

	// Initialize schema
	if err := service.initSchema(); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to initialize schema: %w", err)
	}

	// Start periodic cleanup of stale connections
	go service.cleanupStaleConnections()

	return service, nil
}

func (s *AttendanceService) initSchema() error {
	schema := `
	CREATE TABLE IF NOT EXISTS attendance (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		confidence REAL NOT NULL,
		timestamp DATETIME NOT NULL,
		status TEXT NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);

	CREATE INDEX IF NOT EXISTS idx_attendance_timestamp ON attendance(timestamp DESC);
	CREATE INDEX IF NOT EXISTS idx_attendance_name ON attendance(name);
	CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance(status);
	`

	_, err := s.db.Exec(schema)
	if err != nil {
		return fmt.Errorf("failed to execute schema: %w", err)
	}

	return nil
}

func (s *AttendanceService) Close() error {
	// Cancel cleanup goroutine
	s.cancel()

	// Close all SSE connections
	s.mu.Lock()
	log.Printf("🛑 SSE: Closing %d active connections for shutdown", len(s.clients))
	for clientID, client := range s.clients {
		if client.active {
			client.active = false
			close(client.channel)
			log.Printf("🛑 SSE: Closed client %s", clientID)
		}
		delete(s.clients, clientID)
	}
	s.mu.Unlock()

	return s.db.Close()
}

func (s *AttendanceService) RecordAttendance(ctx context.Context, imageData []byte, filename string) (*domain.AttendanceResponse, error) {
	result, err := s.faceClient.RecognizeFace(ctx, imageData, filename)
	if err != nil {
		return &domain.AttendanceResponse{
			Success:    false,
			Authorized: false,
			Message:    "Failed to recognize face",
			Action:     "keep_closed",
		}, err
	}

	if result.FacesDetected == 0 {
		return &domain.AttendanceResponse{
			Success:    true,
			Authorized: false,
			Message:    "No face detected",
			Action:     "keep_closed",
		}, nil
	}

	face := result.Faces[0]
	authorized := face.Name != "Unknown"
	status := "unauthorized"
	action := "keep_closed"
	message := "Unknown person"

	fmt.Printf("DEBUG: Face name='%s', authorized=%v\n", face.Name, authorized)

	if authorized {
		status = "authorized"
		action = "open_door"
		message = fmt.Sprintf("Welcome, %s", face.Name)
	}

	record := domain.AttendanceRecord{
		ID:         uuid.New().String(),
		Name:       face.Name,
		Confidence: face.Confidence,
		Timestamp:  time.Now(),
		Status:     status,
	}

	if err := s.saveRecord(record); err != nil {
		fmt.Printf("❌ ERROR: Failed to save attendance record: %v\n", err)
	} else {
		fmt.Printf("✅ Saved attendance record: ID=%s, Name=%s, Status=%s\n", record.ID, record.Name, record.Status)
	}

	s.broadcast(domain.SSEMessage{
		Event: "attendance",
		Data:  record,
	})

	return &domain.AttendanceResponse{
		Success:    true,
		Authorized: authorized,
		Name:       face.Name,
		Confidence: face.Confidence,
		Message:    message,
		Action:     action,
	}, nil
}

func (s *AttendanceService) saveRecord(record domain.AttendanceRecord) error {
	query := `
		INSERT INTO attendance (id, name, confidence, timestamp, status)
		VALUES (?, ?, ?, ?, ?)
	`

	_, err := s.db.Exec(query, record.ID, record.Name, record.Confidence, record.Timestamp, record.Status)
	if err != nil {
		return fmt.Errorf("failed to insert record: %w", err)
	}

	return nil
}

func (s *AttendanceService) Subscribe() (string, chan domain.SSEMessage) {
	s.mu.Lock()
	defer s.mu.Unlock()

	clientID := uuid.New().String()[:8] // Short ID for logging
	ch := make(chan domain.SSEMessage, 10)

	client := &SSEClient{
		id:      clientID,
		channel: ch,
		active:  true,
	}

	s.clients[clientID] = client
	log.Printf("📡 SSE: Client %s connected (total: %d)", clientID, len(s.clients))

	return clientID, ch
}

func (s *AttendanceService) Unsubscribe(clientID string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if client, exists := s.clients[clientID]; exists {
		client.active = false
		close(client.channel)
		delete(s.clients, clientID)
		log.Printf("🔌 SSE: Client %s disconnected (remaining: %d)", clientID, len(s.clients))
	} else {
		log.Printf("⚠️ SSE: Attempted to unsubscribe unknown client %s", clientID)
	}
}

func (s *AttendanceService) broadcast(msg domain.SSEMessage) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	successCount := 0
	for clientID, client := range s.clients {
		if !client.active {
			continue
		}

		select {
		case client.channel <- msg:
			successCount++
		default:
			// Channel full or blocked - client might be slow/dead
			log.Printf("⚠️ SSE: Failed to send to client %s (channel full/blocked)", clientID)
		}
	}

	if len(s.clients) > 0 {
		log.Printf("📤 SSE: Broadcast to %d/%d clients", successCount, len(s.clients))
	}
}

func (s *AttendanceService) GetRecentAttendance(limit int) ([]domain.AttendanceRecord, error) {
	query := `
		SELECT id, name, confidence, timestamp, status
		FROM attendance
		ORDER BY timestamp DESC
		LIMIT ?
	`

	rows, err := s.db.Query(query, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query records: %w", err)
	}
	defer rows.Close()

	var records []domain.AttendanceRecord
	for rows.Next() {
		var record domain.AttendanceRecord
		if err := rows.Scan(&record.ID, &record.Name, &record.Confidence, &record.Timestamp, &record.Status); err != nil {
			return nil, fmt.Errorf("failed to scan record: %w", err)
		}
		records = append(records, record)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return records, nil
}

func (s *AttendanceService) GetAttendanceByName(name string, limit int) ([]domain.AttendanceRecord, error) {
	query := `
		SELECT id, name, confidence, timestamp, status
		FROM attendance
		WHERE name = ?
		ORDER BY timestamp DESC
		LIMIT ?
	`

	rows, err := s.db.Query(query, name, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query records: %w", err)
	}
	defer rows.Close()

	var records []domain.AttendanceRecord
	for rows.Next() {
		var record domain.AttendanceRecord
		if err := rows.Scan(&record.ID, &record.Name, &record.Confidence, &record.Timestamp, &record.Status); err != nil {
			return nil, fmt.Errorf("failed to scan record: %w", err)
		}
		records = append(records, record)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return records, nil
}

func (s *AttendanceService) GetAttendanceStats() (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	// Total records
	var total int
	err := s.db.QueryRow("SELECT COUNT(*) FROM attendance").Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to get total count: %w", err)
	}
	stats["total"] = total

	// Authorized vs Unauthorized
	var authorized, unauthorized int
	err = s.db.QueryRow("SELECT COUNT(*) FROM attendance WHERE status = 'authorized'").Scan(&authorized)
	if err != nil {
		return nil, fmt.Errorf("failed to get authorized count: %w", err)
	}
	err = s.db.QueryRow("SELECT COUNT(*) FROM attendance WHERE status = 'unauthorized'").Scan(&unauthorized)
	if err != nil {
		return nil, fmt.Errorf("failed to get unauthorized count: %w", err)
	}
	stats["authorized"] = authorized
	stats["unauthorized"] = unauthorized

	// Unique people
	var uniquePeople int
	err = s.db.QueryRow("SELECT COUNT(DISTINCT name) FROM attendance WHERE status = 'authorized'").Scan(&uniquePeople)
	if err != nil {
		return nil, fmt.Errorf("failed to get unique people: %w", err)
	}
	stats["unique_people"] = uniquePeople

	return stats, nil
}

func (s *AttendanceService) GetSSEStats() map[string]interface{} {
	s.mu.RLock()
	defer s.mu.RUnlock()

	activeClients := 0
	for _, client := range s.clients {
		if client.active {
			activeClients++
		}
	}

	return map[string]interface{}{
		"total_clients":  len(s.clients),
		"active_clients": activeClients,
	}
}

// Periodic cleanup of stale connections (called as goroutine)
func (s *AttendanceService) cleanupStaleConnections() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-s.ctx.Done():
			log.Println("🛑 SSE: Cleanup goroutine stopped")
			return
		case <-ticker.C:
			s.mu.Lock()
			before := len(s.clients)

			// Remove inactive clients
			for clientID, client := range s.clients {
				if !client.active {
					delete(s.clients, clientID)
					log.Printf("🧹 SSE: Cleaned up inactive client %s", clientID)
				}
			}

			after := len(s.clients)
			if before != after {
				log.Printf("🧹 SSE: Cleanup removed %d stale clients (%d → %d)", before-after, before, after)
			}

			s.mu.Unlock()
		}
	}
}
