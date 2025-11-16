#!/usr/bin/env python3
"""
Helper script to organize and add known faces.
Usage: python add_faces.py
"""

import os
import shutil
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))


def list_current_faces():
    """List all current known faces."""
    known_faces_dir = Path("known_faces")
    
    if not known_faces_dir.exists():
        print("known_faces/ directory doesn't exist yet.")
        return {}
    
    image_extensions = {'.jpg', '.jpeg', '.png', '.bmp'}
    images = [f for f in known_faces_dir.iterdir() 
              if f.suffix.lower() in image_extensions]
    
    if not images:
        print("No face images found in known_faces/")
        return {}
    
    # Group by person
    from collections import defaultdict
    people = defaultdict(list)
    
    for img in images:
        name = img.stem
        # Extract person name (remove number suffix if exists)
        parts = name.split('_')
        if len(parts) > 1 and parts[-1].isdigit():
            person = '_'.join(parts[:-1])
        else:
            person = name
        people[person].append(img.name)
    
    print("\nCurrent known faces:")
    print("=" * 60)
    for person, files in sorted(people.items()):
        print(f"\n{person}: ({len(files)} image{'s' if len(files) > 1 else ''})")
        for f in sorted(files):
            print(f"  - {f}")
    
    return people


def add_new_person():
    """Guide user to add a new person."""
    print("\n" + "=" * 60)
    print("Add New Person")
    print("=" * 60)
    
    person_name = input("\nEnter person's name (e.g., john_doe): ").strip()
    
    if not person_name:
        print("❌ Name cannot be empty")
        return
    
    # Replace spaces with underscores
    person_name = person_name.replace(' ', '_').lower()
    
    known_faces_dir = Path("known_faces")
    known_faces_dir.mkdir(exist_ok=True)
    
    print(f"\nAdding images for: {person_name}")
    print("\nOptions:")
    print("1. Add a single image")
    print("2. Add multiple images (recommended for better accuracy)")
    
    choice = input("\nChoice (1 or 2): ").strip()
    
    if choice == "1":
        image_path = input("Enter path to image file: ").strip()
        if os.path.exists(image_path):
            ext = Path(image_path).suffix
            dest = known_faces_dir / f"{person_name}{ext}"
            shutil.copy2(image_path, dest)
            print(f"✓ Added: {dest.name}")
        else:
            print(f"❌ File not found: {image_path}")
    
    elif choice == "2":
        print("\nEnter image paths (one per line, empty line to finish):")
        count = 1
        while True:
            image_path = input(f"Image {count}: ").strip()
            if not image_path:
                break
            
            if os.path.exists(image_path):
                ext = Path(image_path).suffix
                dest = known_faces_dir / f"{person_name}_{count}{ext}"
                shutil.copy2(image_path, dest)
                print(f"  ✓ Added: {dest.name}")
                count += 1
            else:
                print(f"  ❌ File not found: {image_path}")
        
        if count > 1:
            print(f"\n✓ Successfully added {count - 1} image(s) for {person_name}")
    else:
        print("❌ Invalid choice")


def remove_person():
    """Remove a person's images."""
    people = list_current_faces()
    
    if not people:
        return
    
    print("\n" + "=" * 60)
    person_name = input("\nEnter person's name to remove: ").strip().replace(' ', '_').lower()
    
    if person_name not in people:
        print(f"❌ Person '{person_name}' not found")
        return
    
    confirm = input(f"Remove all {len(people[person_name])} image(s) for {person_name}? (yes/no): ").strip().lower()
    
    if confirm == 'yes':
        known_faces_dir = Path("known_faces")
        for filename in people[person_name]:
            (known_faces_dir / filename).unlink()
            print(f"  ✓ Removed: {filename}")
        print(f"\n✓ Removed all images for {person_name}")
        
        # Remove cache to force reload
        if Path("face_encodings.pkl").exists():
            Path("face_encodings.pkl").unlink()
            print("✓ Cleared encodings cache")
    else:
        print("❌ Cancelled")


def show_guidelines():
    """Show guidelines for adding faces."""
    print("\n" + "=" * 60)
    print("Guidelines for Best Results")
    print("=" * 60)
    print("""
For SINGLE image per person:
  - Use: person_name.jpg
  - Example: john_doe.jpg, jane_smith.png

For MULTIPLE images per person (recommended):
  - Use: person_name_1.jpg, person_name_2.jpg, etc.
  - Examples:
      john_doe_1.jpg  (front facing)
      john_doe_2.jpg  (slight angle)
      john_doe_3.jpg  (different lighting)

Tips for accurate recognition:
  ✓ Use clear, well-lit photos
  ✓ Face should be clearly visible
  ✓ Include front-facing and slightly angled photos
  ✓ Vary lighting conditions (indoor/outdoor)
  ✓ Use recent photos
  ✓ Each image should contain ONLY ONE face
  
  ✗ Avoid blurry or low-quality images
  ✗ Avoid extreme angles or profiles
  ✗ Avoid images with multiple people
  ✗ Avoid heavy filters or editing

Recommended: 2-5 images per person for best accuracy
""")


def main():
    """Main menu."""
    while True:
        print("\n" + "=" * 60)
        print("Face Recognition - Manage Known Faces")
        print("=" * 60)
        print("\n1. List current known faces")
        print("2. Add new person")
        print("3. Remove person")
        print("4. Show guidelines")
        print("5. Rebuild encodings cache")
        print("6. Exit")
        
        choice = input("\nChoice (1-6): ").strip()
        
        if choice == "1":
            list_current_faces()
        elif choice == "2":
            add_new_person()
        elif choice == "3":
            remove_person()
        elif choice == "4":
            show_guidelines()
        elif choice == "5":
            if Path("face_encodings.pkl").exists():
                Path("face_encodings.pkl").unlink()
                print("✓ Encodings cache cleared. Will rebuild on next recognition.")
            else:
                print("No cache file found.")
        elif choice == "6":
            print("\nGoodbye!")
            break
        else:
            print("❌ Invalid choice")


if __name__ == "__main__":
    main()
