#!/usr/bin/env python3
"""
Test the /faces/add endpoint
"""

import requests
import sys


def test_add_single_face(name, image_path):
    """Test adding a single face."""
    print(f"\n{'='*60}")
    print(f"Testing: Add single image for '{name}'")
    print('='*60)
    
    with open(image_path, 'rb') as f:
        files = {'images': f}
        data = {'name': name}
        response = requests.post('http://localhost:5001/faces/add', files=files, data=data)
    
    print(f"Status: {response.status_code}")
    result = response.json()
    print(f"Response: {result}")
    
    if result.get('success'):
        print(f"\n✓ Successfully added {result['images_added']} image(s) for {result['name']}")
        for file_info in result.get('files', []):
            print(f"  - {file_info['filename']}")
    else:
        print(f"\n✗ Error: {result.get('error')}")
        print(f"  Message: {result.get('message')}")
    
    return result


def test_add_multiple_faces(name, image_paths):
    """Test adding multiple faces at once."""
    print(f"\n{'='*60}")
    print(f"Testing: Add {len(image_paths)} images for '{name}'")
    print('='*60)
    
    files = [('images', open(path, 'rb')) for path in image_paths]
    data = {'name': name}
    
    response = requests.post('http://localhost:5001/faces/add', files=files, data=data)
    
    # Close files
    for _, f in files:
        f.close()
    
    print(f"Status: {response.status_code}")
    result = response.json()
    print(f"Response: {result}")
    
    if result.get('success'):
        print(f"\n✓ Successfully added {result['images_added']} image(s) for {result['name']}")
        for file_info in result.get('files', []):
            print(f"  - {file_info['filename']}")
        
        if result.get('errors'):
            print(f"\n⚠️  {len(result['errors'])} image(s) failed:")
            for error in result['errors']:
                print(f"  - {error['file']}: {error['error']}")
    else:
        print(f"\n✗ Error: {result.get('error')}")
        print(f"  Message: {result.get('message')}")
    
    return result


def list_faces():
    """List all known faces."""
    print(f"\n{'='*60}")
    print("Current Known Faces")
    print('='*60)
    
    response = requests.get('http://localhost:5001/faces')
    result = response.json()
    
    if result.get('success'):
        print(f"Total people: {result['total_people']}")
        print(f"Total images: {result['total_images']}\n")
        
        for person in result.get('people', []):
            print(f"  {person['name']}: {person['images']} image(s)")
    else:
        print("No faces found")


if __name__ == "__main__":
    print("\n🧪 Face Recognition API - Add Faces Test")
    print("="*60)
    
    if len(sys.argv) < 3:
        print("\nUsage:")
        print("  Single image:  python test_add_face.py 'John Doe' photo.jpg")
        print("  Multiple:      python test_add_face.py 'Jane Smith' photo1.jpg photo2.jpg photo3.jpg")
        sys.exit(1)
    
    name = sys.argv[1]
    image_paths = sys.argv[2:]
    
    try:
        # Test adding faces
        if len(image_paths) == 1:
            test_add_single_face(name, image_paths[0])
        else:
            test_add_multiple_faces(name, image_paths)
        
        # List all faces
        list_faces()
        
    except requests.exceptions.ConnectionError:
        print("\n❌ Error: Cannot connect to API server")
        print("Make sure the server is running: python api_server.py")
    except FileNotFoundError as e:
        print(f"\n❌ Error: Image file not found: {e}")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
