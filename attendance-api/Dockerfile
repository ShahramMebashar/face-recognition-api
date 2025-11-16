# Multi-stage Dockerfile for Attendance API

# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Install build dependencies (gcc for CGO and SQLite)
RUN apk add --no-cache git gcc musl-dev sqlite-dev

# Copy go mod files
COPY go.mod go.sum ./
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

# Copy .env.example as default
COPY .env.example .env

# Create data directory
RUN mkdir -p /app/data

# Expose port
EXPOSE 8080

# Run the application
CMD ["./attendance-api"]
