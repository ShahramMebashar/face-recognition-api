#!/usr/bin/env python3
"""
Quick test script to verify the face recognition system is working.
This script will help you test the installation.
"""

import sys
import os
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))


def test_imports():
    """Test if all required libraries are installed."""
    print("Testing imports...")
    
    try:
        import face_recognition
        print("  ✓ face_recognition")
    except ImportError as e:
        print(f"  ✗ face_recognition: {e}")
        return False
    
    try:
        import cv2
        print("  ✓ opencv (cv2)")
    except ImportError as e:
        print(f"  ✗ opencv: {e}")
        return False
    
    try:
        import numpy
        print("  ✓ numpy")
    except ImportError as e:
        print(f"  ✗ numpy: {e}")
        return False
    
    try:
        import PIL
        print("  ✓ Pillow (PIL)")
    except ImportError as e:
        print(f"  ✗ Pillow: {e}")
        return False
    
    return True


def test_face_recognizer():
    """Test if the FaceRecognizer class works."""
    print("\nTesting FaceRecognizer class...")
    
    try:
        from face_recognizer import FaceRecognizer
        
        recognizer = FaceRecognizer(known_faces_dir="known_faces")
        print("  ✓ FaceRecognizer initialized")
        
        recognizer.load_known_faces()
        print(f"  ✓ Loaded {len(recognizer.known_face_names)} known faces")
        
        return True
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False


def check_directory_structure():
    """Check if required directories exist."""
    print("\nChecking directory structure...")
    
    known_faces = Path("known_faces")
    if known_faces.exists() and known_faces.is_dir():
        print("  ✓ known_faces/ directory exists")
        
        # Count images
        image_extensions = {'.jpg', '.jpeg', '.png', '.bmp'}
        images = [f for f in known_faces.iterdir() 
                 if f.suffix.lower() in image_extensions]
        
        if images:
            print(f"  ✓ Found {len(images)} image(s) in known_faces/")
            for img in images:
                print(f"    - {img.name}")
        else:
            print("  ⚠️  No images found in known_faces/")
            print("     Add face images to test recognition")
    else:
        print("  ✗ known_faces/ directory not found")
        return False
    
    return True


def main():
    """Run all tests."""
    print("=" * 60)
    print("Face Recognition System - Installation Test")
    print("=" * 60)
    print()
    
    success = True
    
    # Test imports
    if not test_imports():
        print("\n❌ Import test failed!")
        print("\nPlease install requirements:")
        print("  pip install -r requirements.txt")
        success = False
    
    # Check directories
    if not check_directory_structure():
        print("\n⚠️  Directory structure incomplete")
        success = False
    
    # Test face recognizer
    if not test_face_recognizer():
        print("\n❌ FaceRecognizer test failed!")
        success = False
    
    print("\n" + "=" * 60)
    
    if success:
        print("✅ All tests passed! System is ready to use.")
        print("\nNext steps:")
        print("1. Add face images to known_faces/ directory")
        print("2. Run: python recognize_image.py <image_path>")
    else:
        print("❌ Some tests failed. Please fix the issues above.")
    
    print("=" * 60)
    
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
