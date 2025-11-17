#!/usr/bin/env python3
"""Run the Face Recognition API server"""

if __name__ == '__main__':
    from src.api_server import app
    import sys
    
    # Default port (5001 to avoid macOS AirPlay on 5000)
    port = 5001
    
    # Allow custom port via command line
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port: {sys.argv[1]}, using default: {port}")
    
    print("\n" + "=" * 60)
    print("Face Recognition API Server")
    print("=" * 60)
    print("\nEndpoints:")
    print("  GET  /health     - Health check")
    print("  GET  /faces      - List known faces")
    print("  POST /recognize  - Recognize faces in image")
    print("  POST /faces/add  - Add new face(s)")
    print(f"\nServer running on: http://localhost:{port}")
    print("\nExample usage:")
    print(f"  curl -X POST -F 'image=@photo.jpg' http://localhost:{port}/recognize")
    print(f"  curl -X POST -F 'name=john_doe' -F 'images=@photo1.jpg' http://localhost:{port}/faces/add")
    print("\n" + "=" * 60 + "\n")
    
    # Check if we should run in debug mode (default True for local dev)
    import os
    debug_mode = os.getenv('FLASK_DEBUG', 'True').lower() in ('true', '1', 'yes')
    
    # Run server
    # Note: use_reloader=False prevents restart when files change
    # In production (Docker), use gunicorn instead
    app.run(host='0.0.0.0', port=port, debug=debug_mode, use_reloader=False)
