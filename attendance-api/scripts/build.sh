#!/bin/bash
# Build script for attendance API

echo "Building attendance-api..."

cd "$(dirname "$0")/.."

# Build for current platform
go build -o bin/attendance-api cmd/server/main.go

echo "✓ Build complete: bin/attendance-api"

# Build for Linux (for VPS deployment)
GOOS=linux GOARCH=amd64 go build -o bin/attendance-api-linux cmd/server/main.go

echo "✓ Linux build complete: bin/attendance-api-linux"
