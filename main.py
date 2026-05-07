from fastapi import FastAPI, UploadFile, File
import os
import cv2
import mediapipe as mp

app = FastAPI()

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


# ✅ Fonction d'analyse vidéo
def analyze_video(video_path):
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose()

    cap = cv2.VideoCapture(video_path)

    frame_count = 0
    detected = False

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        frame_count += 1

        # On analyse 1 frame sur 10 pour aller plus vite
        if frame_count % 10 != 0:
            continue

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(rgb)

        if results.pose_landmarks:
            detected = True

    cap.release()

    if detected:
        return "Mouvement détecté (pose trouvée)"
    else:
        return "Aucune pose détectée"


# ✅ Route upload
@app.post("/upload/")
async def upload_video(file: UploadFile = File(...)):
    file_path = os.path.join(UPLOAD_DIR, file.filename)

    # Sauvegarde du fichier
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())

    print(f"VIDEO RECEIVED: {file.filename}")

    # Analyse vidéo
    analysis = analyze_video(file_path)

    # Réponse JSON pour Flutter
    return {
        "message": "video uploaded successfully",
        "filename": file.filename,
        "analysis": analysis
    }