#!/bin/bash
# Complete test suite for attendance API with SQLite

BASE_URL="http://localhost:8080"

echo "======================================"
echo "Attendance API - Complete Test Suite"
echo "======================================"
echo ""

# 1. Health Check
echo "1. Health Check..."
HEALTH=$(curl -s "$BASE_URL/health")
echo "$HEALTH" | jq '.'
if echo "$HEALTH" | jq -e '.status == "ok"' > /dev/null; then
    echo "✓ Health check passed"
else
    echo "✗ Health check failed"
    exit 1
fi
echo ""

# 2. Check initial stats
echo "2. Initial Statistics..."
curl -s "$BASE_URL/api/attendance/stats" | jq '.'
echo ""

# 3. List faces
echo "3. List Known Faces..."
curl -s "$BASE_URL/api/faces" | jq '.'
echo ""

# 4. Get recent attendance (should be empty initially)
echo "4. Recent Attendance Records..."
curl -s "$BASE_URL/api/attendance/recent?limit=5" | jq '.'
echo ""

# 5. Test attendance recording with image
if [ -f "$1" ]; then
    echo "5. Recording Attendance with image: $1"
    RESULT=$(curl -s -X POST -F "image=@$1" "$BASE_URL/api/attendance")
    echo "$RESULT" | jq '.'
    
    AUTHORIZED=$(echo "$RESULT" | jq -r '.authorized')
    ACTION=$(echo "$RESULT" | jq -r '.action')
    
    if [ "$AUTHORIZED" = "true" ]; then
        echo "✓ Access authorized - Action: $ACTION"
    else
        echo "✓ Access denied - Action: $ACTION"
    fi
    echo ""
    
    # 6. Check stats after recording
    echo "6. Statistics After Recording..."
    curl -s "$BASE_URL/api/attendance/stats" | jq '.'
    echo ""
    
    # 7. Get recent records again
    echo "7. Recent Records (should show new entry)..."
    curl -s "$BASE_URL/api/attendance/recent?limit=5" | jq '.'
    echo ""
else
    echo "5. Skipping attendance recording test (no image provided)"
    echo "   Usage: $0 path/to/image.jpg"
    echo ""
fi

echo "======================================"
echo "✓ Test suite completed!"
echo "======================================"
echo ""
echo "Database location: ./data/attendance.db"
echo "Inspect with: ./scripts/inspect_db.sh"
