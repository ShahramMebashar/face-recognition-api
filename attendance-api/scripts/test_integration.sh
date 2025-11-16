#!/bin/bash
# Test script for Attendance API

BASE_URL="http://localhost:8080"

echo "======================================"
echo "Attendance API - Integration Tests"
echo "======================================"
echo ""

# Check if server is running
echo "1. Health Check..."
curl -s "$BASE_URL/health" | jq '.' || echo "Server not running!"
echo ""

# List faces from Face Recognition API
echo "2. List Known Faces..."
curl -s "$BASE_URL/api/faces" | jq '.'
echo ""

# Test attendance recording (need an image)
if [ -f "$1" ]; then
    echo "3. Testing Attendance Recording with: $1"
    curl -s -X POST -F "image=@$1" "$BASE_URL/api/attendance" | jq '.'
    echo ""
else
    echo "3. Skipping attendance test (no image provided)"
    echo "   Usage: ./test_integration.sh path/to/person.jpg"
    echo ""
fi

# Test SSE stream (run for 5 seconds)
echo "4. Testing SSE Stream (5 seconds)..."
timeout 5 curl -N "$BASE_URL/api/attendance/stream" || echo "SSE stream test completed"
echo ""

echo "======================================"
echo "Tests completed!"
echo "======================================"
