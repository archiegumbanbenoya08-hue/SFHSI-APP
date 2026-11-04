import cv2
import face_recognition
import requests
import numpy as np
import time
import json
import os
from datetime import datetime
from collections import defaultdict
import base64
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))

# Configuration
API_BASE_URL = os.getenv('API_URL', 'http://localhost:8000')
DEVICE_API_KEY = os.getenv('DEVICE_API_KEY')
if not DEVICE_API_KEY:
    raise RuntimeError('Set DEVICE_API_KEY in mini_pc_client/.env before starting the client.')
COOLDOWN_SECONDS = 10
FACE_DISTANCE_THRESHOLD = 0.5
RETRY_ATTEMPTS = 3
RETRY_DELAY = 2

class FaceRecognitionClient:
    def __init__(self):
        self.known_face_encodings = []
        self.known_face_labels = []  # Stores student metadata
        self.student_cooldowns = defaultdict(lambda: 0)  # Track last detection time per student
        self.faces_in_frame = set()  # Track faces currently visible
        
    def fetch_encodings(self):
        """Fetch all student face encodings from backend with retry logic"""
        for attempt in range(RETRY_ATTEMPTS):
            try:
                headers = {'x-device-key': DEVICE_API_KEY}
                response = requests.get(f'{API_BASE_URL}/api/students/encodings/all', headers=headers, timeout=10)
                
                if response.status_code == 200:
                    students = response.json()
                    self.known_face_encodings = []
                    self.known_face_labels = []
                    
                    for student in students:
                        if student.get('face_encoding'):
                            try:
                                # Parse the face encoding from JSON
                                encoding = np.array(json.loads(student['face_encoding']))
                                self.known_face_encodings.append(encoding)
                                self.known_face_labels.append({
                                    'id': student['id'],
                                    'student_id': student['student_id'],
                                    'name': f"{student['first_name']} {student['last_name']}",
                                    'grade': student['grade_level'],
                                    'parent_id': student['parent_id'],
                                    'parent_email': student['parent_email']
                                })
                            except:
                                continue
                    
                    print(f"[{datetime.now()}] Loaded {len(self.known_face_encodings)} face encodings")
                    return True
                elif response.status_code == 401:
                    print(f"[{datetime.now()}] ERROR: Invalid device API key")
                    return False
                else:
                    print(f"[{datetime.now()}] ERROR: Failed to fetch encodings (status {response.status_code})")
            except Exception as e:
                print(f"[{datetime.now()}] ERROR: Attempt {attempt + 1}/{RETRY_ATTEMPTS}: {str(e)}")
                if attempt < RETRY_ATTEMPTS - 1:
                    time.sleep(RETRY_DELAY)
        
        print(f"[{datetime.now()}] Failed to fetch encodings after {RETRY_ATTEMPTS} attempts")
        return False

    def get_last_log(self, student_id):
        """Get last log for a student to determine if next event is ENTRY or EXIT"""
        try:
            headers = {'x-device-key': DEVICE_API_KEY}
            response = requests.get(f'{API_BASE_URL}/api/logs/last/{student_id}', headers=headers, timeout=5)
            
            if response.status_code == 200:
                log = response.json()
                return log.get('event_type', 'EXIT')  # Default to EXIT if no logs
            else:
                print(f"[{datetime.now()}] Warning: Could not get last log for {student_id}")
                return 'EXIT'
        except Exception as e:
            print(f"[{datetime.now()}] Warning: Error getting last log: {str(e)}")
            return 'EXIT'

    def post_log(self, student_id, event_type, confidence_score):
        """Post entry/exit log to backend with retry logic"""
        for attempt in range(RETRY_ATTEMPTS):
            try:
                headers = {'x-device-key': DEVICE_API_KEY}
                data = {
                    'student_id': student_id,
                    'event_type': event_type,
                    'confidence_score': round(confidence_score, 2),
                    'location': 'Main Gate'
                }
                
                response = requests.post(f'{API_BASE_URL}/api/logs', json=data, headers=headers, timeout=10)
                
                if response.status_code == 201:
                    print(f"[{datetime.now()}] SUCCESS: {event_type} logged for {student_id}")
                    return True
                else:
                    print(f"[{datetime.now()}] ERROR: Failed to post log (status {response.status_code})")
            except Exception as e:
                print(f"[{datetime.now()}] ERROR: Attempt {attempt + 1}/{RETRY_ATTEMPTS}: {str(e)}")
                if attempt < RETRY_ATTEMPTS - 1:
                    time.sleep(RETRY_DELAY)
        
        return False

    def process_frame(self, frame):
        """Detect faces in frame and handle entry/exit logic"""
        current_time = time.time()
        small_frame = cv2.resize(frame, (0, 0), fx=0.25, fy=0.25)
        rgb_small_frame = cv2.cvtColor(small_frame, cv2.COLOR_BGR2RGB)
        
        # Detect face locations and encodings
        face_locations = face_recognition.face_locations(rgb_small_frame, model='hog')
        face_encodings = face_recognition.face_encodings(rgb_small_frame, face_locations)
        
        face_labels = []
        face_colors = []
        detected_faces = set()
        
        for face_encoding, face_location in zip(face_encodings, face_locations):
            # Compare with known faces
            distances = face_recognition.face_distance(self.known_face_encodings, face_encoding)
            
            if len(distances) > 0:
                best_match_index = np.argmin(distances)
                
                if distances[best_match_index] < FACE_DISTANCE_THRESHOLD:
                    label = self.known_face_labels[best_match_index]
                    student_id = label['student_id']
                    detected_faces.add(student_id)
                    
                    # Check cooldown
                    if current_time - self.student_cooldowns[student_id] >= COOLDOWN_SECONDS:
                        # Get last log and determine event type
                        last_event = self.get_last_log(student_id)
                        event_type = 'EXIT' if last_event == 'ENTRY' else 'ENTRY'
                        
                        # Post log
                        confidence = 1 - distances[best_match_index]
                        self.post_log(student_id, event_type, confidence)
                        
                        # Update cooldown
                        self.student_cooldowns[student_id] = current_time
                        
                        face_colors.append((0, 255, 0))  # Green for processed
                    else:
                        face_colors.append((255, 165, 0))  # Orange for cooldown
                    
                    face_labels.append(f"{label['name']}")
                else:
                    face_labels.append('Unknown')
                    face_colors.append((0, 0, 255))  # Red for unknown
            else:
                face_labels.append('Unknown')
                face_colors.append((0, 0, 255))
        
        self.faces_in_frame = detected_faces
        
        # Draw results on original frame
        for (top, right, bottom, left), label, color in zip(face_locations, face_labels, face_colors):
            top *= 4
            right *= 4
            bottom *= 4
            left *= 4
            
            cv2.rectangle(frame, (left, top), (right, bottom), color, 2)
            cv2.putText(frame, label, (left, top - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)
        
        return frame

    def run(self):
        """Main execution loop"""
        print(f"[{datetime.now()}] Starting Face Recognition Client")
        print(f"[{datetime.now()}] Server: {API_BASE_URL}")
        
        # Fetch encodings on startup
        if not self.fetch_encodings():
            print(f"[{datetime.now()}] WARNING: Could not fetch encodings on startup. Retrying...")
            time.sleep(5)
            self.fetch_encodings()
        
        # Open webcam
        video_capture = cv2.VideoCapture(0)
        video_capture.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        video_capture.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        video_capture.set(cv2.CAP_PROP_FPS, 30)
        
        last_reload = time.time()
        reload_interval = 3600  # Reload encodings every hour
        
        try:
            while True:
                ret, frame = video_capture.read()
                
                if not ret:
                    print(f"[{datetime.now()}] Warning: Could not read frame from webcam")
                    time.sleep(1)
                    continue
                
                # Process frame
                frame = self.process_frame(frame)
                
                # Show frame
                cv2.imshow('Campus Entry/Exit Monitoring', frame)
                
                # Reload encodings periodically
                current_time = time.time()
                if current_time - last_reload > reload_interval:
                    print(f"[{datetime.now()}] Reloading student encodings...")
                    self.fetch_encodings()
                    last_reload = current_time
                
                # Press 'q' to quit
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
        
        except KeyboardInterrupt:
            print(f"\n[{datetime.now()}] Shutting down gracefully...")
        except Exception as e:
            print(f"[{datetime.now()}] ERROR: {str(e)}")
        finally:
            video_capture.release()
            cv2.destroyAllWindows()

if __name__ == '__main__':
    client = FaceRecognitionClient()
    client.run()
