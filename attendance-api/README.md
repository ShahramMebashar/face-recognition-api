# Attendance API

Go-based REST API for face recognition attendance system that integrates with the Python face recognition service.

## Features

- ✅ Stdlib HTTP router and server (no external routing frameworks)
- ✅ Graceful shutdown with signal handling
- ✅ Configuration via .env or Viper
- ✅ SQLite database for efficient attendance storage
- ✅ Automatic schema initialization on startup
- ✅ Docker support with multi-stage builds
- ✅ Real-time Server-Sent Events (SSE) for attendance updates
- ✅ Integration with Python face recognition API
- ✅ Arduino-friendly responses for IoT devices
- ✅ Clean, modular, idiomatic Go code

## Architecture

```
attendance-api/
├── cmd/
│   └── server/
│       └── main.go              # Entry point with graceful shutdown
├── internal/
│   ├── config/
│   │   └── config.go            # Viper configuration
│   ├── domain/
│   │   └── models.go            # Data models
│   ├── client/
│   │   └── face_client.go       # Face recognition API client
│   ├── service/
│   │   └── attendance.go        # Business logic & SSE
│   └── handler/
│       └── handlers.go          # HTTP handlers
├── data/                         # Attendance logs
├── .env                         # Configuration
├── Dockerfile                   # Production Docker image
└── docker-compose.yml           # Multi-service deployment
```

## Quick Start

### 1. Install Dependencies

```bash
cd attendance-api
go mod download
```

### 2. Configure Environment

Copy `.env.example` to `.env` and adjust settings:

```bash
cp .env.example .env
```

Default configuration:
- Server: `0.0.0.0:8080`
- Face API: `http://localhost:5001`
- Max upload: 5MB per image

### 3. Run Locally

```bash
go run cmd/server/main.go
```

### 4. Run with Docker

Build and run:
```bash
docker build -t attendance-api .
docker run -p 8080:8080 \
  -e FACE_API_URL=http://host.docker.internal:5001 \
  -e ATTENDANCE_DB_PATH=/app/data/attendance.db \
  -v $(pwd)/data:/app/data \
  attendance-api
```

Or use docker-compose (with face recognition API):
```bash
docker-compose up -d
```

**Environment Variables (all optional, defaults provided):**
- `SERVER_PORT=8080`
- `SERVER_HOST=0.0.0.0`
- `FACE_API_URL=http://localhost:5001`
- `FACE_API_TIMEOUT=30s`
- `MAX_UPLOAD_SIZE=5242880`
- `MAX_MEMORY=10485760`
- `ATTENDANCE_DB_PATH=/app/data/attendance.db`

## API Endpoints

### 1. List Known Faces
```bash
GET /api/faces
```

**Response:**
```json
{
  "success": true,
  "count": 2,
  "faces": [
    {"name": "john_doe", "images": 3},
    {"name": "jane_smith", "images": 2}
  ]
}
```

### 2. Upload New Faces
```bash
POST /api/faces/upload
Content-Type: multipart/form-data

Fields:
  - name: string (required)
  - images: file[] (required, max 5MB each)
```

**Example (curl):**
```bash
curl -X POST http://localhost:8080/api/faces/upload \
  -F "name=alice" \
  -F "images=@photo1.jpg" \
  -F "images=@photo2.jpg"
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully added 2 image(s) for alice",
  "name": "alice",
  "images_added": 2
}
```

### 3. Record Attendance (Arduino Endpoint)
```bash
POST /api/attendance
Content-Type: multipart/form-data

Fields:
  - image: file (required, max 5MB)
```

**Example:**
```bash
curl -X POST http://localhost:8080/api/attendance \
  -F "image=@person.jpg"
```

**Response (Authorized):**
```json
{
  "success": true,
  "authorized": true,
  "name": "john_doe",
  "confidence": 95.23,
  "message": "Welcome, john_doe",
  "action": "open_door"
}
```

**Response (Unauthorized):**
```json
{
  "success": true,
  "authorized": false,
  "message": "Unknown person",
  "action": "keep_closed"
}
```

**Response (No Face):**
```json
{
  "success": true,
  "authorized": false,
  "message": "No face detected",
  "action": "keep_closed"
}
```

### 4. Real-time Attendance Stream (SSE)
```bash
GET /api/attendance/stream
```

**Example (JavaScript):**
```javascript
const eventSource = new EventSource('http://localhost:8080/api/attendance/stream');

eventSource.addEventListener('attendance', (event) => {
  const data = JSON.parse(event.data);
  console.log('New attendance:', data);
  // {
  //   "id": "uuid",
  //   "name": "john_doe",
  //   "confidence": 95.23,
  //   "timestamp": "2025-11-16T10:30:00Z",
  //   "status": "authorized"
  // }
});
```

**Example (curl):**
```bash
curl -N http://localhost:8080/api/attendance/stream
```

### 5. Get Recent Attendance Records
```bash
GET /api/attendance/recent?limit=50
```

**Response:**
```json
{
  "success": true,
  "count": 10,
  "records": [
    {
      "id": "uuid",
      "name": "john_doe",
      "confidence": 95.23,
      "timestamp": "2025-11-16T10:30:00Z",
      "status": "authorized"
    }
  ]
}
```

### 6. Get Attendance Statistics
```bash
GET /api/attendance/stats
```

**Response:**
```json
{
  "success": true,
  "stats": {
    "total": 150,
    "authorized": 142,
    "unauthorized": 8,
    "unique_people": 12
  }
}
```

### 7. Health Check
```bash
GET /health
```

**Response:**
```json
{
  "status": "ok",
  "service": "Attendance API"
}
```

## Arduino Integration

### Example ESP32/Arduino Code

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

const char* serverUrl = "http://192.168.1.100:8080/api/attendance";
const int doorPin = 2; // GPIO pin for door lock

void sendAttendance(uint8_t* imageData, size_t imageSize) {
  HTTPClient http;
  http.begin(serverUrl);
  
  // Create multipart form data
  String boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW";
  String contentType = "multipart/form-data; boundary=" + boundary;
  
  http.addHeader("Content-Type", contentType);
  
  // Build multipart body
  String body = "--" + boundary + "\r\n";
  body += "Content-Disposition: form-data; name=\"image\"; filename=\"capture.jpg\"\r\n";
  body += "Content-Type: image/jpeg\r\n\r\n";
  
  // Send request
  http.POST((uint8_t*)(body.c_str()), body.length());
  http.POST(imageData, imageSize);
  http.POST((uint8_t*)("\r\n--" + boundary + "--\r\n").c_str(), 
            ("\r\n--" + boundary + "--\r\n").length());
  
  int httpCode = http.GET();
  
  if (httpCode == 200) {
    String payload = http.getString();
    
    StaticJsonDocument<512> doc;
    deserializeJson(doc, payload);
    
    bool authorized = doc["authorized"];
    String action = doc["action"];
    
    if (authorized && action == "open_door") {
      digitalWrite(doorPin, HIGH); // Open door
      delay(3000);
      digitalWrite(doorPin, LOW);  // Close door
    }
  }
  
  http.end();
}
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_PORT` | `8080` | API server port |
| `SERVER_HOST` | `0.0.0.0` | Bind address |
| `FACE_API_URL` | `http://localhost:5001` | Face recognition API URL |
| `FACE_API_TIMEOUT` | `30s` | Request timeout |
| `MAX_UPLOAD_SIZE` | `5242880` | Max file size (5MB) |
| `MAX_MEMORY` | `10485760` | Max memory for form parsing (10MB) |
| `ATTENDANCE_DB_PATH` | `./data/attendance.db` | SQLite database path |

### Using Viper Config File

Create `config.yaml`:

```yaml
server:
  port: "8080"
  host: "0.0.0.0"

faceapi:
  url: "http://localhost:5001"
  timeout: "30s"

upload:
  maxuploadsize: 5242880
  maxmemory: 10485760

attendance:
  logfile: "./data/attendance.json"
```

## Production Deployment

### Docker Compose (Recommended)

Deploy both services together:

```bash
docker-compose up -d
```

### Standalone Docker

```bash
# Build
docker build -t attendance-api .

# Run
docker run -d \
  --name attendance-api \
  -p 8080:8080 \
  -e FACE_API_URL=http://face-api:5001 \
  -e ATTENDANCE_DB_PATH=/app/data/attendance.db \
  -v $(pwd)/data:/app/data \
  --restart unless-stopped \
  attendance-api
```

### systemd Service

Create `/etc/systemd/system/attendance-api.service`:

```ini
[Unit]
Description=Attendance API Service
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/attendance-api
ExecStart=/opt/attendance-api/attendance-api
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable attendance-api
sudo systemctl start attendance-api
```

## Testing

### Test with curl

```bash
# Health check
curl http://localhost:8080/health

# List faces
curl http://localhost:8080/api/faces

# Upload face
curl -X POST http://localhost:8080/api/faces/upload \
  -F "name=test_user" \
  -F "images=@photo.jpg"

# Record attendance
curl -X POST http://localhost:8080/api/attendance \
  -F "image=@person.jpg"

# Stream attendance (keep connection open)
curl -N http://localhost:8080/api/attendance/stream
```

### Test SSE with JavaScript

```html
<!DOCTYPE html>
<html>
<head>
  <title>Attendance Monitor</title>
</head>
<body>
  <h1>Real-time Attendance</h1>
  <div id="logs"></div>
  
  <script>
    const logs = document.getElementById('logs');
    const eventSource = new EventSource('http://localhost:8080/api/attendance/stream');
    
    eventSource.addEventListener('attendance', (event) => {
      const data = JSON.parse(event.data);
      const entry = document.createElement('div');
      entry.textContent = `${data.timestamp}: ${data.name} - ${data.status}`;
      logs.prepend(entry);
    });
  </script>
</body>
</html>
```

## Development

### Build

```bash
go build -o bin/attendance-api cmd/server/main.go
```

### Run Tests

```bash
go test ./...
```

### Format Code

```bash
go fmt ./...
```

### Check for Issues

```bash
go vet ./...
```

## Troubleshooting

### Cannot connect to face recognition API

Check that the Python face recognition API is running:
```bash
curl http://localhost:5001/health
```

Update `FACE_API_URL` in `.env` if needed.

### Permission denied on data directory

```bash
mkdir -p data
chmod 755 data
```

### Port already in use

Change `SERVER_PORT` in `.env`:
```bash
SERVER_PORT=8081
```

## License

MIT License - free for commercial and personal use.
