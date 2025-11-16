# SQLite Migration Complete ✓

## What Changed

The attendance system has been migrated from JSON file storage to SQLite database for better performance and reliability.

### Key Updates

1. **Database**: SQLite with automatic schema initialization
2. **New Endpoints**: 
   - `GET /api/attendance/recent?limit=50` - Get recent records
   - `GET /api/attendance/stats` - Get statistics
3. **Schema**: Optimized with indexes for fast queries
4. **Config**: `ATTENDANCE_DB_PATH` replaces `ATTENDANCE_LOG_FILE`

## Benefits

✅ **Performance**: Indexed queries are much faster than JSON parsing  
✅ **Reliability**: ACID transactions prevent data corruption  
✅ **Scalability**: Handles thousands of records efficiently  
✅ **Queryability**: SQL queries for complex analytics  
✅ **Concurrent Access**: Multiple readers/writers supported  
✅ **Automatic Init**: Schema created on first startup  

## Quick Test

```bash
# Start server
./bin/attendance-api

# Check stats (empty initially)
curl http://localhost:8080/api/attendance/stats

# Record attendance (needs face recognition API running)
curl -X POST -F "image=@person.jpg" http://localhost:8080/api/attendance

# View records
curl http://localhost:8080/api/attendance/recent?limit=10

# Inspect database
./scripts/inspect_db.sh
```

## Database Schema

```sql
CREATE TABLE attendance (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    confidence REAL NOT NULL,
    timestamp DATETIME NOT NULL,
    status TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_attendance_timestamp ON attendance(timestamp DESC);
CREATE INDEX idx_attendance_name ON attendance(name);
CREATE INDEX idx_attendance_status ON attendance(status);
```

## API Response Examples

### Stats Endpoint
```json
{
  "success": true,
  "stats": {
    "total": 150,
    "authorized": 142,
    "unauthorized": 8,
    "unique_people": 12
  }
}
```

### Recent Records
```json
{
  "success": true,
  "count": 5,
  "records": [
    {
      "id": "uuid-here",
      "name": "john_doe",
      "confidence": 95.23,
      "timestamp": "2025-11-16T22:30:00Z",
      "status": "authorized"
    }
  ]
}
```

## Useful Scripts

```bash
# Inspect database with details
./scripts/inspect_db.sh

# Complete test suite
./scripts/test_complete.sh path/to/image.jpg

# Build for production
./scripts/build.sh
```

## SQL Query Examples

```bash
# Count visits by person
sqlite3 ./data/attendance.db "
  SELECT name, COUNT(*) as visits 
  FROM attendance 
  WHERE status='authorized' 
  GROUP BY name 
  ORDER BY visits DESC;
"

# Today's attendance
sqlite3 ./data/attendance.db "
  SELECT name, datetime(timestamp) 
  FROM attendance 
  WHERE date(timestamp) = date('now') 
  ORDER BY timestamp DESC;
"

# Export to CSV
sqlite3 -header -csv ./data/attendance.db \
  "SELECT * FROM attendance;" > attendance_export.csv
```

## Docker Build Note

The Dockerfile has been updated to support CGO (required for SQLite):
- `CGO_ENABLED=1` in build stage
- Added `gcc`, `musl-dev`, `sqlite-dev` dependencies
- Added `sqlite-libs` to runtime stage

## Migration Notes

- Old JSON files are not automatically migrated
- Database is created on first startup if it doesn't exist
- Schema initialization is idempotent (safe to run multiple times)
- No breaking changes to existing API endpoints

## Next Steps

1. Start the server: `./bin/attendance-api`
2. Test endpoints with curl or Postman
3. Integrate with Arduino/IoT devices
4. Monitor database: `./scripts/inspect_db.sh`

For full documentation, see `README.md`.
