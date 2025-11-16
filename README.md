# Face Recognition System

Simple, accurate face recognition API for Linux VPS deployment.

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Add known faces
python scripts/add_faces.py

# Start API server
python run_server.py
```

API runs on: `http://localhost:5001`

## API Endpoints

- `GET /health` - Server status
- `GET /faces` - List known people
- `POST /recognize` - Recognize faces in image
- `POST /faces/add` - Add new person with images

## Documentation

See `docs/` folder for detailed documentation:
- `docs/README.md` - Full setup guide
- `docs/API_README.md` - API usage
- `docs/DOCKER.md` - Docker deployment

## Project Structure

```
face/
├── src/                    # Core application
│   ├── face_recognizer.py  # Recognition engine
│   └── api_server.py       # REST API
├── scripts/                # Utility scripts
│   ├── add_faces.py        # Manage known faces
│   ├── recognize_image.py  # CLI recognition
│   └── test_*.py           # Test scripts
├── docs/                   # Documentation
├── known_faces/            # Known face images
└── requirements.txt        # Dependencies
```

## Docker

```bash
docker-compose up -d
```

## License

Open source
