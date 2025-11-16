# Docker Deployment

## Build and Run

```bash
# Using docker-compose (recommended)
docker-compose up -d

# Or using Docker directly
docker build -t face-recognition-api .
docker run -d -p 5001:5001 -v $(pwd)/known_faces:/app/known_faces face-recognition-api

# Or use the script
./docker-run.sh
```

## Manage Container

```bash
# View logs
docker logs face-api

# Stop
docker stop face-api

# Restart
docker restart face-api

# Remove
docker rm face-api
```

## Access API

API will be available at `http://localhost:5001`

## Add Known Faces

Place images in `known_faces/` directory before building, or add via API:

```bash
curl -X POST -F "name=john_doe" -F "images=@photo.jpg" http://localhost:5001/faces/add
```
