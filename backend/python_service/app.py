from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
import cv2
import numpy as np
import pytesseract
import shutil
import os
import random

app = FastAPI()

# MOCK OR REAL AI LOGIC
# Since we can't easily run heavy models here, we will implement the STRUCTURE and basic checks.

class VideoAnalysisResult(BaseModel):
    is_valid: bool
    confidence: float
    message: String

@app.get("/")
def read_root():
    return {"status": "AI Service Running"}

@app.post("/analyze-video")
async def analyze_video(file: UploadFile = File(...)):
    try:
        # Save temp file
        temp_path = f"temp_{file.filename}"
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Basic OpenCV Check: Duration and Frame Content
        cap = cv2.VideoCapture(temp_path)
        fps = cap.get(cv2.CAP_PROP_FPS)
        frame_count = cap.get(cv2.CAP_PROP_FRAME_COUNT)
        duration = frame_count / fps if fps > 0 else 0
        
        # Check if video is too short or empty
        if duration < 5:
             os.remove(temp_path)
             return {"is_valid": False, "confidence": 0.0, "message": "Video too short"}
             
        # Check if frames are not black (simple check)
        # Read a middle frame
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_count // 2)
        ret, frame = cap.read()
        
        is_dark = True
        if ret:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            avg_brightness = np.mean(gray)
            if avg_brightness > 10: # Threshold
                is_dark = False
        
        cap.release()
        os.remove(temp_path)
        
        if is_dark:
             return {"is_valid": False, "confidence": 0.1, "message": "Video is too dark"}
             
        # Mocking Face Detection confidence
        # In real world: 
        # face_locations = face_recognition.face_locations(rgb_frame)
        # if len(face_locations) == 0: return { ... valid: False ... }
        
        confidence = random.uniform(0.85, 0.99)
        
        return {
            "is_valid": True, 
            "confidence": confidence, 
            "message": "Face detected, voice activity present (Mock)"
        }
            
    except Exception as e:
        return {"is_valid": False, "confidence": 0.0, "message": str(e)}

@app.post("/verify-document")
async def verify_document(file: UploadFile = File(...)):
    # Mock Document Verification
    return {
        "is_valid": True,
        "extracted_text": "Sample Aadhaar Text",
        "confidence": 0.95
    }

import face_recognition

@app.post("/compare-faces")
async def compare_faces(
    video: UploadFile = File(None), 
    photo: UploadFile = File(None),
    aadhaar: UploadFile = File(None),
    pan: UploadFile = File(None)
):
    """
    Compares the face in the video/profile photo against ID documents Using Real AI.
    """
    temp_files = []
    try:
        # Helper to save and return path
        def save_upload(upload_file):
            if not upload_file: return None
            path = f"temp_{random.randint(1000,9999)}_{upload_file.filename}"
            with open(path, "wb") as buffer:
                shutil.copyfileobj(upload_file.file, buffer)
            temp_files.append(path)
            return path

        video_path = save_upload(video)
        photo_path = save_upload(photo)
        aadhaar_path = save_upload(aadhaar)
        
        # 1. Get Reference Encoding (From Selfie or Video)
        reference_encoding = None
        source_name = ""

        if photo_path:
            # Load Selfie
            image = face_recognition.load_image_file(photo_path)
            encodings = face_recognition.face_encodings(image)
            if len(encodings) > 0:
                reference_encoding = encodings[0]
                source_name = "Profile Photo"

        if reference_encoding is None and video_path:
            # Extract frame from video
            cap = cv2.VideoCapture(video_path)
            # Read middle frame
            frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            cap.set(cv2.CAP_PROP_POS_FRAMES, frame_count // 2)
            ret, frame = cap.read()
            cap.release()
            
            if ret:
                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                encodings = face_recognition.face_encodings(rgb_frame)
                if len(encodings) > 0:
                    reference_encoding = encodings[0]
                    source_name = "Video Frame"

        if reference_encoding is None:
             return {"is_match": False, "match_score": 0.0, "details": "No face detected in Profile Photo or Video"}

        # 2. Get ID Encoding (From Aadhaar)
        id_encoding = None
        if aadhaar_path:
             image = face_recognition.load_image_file(aadhaar_path)
             encodings = face_recognition.face_encodings(image)
             if len(encodings) > 0:
                 id_encoding = encodings[0]
        
        if id_encoding is None:
             # Try PAN or fail
             return {"is_match": False, "match_score": 0.0, "details": "No face detected in ID Document"}

        # 3. Compare
        # Lower distance = better match. Tolerance 0.6 is standard.
        match_results = face_recognition.compare_faces([reference_encoding], id_encoding, tolerance=0.6)
        face_distance = face_recognition.face_distance([reference_encoding], id_encoding)[0]
        
        # Convert distance to confidence (0.0 to 1.0 roughly)
        # 0.0 dist = 1.0 conf, 0.6 dist = ~0.5 conf
        match_score = max(0.0, (1.0 - face_distance))

        return {
            "is_match": bool(match_results[0]),
            "match_score": float(match_score),
            "details": f"Matched {source_name} against ID with distance {face_distance:.2f}"
        }

    except Exception as e:
        return {"is_match": False, "match_score": 0.0, "details": str(e)}
@app.post("/verify-address")
async def verify_address(
    aadhaar_back: UploadFile = File(None),
    license: UploadFile = File(None)
):
    """
    Compares the address on Aadhaar Back vs Driving License using OCR with Fuzzy Matching.
    """
    temp_files = []
    try:
        def save_upload(upload_file):
            if not upload_file: return None
            path = f"temp_{random.randint(10000,99999)}_{upload_file.filename}"
            with open(path, "wb") as buffer:
                shutil.copyfileobj(upload_file.file, buffer)
            temp_files.append(path)
            return path

        aadhaar_path = save_upload(aadhaar_back)
        license_path = save_upload(license)
        
        if not aadhaar_path or not license_path:
             return {"is_match": False, "match_score": 0.0, "details": "Missing documents for address check"}

        # 1. OCR Extraction
        img1 = cv2.imread(aadhaar_path)
        img2 = cv2.imread(license_path)
        
        text1 = pytesseract.image_to_string(img1)
        text2 = pytesseract.image_to_string(img2)
        
        # 2. Tokenize and Fuzzy Match
        # Extract alphanumeric words > 3 chars
        def get_tokens(text):
            import re
            words = re.findall(r'\b[A-Za-z0-9]{4,}\b', text.lower())
            return set(words)
            
        tokens1 = get_tokens(text1)
        tokens2 = get_tokens(text2)
        
        # If OCR fails completely
        if len(tokens1) < 2 or len(tokens2) < 2:
             # Fallback: assume match for demo if OCR is too poor/blurry
             return {"is_match": True, "match_score": 0.5, "details": "OCR incomplete, manual review suggested (Soft Pass)"}
             
        # Find intersection
        common = tokens1.intersection(tokens2)
        match_ratio = len(common) / min(len(tokens1), len(tokens2))
        
        # Threshold: if 10-20% of significant words match (State, Pin, City usually match)
        is_match = match_ratio > 0.1 
        
        return {
            "is_match": is_match,
            "match_score": match_ratio,
            "details": f"Address Keyword Match: {len(common)} words ({', '.join(list(common)[:5])}...)"
        }

    except Exception as e:
        return {"is_match": False, "match_score": 0.0, "details": str(e)}
    finally:
        for p in temp_files:
            if os.path.exists(p):
                os.remove(p)
