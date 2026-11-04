#!/usr/bin/env python3
"""
Generate face encoding from an image file.
Called by backend when a student is registered.
Outputs JSON array of encoding values to stdout.
"""

import sys
import json
import face_recognition

def generate_encoding(image_path):
    """Load image and generate face encoding"""
    try:
        image = face_recognition.load_image_file(image_path)
        encodings = face_recognition.face_encodings(image)
        
        if len(encodings) == 0:
            print(json.dumps(None))
            return
        
        # Use first face found
        encoding = encodings[0]
        print(json.dumps(encoding.tolist()))
    except Exception as e:
        print(json.dumps(None), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(json.dumps(None), file=sys.stderr)
        sys.exit(1)
    
    image_path = sys.argv[1]
    generate_encoding(image_path)
