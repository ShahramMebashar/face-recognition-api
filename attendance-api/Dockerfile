# Multi-stage Dockerfile for Attendance API

# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Install build dependencies (gcc for CGO and SQLite)
RUN apk add --no-cache git gcc musl-dev sqlite-dev

# Copy go mod files
COPY go.mod ./
COPY go.sum* ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o attendance-api ./cmd/server

# Final stage
FROM alpine:latest

WORKDIR /app

# Install ca-certificates for HTTPS calls and SQLite runtime
RUN apk --no-cache add ca-certificates sqlite-libs

# Copy binary from builder
COPY --from=builder /build/attendance-api .

# Create data directory
RUN mkdir -p /app/data

# Environment variables (can be overridden at runtime)
ENV SERVER_PORT=8080 \
    SERVER_HOST=0.0.0.0 \
    FACE_API_URL=http://localhost:5001 \
    FACE_API_TIMEOUT=30s \
    MAX_UPLOAD_SIZE=5242880 \
    MAX_MEMORY=10485760 \
    ATTENDANCE_DB_PATH=/app/data/attendance.db

# Expose port
EXPOSE 8080

# Run the application
CMD ["./attendance-api"]
