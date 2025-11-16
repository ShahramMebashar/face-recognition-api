#!/bin/bash
# Quick API test script

BASE_URL="http://localhost:5001"

echo "=================================="
echo "Face Recognition API - Quick Test"
echo "=================================="
echo ""

# 1. Health Check
echo "1. Testing /health endpoint..."
curl -s "$BASE_URL/health" | jq '.'
echo ""

# 2. List Faces
echo "2. Testing /faces endpoint..."
curl -s "$BASE_URL/faces" | jq '.'
echo ""

# 3. Recognize (if image provided)
if [ -f "$1" ]; then
    echo "3. Testing /recognize with: $1"
    curl -s -X POST -F "image=@$1" "$BASE_URL/recognize" | jq '.'
    echo ""
else
    echo "3. Skipping /recognize test (no image provided)"
    echo "   Usage: ./test_api.sh path/to/image.jpg"
    echo ""
fi

echo "=================================="
echo "Test completed!"
echo "=================================="
