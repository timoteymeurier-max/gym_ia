from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq
from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Text, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from dotenv import load_dotenv
from datetime import datetime
from typing import Optional
import os
import cv2
import mediapipe as mp
import numpy as np

load_dotenv()

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

groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))

# Base de données
engine = create_engine("sqlite:///sessions.db")
Base = declarative_base()

class Conversation(Base):
    __tablename__ = "conversations"
    id = Column(Integer, primary_key=True)
    title = Column(String, default="Nouvelle conversation")
    objectif = Column(String, default="force")
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    messages = relationship("Message", back_populates="conversation", cascade="all, delete")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"))
    role = Column(String)
    content = Column(Text)
    video_filename = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.now)
    conversation = relationship("Conversation", back_populates="messages")

Base.metadata.create_all(engine)
DBSession = sessionmaker(bind=engine)

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
            r_knee = [lm[mp_pose.PoseLandmark.RIGHT_KNEE.value].x, lm[mp_pose.PoseLandmark.RIGHT_HIP.value].y]
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

def get_ai_response(messages_history, user_message, objectif, video_data=None):
    content = user_message
    if video_data:
        content += f"""

[Vidéo analysée]
- Répétitions : {video_data['reps']}
- Angle genou min gauche : {video_data['knee_min_left']}°
- Angle genou min droit : {video_data['knee_min_right']}°
- Angle hanche moyen gauche : {video_data['hip_avg_left']}°
- Angle hanche moyen droit : {video_data['hip_avg_right']}°
- Angle dos : {video_data['back_avg']}°
- Asymétrie : {video_data['symmetry']}°
- Stabilité genou gauche : {video_data['knee_stability_left']}
- Stabilité genou droit : {video_data['knee_stability_right']}
"""

    system_prompt = f"""Tu es un coach sportif expert en musculation, biomécanique et nutrition sportive.
Tu accompagnes l'athlète comme un vrai coach personnel. Son objectif : {objectif}.
Tu analyses les vidéos de squats, donnes des conseils précis, bienveillants et professionnels.
Quand tu reçois des données vidéo, structure ta réponse avec les points forts, points faibles, conseils et recommandation de charge.
Réponds toujours en français."""

    history = [{"role": m["role"], "content": m["content"]} for m in messages_history]
    history.append({"role": "user", "content": content})

    response = groq_client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "system", "content": system_prompt}, *history],
        max_tokens=1500,
    )
    return response.choices[0].message.content

# ===== ENDPOINTS CONVERSATIONS =====

@app.post("/conversations/")
async def create_conversation(objectif: str = Form(default="force"), title: str = Form(default="Nouvelle conversation")):
    db = DBSession()
    conv = Conversation(title=title, objectif=objectif)
    db.add(conv)
    db.commit()
    db.refresh(conv)
    result = {"id": conv.id, "title": conv.title, "objectif": conv.objectif, "created_at": conv.created_at.strftime("%d/%m/%Y %H:%M")}
    db.close()
    return result

@app.get("/conversations/")
async def get_conversations():
    db = DBSession()
    convs = db.query(Conversation).order_by(Conversation.updated_at.desc()).all()
    result = [{"id": c.id, "title": c.title, "objectif": c.objectif, "updated_at": c.updated_at.strftime("%d/%m/%Y %H:%M")} for c in convs]
    db.close()
    return result

@app.delete("/conversations/{conv_id}")
async def delete_conversation(conv_id: int):
    db = DBSession()
    conv = db.query(Conversation).filter(Conversation.id == conv_id).first()
    if conv:
        db.delete(conv)
        db.commit()
    db.close()
    return {"message": "deleted"}

@app.get("/conversations/{conv_id}/messages")
async def get_messages(conv_id: int):
    db = DBSession()
    messages = db.query(Message).filter(Message.conversation_id == conv_id).order_by(Message.created_at).all()
    result = [{"role": m.role, "content": m.content, "video_filename": m.video_filename} for m in messages]
    db.close()
    return result

@app.post("/conversations/{conv_id}/chat")
async def chat(
    conv_id: int,
    message: str = Form(default=""),
    file: Optional[UploadFile] = File(default=None)
):
    db = DBSession()
    conv = db.query(Conversation).filter(Conversation.id == conv_id).first()
    if not conv:
        db.close()
        return {"error": "Conversation introuvable"}

    video_data = None
    video_filename = None

    if file and file.filename:
        file_path = os.path.join(UPLOAD_DIR, file.filename)
        with open(file_path, "wb") as buffer:
            buffer.write(await file.read())
        video_data = analyze_video(file_path)
        video_filename = file.filename

    user_text = message if message else "Analyse cette vidéo et donne-moi des conseils détaillés"

    # Historique
    history = db.query(Message).filter(Message.conversation_id == conv_id).order_by(Message.created_at).all()
    history_list = [{"role": m.role, "content": m.content} for m in history]

    # Réponse IA
    ai_response = get_ai_response(history_list, user_text, conv.objectif, video_data)

    # Sauvegarde messages
    user_msg = Message(conversation_id=conv_id, role="user", content=user_text, video_filename=video_filename)
    assistant_msg = Message(conversation_id=conv_id, role="assistant", content=ai_response)
    db.add(user_msg)
    db.add(assistant_msg)

    # Titre auto si première question
    if len(history) == 0:
        conv.title = user_text[:40] + ("..." if len(user_text) > 40 else "")

    conv.updated_at = datetime.now()
    db.commit()
    db.close()

    return {
        "response": ai_response,
        "video_data": video_data,
        "video_filename": video_filename,
    }