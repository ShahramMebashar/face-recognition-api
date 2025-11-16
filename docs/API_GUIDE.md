# Face Recognition API - Quick Reference

## 🚀 Start the API Server

```bash
# Activate virtual environment
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate     # Windows

# Install Flask (if not already installed)
pip install flask werkzeug

# Start server
python api_server.py
```

Server will run on: **http://localhost:5000**

---

## 📡 API Endpoints

### 1. Health Check
**GET** `/health`

Check if server is running and see loaded faces.

**Example:**
```bash
curl http://localhost:5000/health
```

**Response:**
```json
{
  "status": "ok",
  "service": "Face Recognition API",
  "known_faces": 3,
  "total_encodings": 8
}
```

---

### 2. Recognize Faces
**POST** `/recognize`

Upload an image and get face recognition results.

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body: Image file with key `image`

**Example:**
```bash
curl -X POST -F "image=@photo.jpg" http://localhost:5000/recognize
```

**Success Response (200):**
```json
{
  "success": true,
  "faces_detected": 2,
  "faces": [
    {
      "name": "john_doe",
      "confidence": 94.52,
      "location": {
        "top": 120,
        "right": 350,
        "bottom": 280,
        "left": 190
      }
    },
    {
      "name": "jane_smith",
      "confidence": 89.73,
      "location": {
        "top": 140,
        "right": 580,
        "bottom": 300,
        "left": 420
      }
    }
  ]
}
```

**No Faces Detected (200):**
```json
{
  "success": true,
  "faces_detected": 0,
  "faces": []
}
```

**Unknown Face (200):**
```json
{
  "success": true,
  "faces_detected": 1,
  "faces": [
    {
      "name": "Unknown",
      "confidence": 0,
      "location": {
        "top": 100,
        "right": 300,
        "bottom": 260,
        "left": 140
      }
    }
  ]
}
```

**Error Response (400):**
```json
{
  "success": false,
  "error": "No image file provided",
  "message": "Please upload an image file with key 'image'"
}
```

---

### 3. List Known Faces
**GET** `/faces`

Get list of all known people in the system.

**Example:**
```bash
curl http://localhost:5000/faces
```

**Response:**
```json
{
  "success": true,
  "total_people": 3,
  "total_images": 8,
  "people": [
    {
      "name": "jane_smith",
      "images": 3
    },
    {
      "name": "john_doe",
      "images": 4
    },
    {
      "name": "mike_jones",
      "images": 1
    }
  ]
}
```

---

## 💻 Usage Examples

### Using cURL

```bash
# Test health
curl http://localhost:5000/health

# List known faces
curl http://localhost:5000/faces

# Recognize faces in image
curl -X POST -F "image=@test.jpg" http://localhost:5000/recognize

# Save response to file
curl -X POST -F "image=@test.jpg" http://localhost:5000/recognize -o result.json
```

### Using Python (requests)

```python
import requests

# Health check
response = requests.get('http://localhost:5000/health')
print(response.json())

# Recognize faces
with open('photo.jpg', 'rb') as f:
    files = {'image': f}
    response = requests.post('http://localhost:5000/recognize', files=files)
    result = response.json()
    
    if result['success']:
        print(f"Found {result['faces_detected']} face(s)")
        for face in result['faces']:
            print(f"  - {face['name']}: {face['confidence']:.2f}%")
    else:
        print(f"Error: {result['error']}")
```

### Using JavaScript (fetch)

```javascript
const formData = new FormData();
formData.append('image', fileInput.files[0]);

fetch('http://localhost:5000/recognize', {
    method: 'POST',
    body: formData
})
.then(response => response.json())
.then(data => {
    console.log(`Found ${data.faces_detected} face(s)`);
    data.faces.forEach(face => {
        console.log(`${face.name}: ${face.confidence}%`);
    });
});
```

---

## 🔧 Configuration

Edit in `api_server.py`:

```python
# Allowed file types
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'bmp'}

# Max upload size (16MB)
MAX_FILE_SIZE = 16 * 1024 * 1024

# Recognition tolerance (0.6 = default)
recognizer = FaceRecognizer(tolerance=0.6)

# Server host and port
app.run(host='0.0.0.0', port=5000)
```

---

## 🌐 Deploy to VPS

```bash
# Install production WSGI server
pip install gunicorn

# Run with Gunicorn (production)
gunicorn -w 4 -b 0.0.0.0:5000 api_server:app

# Run in background
nohup gunicorn -w 4 -b 0.0.0.0:5000 api_server:app > api.log 2>&1 &
```

---

## ⚠️ Error Codes

| Code | Meaning | Example |
|------|---------|---------|
| 200 | Success | Face recognized successfully |
| 400 | Bad Request | No image file or invalid format |
| 404 | Not Found | Invalid endpoint |
| 413 | Too Large | File exceeds 16MB |
| 500 | Server Error | Processing failed |
| 503 | Service Unavailable | No known faces loaded |

---

## 📝 Response Structure

All responses follow this structure:

```json
{
  "success": true/false,
  "faces_detected": 0,        // Only in /recognize
  "faces": [...],             // Only in /recognize
  "error": "error_type",      // Only on failure
  "message": "details"        // Only on failure
}
```
