#!/bin/bash
# Build and run with Docker

echo "Building Docker image..."
docker build -t face-recognition-api .

echo ""
echo "Starting container..."
docker run -d \
  --name face-api \
  -p 5001:5001 \
  -v $(pwd)/known_faces:/app/known_faces \
  -v $(pwd)/face_encodings.pkl:/app/face_encodings.pkl \
  face-recognition-api

echo ""
echo "API running at http://localhost:5001"
echo ""
echo "Commands:"
echo "  docker logs face-api       - View logs"
echo "  docker stop face-api       - Stop container"
echo "  docker rm face-api         - Remove container"
