# Face Recognition System

A simple but highly accurate face recognition system built with Python. This project uses the `face_recognition` library (based on dlib's state-of-the-art deep learning model with **99.38% accuracy** on the LFW benchmark) and is optimized to run on Linux VPS.

## Features

✅ **High Accuracy**: Uses industry-standard face recognition models  
✅ **Simple to Use**: Clean API with minimal configuration  
✅ **VPS-Ready**: Optimized for headless Linux servers  
✅ **Fast Processing**: Caching system for known face encodings  
✅ **Multiple Modes**: Image-based and real-time webcam recognition  
✅ **Confidence Scores**: Get matching confidence for each recognition

## Prerequisites

- Python 3.7+
- Linux-based system (Ubuntu, Debian, CentOS, etc.)
- For webcam mode: Camera and display

### System Dependencies (Linux VPS)

Before installing Python packages, install these system dependencies:

#### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y python3-pip python3-dev build-essential cmake
sudo apt-get install -y libopenblas-dev liblapack-dev libx11-dev libgtk-3-dev
```

#### CentOS/RHEL:
```bash
sudo yum update
sudo yum install -y python3-pip python3-devel gcc gcc-c++ cmake
sudo yum install -y openblas-devel lapack-devel libX11-devel gtk3-devel
```

## Installation

### 1. Clone or Download This Project

```bash
cd /path/to/project
```

### 2. Create Virtual Environment (Recommended)

```bash
python3 -m venv venv
source venv/bin/activate  # On Linux
```

### 3. Install Python Dependencies

```bash
pip install -r requirements.txt
```

**Note**: Installation may take 5-10 minutes as it compiles dlib from source.

### 4. Verify Installation

```bash
python3 -c "import face_recognition; print('✓ Installation successful!')"
```

## Quick Start

### Step 1: Add Known Faces

Create a `known_faces` directory and add images of people you want to recognize:

```bash
mkdir -p known_faces
```

Add images with the person's name as the filename:
```
known_faces/
├── john_doe.jpg
├── jane_smith.png
└── bob_johnson.jpg
```

**Important**: 
- Each image should contain only ONE face
- Use clear, front-facing photos
- Supported formats: JPG, JPEG, PNG, BMP
- Filename (without extension) will be used as the person's name

### Step 2: Recognize Faces in Images

```bash
python3 recognize_image.py path/to/test_image.jpg
```

The script will:
1. Load known faces from `known_faces/` directory
2. Detect and recognize faces in the test image
3. Print results with confidence scores
4. Save annotated image with bounding boxes

### Step 3 (Optional): Real-time Webcam Recognition

```bash
python3 recognize_webcam.py
```

Press `q` to quit the webcam view.

## Usage Examples

### Basic Image Recognition

```bash
python3 recognize_image.py photo.jpg
```

### Custom Tolerance (Stricter Matching)

```bash
python3 recognize_image.py photo.jpg --tolerance 0.5
```

Lower tolerance = stricter matching (default: 0.6)

### Using Different Camera

```bash
python3 recognize_webcam.py --camera 1
```

## Using in Your Own Code

```python
from face_recognizer import FaceRecognizer

# Initialize
recognizer = FaceRecognizer(known_faces_dir="known_faces", tolerance=0.6)

# Load known faces (cached for performance)
recognizer.load_known_faces()

# Recognize faces in an image
results = recognizer.recognize_faces("test_image.jpg")

for result in results:
    print(f"Name: {result['name']}")
    print(f"Confidence: {result['confidence']:.2f}%")
    print(f"Location: {result['location']}")

# Draw results and save
output_path = recognizer.draw_results("test_image.jpg", "output.jpg")
```

## VPS Deployment Guide

### Running on Headless VPS (No Display)

The project is optimized for VPS environments without a display. Use image-based recognition:

```bash
# Process uploaded images
python3 recognize_image.py uploaded_photo.jpg
```

### API Server Example (Flask)

Create a simple API server for face recognition:

```bash
pip install flask
```

```python
# api_server.py
from flask import Flask, request, jsonify
from face_recognizer import FaceRecognizer
import os

app = Flask(__name__)
recognizer = FaceRecognizer()
recognizer.load_known_faces()

@app.route('/recognize', methods=['POST'])
def recognize():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    
    file = request.files['image']
    temp_path = '/tmp/temp_image.jpg'
    file.save(temp_path)
    
    try:
        results = recognizer.recognize_faces(temp_path)
        return jsonify({'faces': results})
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

Run the API:
```bash
python3 api_server.py
```

Test it:
```bash
curl -X POST -F "image=@test.jpg" http://localhost:5000/recognize
```

### Security Considerations for VPS

1. **Firewall**: Only expose necessary ports
2. **Authentication**: Add API authentication for production
3. **Rate Limiting**: Implement rate limiting for API endpoints
4. **HTTPS**: Use SSL/TLS in production
5. **Input Validation**: Validate uploaded images

### Performance Optimization for VPS

1. **Use caching**: Face encodings are automatically cached in `face_encodings.pkl`
2. **Batch processing**: Process multiple images in sequence
3. **Image resizing**: Resize large images before processing
4. **Model selection**: The project uses "hog" model (faster, CPU-friendly). For GPU servers, you can switch to "cnn" model for better accuracy

## Project Structure

```
face/
├── face_recognizer.py      # Main face recognition module
├── recognize_image.py      # CLI script for image recognition
├── recognize_webcam.py     # CLI script for webcam recognition
├── requirements.txt        # Python dependencies
├── known_faces/           # Directory for known face images
│   ├── person1.jpg
│   └── person2.jpg
├── face_encodings.pkl     # Cached encodings (auto-generated)
└── README.md             # This file
```

## Troubleshooting

### Installation Issues

**Problem**: `dlib` compilation fails

**Solution**: Ensure you have build tools installed:
```bash
sudo apt-get install build-essential cmake
```

**Problem**: `No module named 'face_recognition'`

**Solution**: Activate virtual environment and reinstall:
```bash
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Recognition Issues

**Problem**: "No face found" in known faces

**Solution**: 
- Ensure images are clear and front-facing
- Check image quality and lighting
- Verify only one face per image

**Problem**: False positives or low accuracy

**Solution**:
- Decrease tolerance: `--tolerance 0.5` (stricter)
- Use higher quality images for known faces
- Ensure consistent lighting conditions

**Problem**: Slow performance on VPS

**Solution**:
- Use image caching (automatic)
- Resize large images before processing
- Consider upgrading VPS specs

## Technical Details

### Accuracy
- **Face Detection**: Uses HOG (Histogram of Oriented Gradients) for fast CPU-based detection
- **Face Recognition**: Deep learning model with 99.38% accuracy on LFW (Labeled Faces in the Wild) benchmark
- **Distance Metric**: Uses 128-dimensional face encodings with Euclidean distance

### Performance
- **Face Detection**: ~100-300ms per image (depending on size)
- **Face Recognition**: ~30-50ms per face
- **Encoding Cache**: Subsequent loads are instant

### Memory Usage
- Base memory: ~100-200MB
- Per known face: ~1KB (cached encoding)
- Per image processed: 10-50MB (temporary)

## API Reference

### FaceRecognizer Class

#### `__init__(known_faces_dir="known_faces", tolerance=0.6)`
Initialize the face recognizer.

#### `load_known_faces(force_reload=False)`
Load known faces from directory or cache.

#### `recognize_faces(image_path)`
Recognize faces in an image file.
Returns: List of dicts with 'name', 'location', 'confidence'

#### `recognize_faces_from_array(image_array)`
Recognize faces from numpy array (for video frames).

#### `draw_results(image_path, output_path=None)`
Draw bounding boxes and labels on image.

## License

This project is open source. The `face_recognition` library is licensed under MIT.

## Credits

Built with:
- [face_recognition](https://github.com/ageitgey/face_recognition) by Adam Geitgey
- [dlib](http://dlib.net/) by Davis King
- [OpenCV](https://opencv.org/)

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review the examples
3. Check `face_recognition` library documentation

---

**Ready to use!** Start by adding face images to the `known_faces/` directory and run your first recognition.
