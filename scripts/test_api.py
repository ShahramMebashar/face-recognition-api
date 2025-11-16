#!/usr/bin/env python3
"""
Test script for Face Recognition API
"""

import requests
import sys
import json


API_URL = "http://localhost:5001"  # Changed from 5000 to avoid macOS AirPlay


def test_health():
    """Test health endpoint."""
    print("Testing /health endpoint...")
    try:
        response = requests.get(f"{API_URL}/health")
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False


def test_list_faces():
    """Test list faces endpoint."""
    print("\nTesting /faces endpoint...")
    try:
        response = requests.get(f"{API_URL}/faces")
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False


def test_recognize(image_path):
    """Test recognize endpoint."""
    print(f"\nTesting /recognize endpoint with: {image_path}")
    try:
        with open(image_path, 'rb') as f:
            files = {'image': f}
            response = requests.post(f"{API_URL}/recognize", files=files)
        
        print(f"Status: {response.status_code}")
        result = response.json()
        print(f"Response: {json.dumps(result, indent=2)}")
        
        if result.get('success'):
            print(f"\n✓ Found {result['faces_detected']} face(s)")
            for i, face in enumerate(result['faces'], 1):
                print(f"  Face {i}: {face['name']} ({face['confidence']}%)")
        
        return response.status_code == 200
    except FileNotFoundError:
        print(f"Error: Image file not found: {image_path}")
        return False
    except Exception as e:
        print(f"Error: {e}")
        return False


def main():
    """Run all tests."""
    print("=" * 60)
    print("Face Recognition API - Test Script")
    print("=" * 60)
    print(f"\nAPI URL: {API_URL}")
    print("Make sure the API server is running: python api_server.py")
    print("=" * 60)
    
    # Test health
    if not test_health():
        print("\n❌ Server is not responding. Start it with: python api_server.py")
        return 1
    
    # Test list faces
    test_list_faces()
    
    # Test recognize if image path provided
    if len(sys.argv) > 1:
        image_path = sys.argv[1]
        test_recognize(image_path)
    else:
        print("\nTo test face recognition, provide an image:")
        print("  python test_api.py photo.jpg")
    
    print("\n" + "=" * 60)
    print("✅ Tests completed!")
    print("=" * 60)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
