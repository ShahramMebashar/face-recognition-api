#!/usr/bin/env python3
"""
Simple Face Recognition API using Flask
Accepts image upload and returns recognition results in JSON format
"""

from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import os
import sys
import tempfile
from pathlib import Path

# Import from same package
from .face_recognizer import FaceRecognizer

app = Flask(__name__)

# Configuration
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'bmp'}
MAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB

# Initialize face recognizer
recognizer = FaceRecognizer(known_faces_dir="known_faces", tolerance=0.6)
print("Loading known faces...")
recognizer.load_known_faces()

if not recognizer.known_face_encodings:
    print("⚠️  WARNING: No known faces loaded!")
    print("Add face images to 'known_faces/' directory and restart the server.")


def allowed_file(filename):
    """Check if file extension is allowed."""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "ok",
        "service": "Face Recognition API",
        "known_faces": len(set(recognizer.known_face_names)),
        "total_encodings": len(recognizer.known_face_encodings)
    })


@app.route('/recognize', methods=['POST'])
def recognize():
    """
    Recognize faces in uploaded image.
    
    Expects: multipart/form-data with 'image' field
    Returns: JSON with recognition results
    """
    
    # Check if image file is present
    if 'image' not in request.files:
        return jsonify({
            "success": False,
            "error": "No image file provided",
            "message": "Please upload an image file with key 'image'"
        }), 400
    
    file = request.files['image']
    
    # Check if filename is empty
    if file.filename == '':
        return jsonify({
            "success": False,
            "error": "Empty filename",
            "message": "No file selected"
        }), 400
    
    # Check file extension
    if not allowed_file(file.filename):
        return jsonify({
            "success": False,
            "error": "Invalid file type",
            "message": f"Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"
        }), 400
    
    # Check if known faces are loaded
    if not recognizer.known_face_encodings:
        return jsonify({
            "success": False,
            "error": "No known faces",
            "message": "Server has no known faces loaded. Add faces to 'known_faces/' directory."
        }), 503
    
    try:
        # Save uploaded file temporarily
        temp_dir = tempfile.gettempdir()
        filename = secure_filename(file.filename)
        temp_path = os.path.join(temp_dir, filename)
        file.save(temp_path)
        
        # Recognize faces
        results = recognizer.recognize_faces(temp_path)
        
        # Clean up temp file
        os.remove(temp_path)
        
        # Format response
        faces = []
        for result in results:
            face_data = {
                "name": result['name'],
                "confidence": round(result['confidence'], 2),
                "location": {
                    "top": result['location'][0],
                    "right": result['location'][1],
                    "bottom": result['location'][2],
                    "left": result['location'][3]
                }
            }
            faces.append(face_data)
        
        response = {
            "success": True,
            "faces_detected": len(faces),
            "faces": faces
        }
        
        return jsonify(response), 200
    
    except Exception as e:
        # Clean up temp file if it exists
        if 'temp_path' in locals() and os.path.exists(temp_path):
            os.remove(temp_path)
        
        return jsonify({
            "success": False,
            "error": "Processing error",
            "message": str(e)
        }), 500


@app.route('/faces', methods=['GET'])
def list_faces():
    """List all known faces in the system."""
    from collections import Counter
    
    if not recognizer.known_face_names:
        return jsonify({
            "success": True,
            "total_people": 0,
            "people": []
        })
    
    # Count images per person
    person_counts = Counter(recognizer.known_face_names)
    
    people = [
        {
            "name": name,
            "images": count
        }
        for name, count in sorted(person_counts.items())
    ]
    
    return jsonify({
        "success": True,
        "total_people": len(people),
        "total_images": len(recognizer.known_face_names),
        "people": people
    })


@app.route('/faces/add', methods=['POST'])
def add_face():
    """
    Add new face(s) to the known faces database.
    
    Expects:
    - 'name': Person's name (required)
    - 'images': One or more image files (required)
    
    Returns: JSON with success status and added images info
    """
    
    # Check if name is provided
    if 'name' not in request.form:
        return jsonify({
            "success": False,
            "error": "No name provided",
            "message": "Please provide 'name' field with person's name"
        }), 400
    
    name = request.form['name'].strip()
    
    # Validate name
    if not name:
        return jsonify({
            "success": False,
            "error": "Empty name",
            "message": "Name cannot be empty"
        }), 400
    
    # Sanitize name: replace spaces with underscores, lowercase
    name = name.replace(' ', '_').lower()
    
    # Check if images are provided
    if 'images' not in request.files:
        return jsonify({
            "success": False,
            "error": "No images provided",
            "message": "Please upload at least one image with key 'images'"
        }), 400
    
    # Get all uploaded images (can be multiple)
    files = request.files.getlist('images')
    
    if not files or all(f.filename == '' for f in files):
        return jsonify({
            "success": False,
            "error": "No images selected",
            "message": "Please select at least one image file"
        }), 400
    
    # Process each image
    added_images = []
    errors = []
    
    # Find next available number for this person
    known_faces_dir = Path("known_faces")
    known_faces_dir.mkdir(exist_ok=True)
    
    # Get existing image count for this person
    existing_files = list(known_faces_dir.glob(f"{name}*.*"))
    start_number = len([f for f in existing_files if f.stem.startswith(name)]) + 1
    
    for idx, file in enumerate(files):
        # Validate file
        if file.filename == '':
            continue
        
        if not allowed_file(file.filename):
            errors.append({
                "file": file.filename,
                "error": f"Invalid file type. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
            })
            continue
        
        try:
            # Determine filename
            ext = os.path.splitext(file.filename)[1].lower()
            
            if len(files) == 1:
                # Single image: name.jpg
                filename = f"{name}{ext}"
            else:
                # Multiple images: name_1.jpg, name_2.jpg, etc.
                filename = f"{name}_{start_number + idx}{ext}"
            
            filepath = known_faces_dir / filename
            
            # Save file temporarily to validate it has a face
            temp_path = os.path.join(tempfile.gettempdir(), secure_filename(file.filename))
            file.save(temp_path)
            
            # Validate the image has a face
            import face_recognition as fr
            image = fr.load_image_file(temp_path)
            face_encodings = fr.face_encodings(image)
            
            if len(face_encodings) == 0:
                errors.append({
                    "file": file.filename,
                    "error": "No face detected in image"
                })
                os.remove(temp_path)
                continue
            
            if len(face_encodings) > 1:
                errors.append({
                    "file": file.filename,
                    "error": "Multiple faces detected. Please use images with only one face"
                })
                os.remove(temp_path)
                continue
            
            # Move to known_faces directory
            import shutil
            shutil.move(temp_path, filepath)
            
            added_images.append({
                "filename": filename,
                "path": str(filepath)
            })
            
        except Exception as e:
            errors.append({
                "file": file.filename,
                "error": str(e)
            })
            # Clean up temp file if exists
            if 'temp_path' in locals() and os.path.exists(temp_path):
                os.remove(temp_path)
    
    # Check if any images were added
    if not added_images:
        return jsonify({
            "success": False,
            "error": "No valid images added",
            "message": "None of the uploaded images could be processed",
            "errors": errors
        }), 400
    
    # Clear cache to force reload
    cache_file = "face_encodings.pkl"
    if os.path.exists(cache_file):
        os.remove(cache_file)
    
    # Reload known faces
    recognizer.load_known_faces(force_reload=True)
    
    response = {
        "success": True,
        "message": f"Successfully added {len(added_images)} image(s) for {name}",
        "name": name,
        "images_added": len(added_images),
        "files": added_images
    }
    
    if errors:
        response["errors"] = errors
        response["message"] += f" ({len(errors)} failed)"
    
    return jsonify(response), 201


@app.errorhandler(413)
def request_entity_too_large(error):
    """Handle file too large error."""
    return jsonify({
        "success": False,
        "error": "File too large",
        "message": f"Maximum file size is {MAX_FILE_SIZE / (1024*1024)}MB"
    }), 413


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({
        "success": False,
        "error": "Not found",
        "message": "Endpoint not found"
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    return jsonify({
        "success": False,
        "error": "Internal server error",
        "message": "An unexpected error occurred"
    }), 500
