from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq
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

from dotenv import load_dotenv
load_dotenv()
groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))

def calculate_angle(a, b, c):
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)
    radians = np.arctan2(c[1]-b[1], c[0]-b[0]) - np.arctan2(a[1]-b[1], a[0]-b[0])
    angle = np.abs(radians * 180.0 / np.pi)
    if angle > 180.0:
        angle = 360 - angle
    return angle

def get_ai_coaching(data: dict, objectif: str) -> str:
    prompt = f"""Tu es un coach sportif expert en biomécanique et musculation.
Voici les données d'analyse d'une série de squats :

- Répétitions : {data['reps']}
- Angle genou minimum gauche : {data['knee_min_left']}°
- Angle genou minimum droit : {data['knee_min_right']}°
- Angle hanche moyen gauche : {data['hip_avg_left']}°
- Angle hanche moyen droit : {data['hip_avg_right']}°
- Angle du dos moyen : {data['back_avg']}°
- Asymétrie gauche/droite : {data['symmetry']}°
- Stabilité genou gauche : {data['knee_stability_left']}
- Stabilité genou droit : {data['knee_stability_right']}

Objectif de l'athlète : {objectif}

Donne une analyse complète et structurée avec :
1. Les points forts de la série
2. Les points faibles et corrections à apporter
3. Des conseils spécifiques selon l'objectif "{objectif}"
4. Une recommandation sur l'augmentation de charge (oui/non et pourquoi)

Sois précis, bienveillant et professionnel. Réponds en français."""

    response = groq_client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=1000,
    )
    return response.choices[0].message.content

def analyze_video(video_path):
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose()
    cap = cv2.VideoCapture(video_path)
    frame_count = 0

    angles_knee_left = []
    angles_knee_right = []
    angles_hip_left = []
    angles_hip_right = []
    angles_back = []
    knee_x_left = []
    knee_x_right = []

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        frame_count += 1
        if frame_count % 5 != 0:
            continue
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(rgb)
        if results.pose_landmarks:
            lm = results.pose_landmarks.landmark
            l_shoulder = [lm[mp_pose.PoseLandmark.LEFT_SHOULDER.value].x, lm[mp_pose.PoseLandmark.LEFT_SHOULDER.value].y]
            l_hip = [lm[mp_pose.PoseLandmark.LEFT_HIP.value].x, lm[mp_pose.PoseLandmark.LEFT_HIP.value].y]
            l_knee = [lm[mp_pose.PoseLandmark.LEFT_KNEE.value].x, lm[mp_pose.PoseLandmark.LEFT_KNEE.value].y]
            l_ankle = [lm[mp_pose.PoseLandmark.LEFT_ANKLE.value].x, lm[mp_pose.PoseLandmark.LEFT_ANKLE.value].y]
            r_shoulder = [lm[mp_pose.PoseLandmark.RIGHT_SHOULDER.value].x, lm[mp_pose.PoseLandmark.RIGHT_SHOULDER.value].y]
            r_hip = [lm[mp_pose.PoseLandmark.RIGHT_HIP.value].x, lm[mp_pose.PoseLandmark.RIGHT_HIP.value].y]
            r_knee = [lm[mp_pose.PoseLandmark.RIGHT_KNEE.value].x, lm[mp_pose.PoseLandmark.RIGHT_KNEE.value].y]
            r_ankle = [lm[mp_pose.PoseLandmark.RIGHT_ANKLE.value].x, lm[mp_pose.PoseLandmark.RIGHT_ANKLE.value].y]

            angles_knee_left.append(calculate_angle(l_hip, l_knee, l_ankle))
            angles_knee_right.append(calculate_angle(r_hip, r_knee, r_ankle))
            angles_hip_left.append(calculate_angle(l_shoulder, l_hip, l_knee))
            angles_hip_right.append(calculate_angle(r_shoulder, r_hip, r_knee))
            vertical = [l_hip[0], l_hip[1] - 1]
            angles_back.append(calculate_angle(l_shoulder, l_hip, vertical))
            knee_x_left.append(l_knee[0])
            knee_x_right.append(r_knee[0])

    cap.release()

    if not angles_knee_left:
        return None

    reps = 0
    state = "up"
    for angle in angles_knee_left:
        if state == "up" and angle < 90:
            state = "down"
        elif state == "down" and angle > 150:
            state = "up"
            reps += 1

    return {
        "reps": reps,
        "knee_min_left": round(float(np.min(angles_knee_left)), 1),
        "knee_min_right": round(float(np.min(angles_knee_right)), 1),
        "hip_avg_left": round(float(np.mean(angles_hip_left)), 1),
        "hip_avg_right": round(float(np.mean(angles_hip_right)), 1),
        "back_avg": round(float(np.mean(angles_back)), 1),
        "symmetry": round(abs(float(np.min(angles_knee_left)) - float(np.min(angles_knee_right))), 1),
        "knee_stability_left": round(float(np.std(knee_x_left)) * 100, 2),
        "knee_stability_right": round(float(np.std(knee_x_right)) * 100, 2),
    }

@app.post("/upload/")
async def upload_video(file: UploadFile = File(...), objectif: str = "force"):
    file_path = os.path.join(UPLOAD_DIR, file.filename)
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())
    print(f"VIDEO RECEIVED: {file.filename}")
    data = analyze_video(file_path)
    if data is None:
        return {"error": "Aucune pose detectee dans la video."}
    print("Generating AI coaching...")
    coaching = get_ai_coaching(data, objectif)
    return {
        "message": "video uploaded successfully",
        "filename": file.filename,
        **data,
        "coaching": coaching
    }

    from fastapi import Form
from typing import Optional

conversation_history = []

@app.post("/chat/")
async def chat(
    message: str = Form(...),
    objectif: str = Form(default="force"),
    file: Optional[UploadFile] = File(default=None)
):
    global conversation_history

    user_content = message

    # Si une vidéo est envoyée
    if file and file.filename:
        file_path = os.path.join(UPLOAD_DIR, file.filename)
        with open(file_path, "wb") as buffer:
            buffer.write(await file.read())
        data = analyze_video(file_path)
        if data:
            user_content += f"""

[Vidéo analysée : {file.filename}]
- Répétitions : {data['reps']}
- Angle genou min gauche : {data['knee_min_left']}°
- Angle genou min droit : {data['knee_min_right']}°
- Angle hanche moyen gauche : {data['hip_avg_left']}°
- Angle hanche moyen droit : {data['hip_avg_right']}°
- Angle dos : {data['back_avg']}°
- Asymétrie : {data['symmetry']}°
- Stabilité genou gauche : {data['knee_stability_left']}
- Stabilité genou droit : {data['knee_stability_right']}
"""

    # Ajout du message dans l'historique
    conversation_history.append({
        "role": "user",
        "content": user_content
    })

    # Système prompt
    system_prompt = f"""Tu es un coach sportif expert en musculation, biomécanique et nutrition sportive.
Tu accompagnes l'athlète comme un vrai coach personnel.
Son objectif actuel : {objectif}.
Tu analyses les vidéos de squats et autres exercices, tu donnes des conseils précis, bienveillants et professionnels.
Tu réponds toujours en français."""

    response = groq_client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": system_prompt},
            *conversation_history
        ],
        max_tokens=1000,
    )

    assistant_message = response.choices[0].message.content

    conversation_history.append({
        "role": "assistant",
        "content": assistant_message
    })

    # Garder seulement les 20 derniers messages
    if len(conversation_history) > 20:
        conversation_history = conversation_history[-20:]

    return {
        "response": assistant_message,
        "has_video": file is not None and file.filename != ""
    }

@app.delete("/chat/reset")
async def reset_chat():
    global conversation_history
    conversation_history = []
    return {"message": "Conversation réinitialisée"}