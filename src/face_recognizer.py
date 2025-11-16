"""
Face Recognition Module
Simple but accurate face recognition using face_recognition library
Optimized for Linux VPS deployment
"""

import face_recognition
import cv2
import numpy as np
import os
import pickle
from pathlib import Path
from typing import List, Tuple, Dict, Optional


class FaceRecognizer:
    """
    A simple and accurate face recognition system.
    Uses the face_recognition library which is based on dlib's state-of-the-art
    face recognition built with deep learning (99.38% accuracy on LFW benchmark).
    """
    
    def __init__(self, known_faces_dir: str = "known_faces", tolerance: float = 0.6):
        """
        Initialize the face recognizer.
        
        Args:
            known_faces_dir: Directory containing known face images
            tolerance: How much distance between faces to consider it a match.
                       Lower is more strict. Default 0.6 works well.
        """
        self.known_faces_dir = Path(known_faces_dir)
        self.tolerance = tolerance
        self.known_face_encodings = []
        self.known_face_names = []
        self.encodings_file = "face_encodings.pkl"
        self.multiple_encodings_per_person = True  # Support multiple images per person
        
    def load_known_faces(self, force_reload: bool = False):
        """
        Load known faces from directory or cache file.
        
        Args:
            force_reload: If True, reload from images even if cache exists
        """
        # Try to load from cache first
        if not force_reload and os.path.exists(self.encodings_file):
            print(f"Loading encodings from cache: {self.encodings_file}")
            with open(self.encodings_file, 'rb') as f:
                data = pickle.load(f)
                self.known_face_encodings = data['encodings']
                self.known_face_names = data['names']
            print(f"Loaded {len(self.known_face_names)} known faces from cache")
            return
        
        # Load from images
        print(f"Loading known faces from: {self.known_faces_dir}")
        
        if not self.known_faces_dir.exists():
            self.known_faces_dir.mkdir(parents=True, exist_ok=True)
            print(f"Created directory: {self.known_faces_dir}")
            print("Please add face images to this directory (format: person_name.jpg)")
            return
        
        self.known_face_encodings = []
        self.known_face_names = []
        
        # Supported image formats
        image_extensions = {'.jpg', '.jpeg', '.png', '.bmp'}
        
        for image_path in self.known_faces_dir.iterdir():
            if image_path.suffix.lower() not in image_extensions:
                continue
            
            print(f"Processing: {image_path.name}")
            
            # Load image and get face encoding
            image = face_recognition.load_image_file(str(image_path))
            encodings = face_recognition.face_encodings(image)
            
            if len(encodings) == 0:
                print(f"  ⚠️  No face found in {image_path.name}")
                continue
            
            if len(encodings) > 1:
                print(f"  ⚠️  Multiple faces found in {image_path.name}, using first face")
            
            # Extract person's name (handles formats like "john_doe_1.jpg" -> "john_doe")
            # Remove trailing numbers and underscores: john_doe_1 -> john_doe
            name = image_path.stem
            # Split by underscore and check if last part is a number
            parts = name.split('_')
            if len(parts) > 1 and parts[-1].isdigit():
                name = '_'.join(parts[:-1])  # Remove the number suffix
            
            self.known_face_encodings.append(encodings[0])
            self.known_face_names.append(name)
            print(f"  ✓ Added face for: {name}")
        
        print(f"\nTotal known faces loaded: {len(self.known_face_names)}")
        
        # Show summary by person
        if self.known_face_names:
            from collections import Counter
            person_counts = Counter(self.known_face_names)
            print("\nFaces per person:")
            for person, count in sorted(person_counts.items()):
                print(f"  {person}: {count} image(s)")
        
        # Save to cache
        if self.known_face_encodings:
            self.save_encodings()
    
    def save_encodings(self):
        """Save face encodings to cache file for faster loading."""
        data = {
            'encodings': self.known_face_encodings,
            'names': self.known_face_names
        }
        with open(self.encodings_file, 'wb') as f:
            pickle.dump(data, f)
        print(f"Saved encodings to: {self.encodings_file}")
    
    def recognize_faces(self, image_path: str) -> List[Dict]:
        """
        Recognize faces in an image.
        
        Args:
            image_path: Path to the image file
            
        Returns:
            List of dictionaries containing face information:
            [{'name': str, 'location': tuple, 'confidence': float}, ...]
        """
        if not self.known_face_encodings:
            raise ValueError("No known faces loaded. Call load_known_faces() first.")
        
        # Load the image
        image = face_recognition.load_image_file(image_path)
        
        # Find all faces and their encodings
        face_locations = face_recognition.face_locations(image, model="hog")
        face_encodings = face_recognition.face_encodings(image, face_locations)
        
        results = []
        
        for face_encoding, face_location in zip(face_encodings, face_locations):
            # Compare with known faces
            matches = face_recognition.compare_faces(
                self.known_face_encodings, 
                face_encoding, 
                tolerance=self.tolerance
            )
            
            # Calculate face distances (lower is better match)
            face_distances = face_recognition.face_distance(
                self.known_face_encodings, 
                face_encoding
            )
            
            name = "Unknown"
            confidence = 0.0
            
            if True in matches:
                # Get the best match
                best_match_index = np.argmin(face_distances)
                if matches[best_match_index]:
                    name = self.known_face_names[best_match_index]
                    # Convert distance to confidence (0-100%)
                    confidence = (1 - face_distances[best_match_index]) * 100
            
            results.append({
                'name': name,
                'location': face_location,  # (top, right, bottom, left)
                'confidence': confidence
            })
        
        return results
    
    def recognize_faces_from_array(self, image_array: np.ndarray) -> List[Dict]:
        """
        Recognize faces from a numpy array (useful for video frames).
        
        Args:
            image_array: Image as numpy array (BGR or RGB)
            
        Returns:
            List of dictionaries containing face information
        """
        if not self.known_face_encodings:
            raise ValueError("No known faces loaded. Call load_known_faces() first.")
        
        # Convert BGR to RGB if needed (OpenCV uses BGR)
        rgb_image = cv2.cvtColor(image_array, cv2.COLOR_BGR2RGB)
        
        # Find all faces and their encodings
        face_locations = face_recognition.face_locations(rgb_image, model="hog")
        face_encodings = face_recognition.face_encodings(rgb_image, face_locations)
        
        results = []
        
        for face_encoding, face_location in zip(face_encodings, face_locations):
            matches = face_recognition.compare_faces(
                self.known_face_encodings, 
                face_encoding, 
                tolerance=self.tolerance
            )
            
            face_distances = face_recognition.face_distance(
                self.known_face_encodings, 
                face_encoding
            )
            
            name = "Unknown"
            confidence = 0.0
            
            if True in matches:
                best_match_index = np.argmin(face_distances)
                if matches[best_match_index]:
                    name = self.known_face_names[best_match_index]
                    confidence = (1 - face_distances[best_match_index]) * 100
            
            results.append({
                'name': name,
                'location': face_location,
                'confidence': confidence
            })
        
        return results
    
    def draw_results(self, image_path: str, output_path: str = None) -> str:
        """
        Draw recognition results on image and save it.
        
        Args:
            image_path: Path to input image
            output_path: Path to save output image (optional)
            
        Returns:
            Path to output image
        """
        # Load image with OpenCV
        image = cv2.imread(image_path)
        
        # Get recognition results
        results = self.recognize_faces(image_path)
        
        # Draw rectangles and labels
        for result in results:
            top, right, bottom, left = result['location']
            name = result['name']
            confidence = result['confidence']
            
            # Choose color based on recognition
            color = (0, 255, 0) if name != "Unknown" else (0, 0, 255)
            
            # Draw rectangle
            cv2.rectangle(image, (left, top), (right, bottom), color, 2)
            
            # Draw label
            label = f"{name}"
            if name != "Unknown":
                label += f" ({confidence:.1f}%)"
            
            cv2.rectangle(image, (left, bottom - 35), (right, bottom), color, cv2.FILLED)
            cv2.putText(image, label, (left + 6, bottom - 6), 
                       cv2.FONT_HERSHEY_DUPLEX, 0.6, (255, 255, 255), 1)
        
        # Save output
        if output_path is None:
            output_path = image_path.replace('.', '_recognized.')
        
        cv2.imwrite(output_path, image)
        return output_path


if __name__ == "__main__":
    # Example usage
    recognizer = FaceRecognizer(known_faces_dir="known_faces")
    recognizer.load_known_faces()
    
    print("\nTo use this module:")
    print("1. Add known face images to 'known_faces/' directory")
    print("2. Name files as: person_name.jpg")
    print("3. Run recognition scripts: recognize_image.py or recognize_webcam.py")
