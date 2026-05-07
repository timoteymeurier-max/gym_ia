from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import os
import cv2
import mediapipe as mp
import numpy as np

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

def calculate_angle(a, b, c):
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)
    radians = np.arctan2(c[1]-b[1], c[0]-b[0]) - np.arctan2(a[1]-b[1], a[0]-b[0])
    angle = np.abs(radians * 180.0 / np.pi)
    if angle > 180.0:
        angle = 360 - angle
    return angle

def analyze_video(video_path):
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose()
    cap = cv2.VideoCapture(video_path)
    frame_count = 0
    angles_knee = []
    angles_hip = []

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        frame_count += 1
        if frame_count % 10 != 0:
            continue
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(rgb)
        if results.pose_landmarks:
            lm = results.pose_landmarks.landmark
            hip = [lm[mp_pose.PoseLandmark.LEFT_HIP.value].x, lm[mp_pose.PoseLandmark.LEFT_HIP.value].y]
            knee = [lm[mp_pose.PoseLandmark.LEFT_KNEE.value].x, lm[mp_pose.PoseLandmark.LEFT_KNEE.value].y]
            ankle = [lm[mp_pose.PoseLandmark.LEFT_ANKLE.value].x, lm[mp_pose.PoseLandmark.LEFT_ANKLE.value].y]
            shoulder = [lm[mp_pose.PoseLandmark.LEFT_SHOULDER.value].x, lm[mp_pose.PoseLandmark.LEFT_SHOULDER.value].y]
            angles_knee.append(calculate_angle(hip, knee, ankle))
            angles_hip.append(calculate_angle(shoulder, hip, knee))

    cap.release()

    if not angles_knee:
        return {
            "analysis": "Aucune pose detectee dans la video.",
            "knee_min": None,
            "hip_avg": None,
            "reps": 0,
            "feedback": []
        }

    min_knee = round(float(np.min(angles_knee)), 1)
    avg_hip = round(float(np.mean(angles_hip)), 1)

    # Comptage des répétitions
    reps = 0
    state = "up"  # état initial : debout
    for angle in angles_knee:
        if state == "up" and angle < 90:
            state = "down"
        elif state == "down" and angle > 150:
            state = "up"
            reps += 1

    feedback = []
    if min_knee > 90:
        feedback.append("Squat pas assez profond - descends plus bas")
    else:
        feedback.append("Bonne profondeur de squat")

    if avg_hip < 45:
        feedback.append("Penche davantage le buste en avant")
    else:
        feedback.append("Inclinaison du buste correcte")

    analysis = " | ".join(feedback)

    return {
        "analysis": analysis,
        "knee_min": min_knee,
        "hip_avg": avg_hip,
        "reps": reps,
        "feedback": feedback
    }

@app.post("/upload/")
async def upload_video(file: UploadFile = File(...)):
    file_path = os.path.join(UPLOAD_DIR, file.filename)
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())
    print(f"VIDEO RECEIVED: {file.filename}")
    result = analyze_video(file_path)
    return {
        "message": "video uploaded successfully",
        "filename": file.filename,
        **result
    }