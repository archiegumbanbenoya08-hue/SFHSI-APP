import face_recognition
import requests
import json
import base64
import os
import sys
from datetime import datetime

# Configuration
API_BASE_URL = os.getenv('API_URL', 'http://localhost:8000')
ADMIN_TOKEN = sys.argv[1] if len(sys.argv) > 1 else None

def encode_student_photo(image_path):
    """Load image and generate face encoding"""
    try:
        image = face_recognition.load_image_file(image_path)
        encodings = face_recognition.face_encodings(image)
        
        if len(encodings) == 0:
            print(f"No face found in {image_path}")
            return None
        
        if len(encodings) > 1:
            print(f"Multiple faces found in {image_path}, using first face")
        
        return encodings[0]
    except Exception as e:
        print(f"Error encoding {image_path}: {str(e)}")
        return None

def upload_encoding(student_id, encoding, admin_token):
    """Upload encoding to backend"""
    try:
        headers = {'Authorization': f'Bearer {admin_token}'}
        data = {
            'student_id': student_id,
            'face_encoding': json.dumps(encoding.tolist())
        }
        
        response = requests.post(f'{API_BASE_URL}/api/students/encoding', json=data, headers=headers, timeout=10)
        
        if response.status_code == 200:
            print(f"[{datetime.now()}] Encoding uploaded for {student_id}")
            return True
        else:
            print(f"[{datetime.now()}] Failed to upload encoding: {response.status_code}")
            return False
    except Exception as e:
        print(f"[{datetime.now()}] Error uploading: {str(e)}")
        return False

if __name__ == '__main__':
    if not ADMIN_TOKEN:
        print("Usage: python encoder.py <admin_token> <image_path> <student_id>")
        print("Example: python encoder.py abc123def456 photo.jpg STU001")
        sys.exit(1)
    
    image_path = sys.argv[2] if len(sys.argv) > 2 else None
    student_id = sys.argv[3] if len(sys.argv) > 3 else None
    
    if not image_path or not student_id:
        print("Image path and student ID required")
        sys.exit(1)
    
    if not os.path.exists(image_path):
        print(f"Image file not found: {image_path}")
        sys.exit(1)
    
    print(f"Encoding face from {image_path}...")
    encoding = encode_student_photo(image_path)
    
    if encoding is not None:
        print(f"Uploading encoding for student {student_id}...")
        upload_encoding(student_id, encoding, ADMIN_TOKEN)
    else:
        print("Failed to generate encoding")
