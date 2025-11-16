#!/bin/bash
# Database inspection and management script

DB_PATH="./data/attendance.db"

if [ ! -f "$DB_PATH" ]; then
    echo "Database not found at $DB_PATH"
    exit 1
fi

echo "======================================"
echo "Attendance Database Inspector"
echo "======================================"
echo ""

# Show schema
echo "1. Database Schema:"
echo "-------------------"
sqlite3 "$DB_PATH" ".schema attendance"
echo ""

# Show table info
echo "2. Table Info:"
echo "-------------------"
sqlite3 "$DB_PATH" ".headers on" ".mode column" "PRAGMA table_info(attendance);"
echo ""

# Show indexes
echo "3. Indexes:"
echo "-------------------"
sqlite3 "$DB_PATH" "SELECT name, sql FROM sqlite_master WHERE type='index' AND tbl_name='attendance';"
echo ""

# Show statistics
echo "4. Statistics:"
echo "-------------------"
sqlite3 "$DB_PATH" <<EOF
.headers on
.mode column
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT name) as unique_people,
    SUM(CASE WHEN status = 'authorized' THEN 1 ELSE 0 END) as authorized,
    SUM(CASE WHEN status = 'unauthorized' THEN 1 ELSE 0 END) as unauthorized
FROM attendance;
EOF
echo ""

# Show recent records
echo "5. Recent Records (last 10):"
echo "-------------------"
sqlite3 "$DB_PATH" <<EOF
.headers on
.mode column
SELECT 
    substr(id, 1, 8) as id,
    name,
    printf('%.2f', confidence) as conf,
    datetime(timestamp) as timestamp,
    status
FROM attendance 
ORDER BY timestamp DESC 
LIMIT 10;
EOF
echo ""

echo "======================================"
