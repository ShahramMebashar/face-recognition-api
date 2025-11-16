#!/usr/bin/env python3
"""
Recognize faces in a static image file.
Usage: python recognize_image.py <image_path>
"""

import sys
import os
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from face_recognizer import FaceRecognizer


def main():
    """Recognize faces in an image."""
    
    if len(sys.argv) < 2:
        print("Usage: python recognize_image.py <image_path> [--tolerance 0.6]")
        print("\nExample: python recognize_image.py test.jpg")
        print("         python recognize_image.py test.jpg --tolerance 0.5")
        sys.exit(1)
    
    image_path = sys.argv[1]
    
    # Parse tolerance argument
    tolerance = 0.6
    if "--tolerance" in sys.argv:
        idx = sys.argv.index("--tolerance")
        if idx + 1 < len(sys.argv):
            tolerance = float(sys.argv[idx + 1])
    
    # Check if image exists
    if not os.path.exists(image_path):
        print(f"Error: Image not found: {image_path}")
        sys.exit(1)
    
    print("=" * 60)
    print("Face Recognition - Image Mode")
    print("=" * 60)
    
    # Initialize recognizer
    recognizer = FaceRecognizer(known_faces_dir="known_faces", tolerance=tolerance)
    
    # Load known faces
    recognizer.load_known_faces()
    
    if not recognizer.known_face_encodings:
        print("\n⚠️  No known faces found!")
        print("Please add face images to the 'known_faces/' directory.")
        print("Format: person_name.jpg")
        sys.exit(1)
    
    print(f"\nProcessing image: {image_path}")
    print("-" * 60)
    
    # Recognize faces
    results = recognizer.recognize_faces(image_path)
    
    if not results:
        print("No faces detected in the image.")
    else:
        print(f"\nFound {len(results)} face(s):\n")
        
        for i, result in enumerate(results, 1):
            name = result['name']
            confidence = result['confidence']
            location = result['location']
            
            print(f"Face {i}:")
            print(f"  Name: {name}")
            if name != "Unknown":
                print(f"  Confidence: {confidence:.2f}%")
            print(f"  Location: top={location[0]}, right={location[1]}, "
                  f"bottom={location[2]}, left={location[3]}")
            print()
        
        # Draw and save result
        output_path = str(Path(image_path).stem) + "_recognized" + Path(image_path).suffix
        recognizer.draw_results(image_path, output_path)
        print(f"✓ Results saved to: {output_path}")
    
    print("=" * 60)


if __name__ == "__main__":
    main()
