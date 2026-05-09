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
import json

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

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///sessions.db")
engine = create_engine(DATABASE_URL)
Base = declarative_base()

class Conversation(Base):
    __tablename__ = "conversations"
    id = Column(Integer, primary_key=True)
    title = Column(String, default="Nouvelle conversation")
    objectif = Column(String, default="general")
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

class UserData(Base):
    __tablename__ = "user_data"
    id = Column(Integer, primary_key=True)
    key = Column(String, unique=True)
    value = Column(Text)
    updated_at = Column(DateTime, default=datetime.now)

Base.metadata.create_all(engine)
DBSession = sessionmaker(bind=engine)

def get_user_data(db):
    rows = db.query(UserData).all()
    return {r.key: r.value for r in rows}

def set_user_data(db, key, value):
    row = db.query(UserData).filter(UserData.key == key).first()
    if row:
        row.value = str(value)
        row.updated_at = datetime.now()
    else:
        db.add(UserData(key=key, value=str(value)))
    db.commit()

def extract_user_data_from_message(message, ai_response):
    prompt = f"""Analyse ce message d'un utilisateur et la réponse du coach.
Extrait UNIQUEMENT les informations factuelles importantes sur l'utilisateur.

Message utilisateur: {message}
Réponse coach: {ai_response}

Retourne UNIQUEMENT un JSON valide avec les clés pertinentes parmi :
- name (prénom)
- age (age en chiffre)
- weight (poids en kg, chiffre)
- height (taille en cm, chiffre)
- goal (objectif principal)
- level (debutant/intermediaire/avance)
- squat_weight (charge squat en kg)
- bench_weight (charge développé couché en kg)
- deadlift_weight (charge soulevé de terre en kg)
- sessions_per_week (séances par semaine)
- last_session_date (date dernière séance)
- streak (jours consécutifs)
- calories (calories journalières)

Si aucune info n'est trouvée retourne {{}}.
Ne retourne QUE le JSON, sans explication."""

    try:
        response = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=300,
        )
        text = response.choices[0].message.content.strip()
        text = text.replace("```json", "").replace("```", "").strip()
        return json.loads(text)
    except:
        return {}

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
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
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
        if frame_count % 3 != 0:
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
    rep_depths = []
    descent_speeds = []
    time_in_hole = []
    descent_start = None
    bottom_start = None

    for i, angle in enumerate(angles_knee_left):
        if state == "up" and angle < 90:
            state = "down"
            descent_start = i
        elif state == "down" and angle < 75:
            if bottom_start is None:
                bottom_start = i
            rep_depths.append(angle)
        elif state == "down" and angle > 150:
            state = "up"
            reps += 1
            if descent_start is not None and bottom_start is not None:
                descent_speeds.append((bottom_start - descent_start) * 3 / fps)
                time_in_hole.append((i - bottom_start) * 3 / fps)
            descent_start = None
            bottom_start = None

    min_knee_left = round(float(np.min(angles_knee_left)), 1)
    min_knee_right = round(float(np.min(angles_knee_right)), 1)
    avg_hip_left = round(float(np.mean(angles_hip_left)), 1)
    avg_hip_right = round(float(np.mean(angles_hip_right)), 1)
    avg_back = round(float(np.mean(angles_back)), 1)
    symmetry = round(abs(min_knee_left - min_knee_right), 1)
    stab_left = round(float(np.std(knee_x_left)) * 100, 2)
    stab_right = round(float(np.std(knee_x_right)) * 100, 2)
    avg_descent_time = round(float(np.mean(descent_speeds)), 2) if descent_speeds else None
    avg_time_in_hole = round(float(np.mean(time_in_hole)), 2) if time_in_hole else None
    max_depth = round(float(np.min(rep_depths)), 1) if rep_depths else min_knee_left

    score = 100
    if min_knee_left > 90: score -= 20
    elif min_knee_left > 80: score -= 10
    if symmetry > 10: score -= 15
    elif symmetry > 5: score -= 7
    if avg_back > 45: score -= 15
    elif avg_back > 35: score -= 7
    if stab_left > 8 or stab_right > 8: score -= 10
    if avg_descent_time and avg_descent_time < 1.0: score -= 10
    score = max(0, min(100, score))

    return {
        "reps": reps,
        "score": score,
        "knee_min_left": min_knee_left,
        "knee_min_right": min_knee_right,
        "hip_avg_left": avg_hip_left,
        "hip_avg_right": avg_hip_right,
        "back_avg": avg_back,
        "symmetry": symmetry,
        "knee_stability_left": stab_left,
        "knee_stability_right": stab_right,
        "max_depth": max_depth,
        "avg_descent_time": avg_descent_time,
        "avg_time_in_hole": avg_time_in_hole,
        "depth_interpretation": "Excellente profondeur" if min_knee_left < 70 else "Bonne profondeur" if min_knee_left < 90 else "Profondeur insuffisante",
        "back_interpretation": "Dos bien droit" if avg_back < 25 else "Légère inclinaison" if avg_back < 40 else "Trop penché en avant",
        "symmetry_interpretation": "Très bonne symétrie" if symmetry < 3 else "Symétrie correcte" if symmetry < 7 else "Asymétrie notable",
        "speed_interpretation": "Descente trop rapide" if avg_descent_time and avg_descent_time < 1.0 else "Vitesse correcte" if avg_descent_time else "Non mesurable",
    }

def build_video_table(video_data):
    descent = f"{video_data['avg_descent_time']}s" if video_data.get('avg_descent_time') else 'N/A'
    hole = f"{video_data['avg_time_in_hole']}s" if video_data.get('avg_time_in_hole') else 'N/A'
    return (
        f"📊 **Analyse — Score {video_data.get('score', '?')}/100**\n\n"
        f"| Métrique | Gauche | Droite |\n"
        f"|----------|--------|--------|\n"
        f"| Genou min | {video_data['knee_min_left']}° | {video_data['knee_min_right']}° |\n"
        f"| Hanche moy | {video_data['hip_avg_left']}° | {video_data['hip_avg_right']}° |\n"
        f"| Dos | {video_data['back_avg']}° | {video_data.get('back_interpretation', '')} |\n"
        f"| Symétrie | {video_data['symmetry']}° | {video_data.get('symmetry_interpretation', '')} |\n"
        f"| Vitesse descente | {descent} | {video_data.get('speed_interpretation', '')} |\n"
        f"| Temps en bas | {hole} | - |\n"
        f"| Reps | {video_data['reps']} | - |\n\n"
    )

def get_ai_response(messages_history, user_message, objectif, video_data=None, user_profile=None):
    content = user_message

    if video_data:
        content += f"""

[Analyse vidéo complète]
Score global : {video_data.get('score', '?')}/100
Répétitions : {video_data['reps']}
Genou gauche min : {video_data['knee_min_left']}° ({video_data.get('depth_interpretation', '')})
Genou droit min : {video_data['knee_min_right']}°
Hanche gauche moy : {video_data['hip_avg_left']}°
Hanche droite moy : {video_data['hip_avg_right']}°
Dos moy : {video_data['back_avg']}° ({video_data.get('back_interpretation', '')})
Symétrie : {video_data['symmetry']}° ({video_data.get('symmetry_interpretation', '')})
Stabilité genou G/D : {video_data['knee_stability_left']} / {video_data['knee_stability_right']}
Vitesse descente : {video_data.get('avg_descent_time', 'N/A')}s ({video_data.get('speed_interpretation', '')})
Temps en position basse : {video_data.get('avg_time_in_hole', 'N/A')}s
Profondeur max : {video_data.get('max_depth', 'N/A')}°
"""

    profile_text = ""
    if user_profile:
        profile_text = f"""
Profil de l'athlète :
- Prénom : {user_profile.get('name', 'Non renseigné')}
- Âge : {user_profile.get('age', 'Non renseigné')} ans
- Poids : {user_profile.get('weight', 'Non renseigné')} kg
- Taille : {user_profile.get('height', 'Non renseigné')} cm
- Niveau : {user_profile.get('level', 'Non renseigné')}
- Objectif : {user_profile.get('goal', 'Non renseigné')}
- Squat : {user_profile.get('squat_weight', 'Non renseigné')} kg
- Développé couché : {user_profile.get('bench_weight', 'Non renseigné')} kg
- Soulevé de terre : {user_profile.get('deadlift_weight', 'Non renseigné')} kg
- Séances/semaine : {user_profile.get('sessions_per_week', 'Non renseigné')}
"""

    system_prompt = f"""Tu es un coach sportif IA nouvelle génération. Tu parles comme un vrai coach qui connaît son athlète, pas comme un robot.

{profile_text}

TON STYLE :
- Direct, motivant, accessible
- Phrases courtes et percutantes
- Utilise des emojis avec modération (max 3-4 par réponse)
- Tutoie toujours l'athlète
- Utilise le prénom si disponible
- Jamais plus de 200 mots sauf si analyse vidéo détaillée

QUAND TU ANALYSES UNE VIDÉO, structure TOUJOURS comme ça :
**Ce que tu fais bien ✅**
(1-2 points max, sois précis)

**Ce qu'on améliore 🎯**
(1-2 points max, avec correction concrète)

**Conseil pour la prochaine séance 💡**
(1 conseil actionnable et précis)

**Charge** : Augmenter / Maintenir / Réduire — et pourquoi en 1 phrase

QUAND TU RÉPONDS À UNE QUESTION :
- Réponse directe en 3-5 phrases max
- Toujours terminer par un conseil actionnable

Tu connais l'historique des échanges et tu t'en souviens.
Réponds toujours en français."""

    history = [{"role": m["role"], "content": m["content"]} for m in messages_history]
    history.append({"role": "user", "content": content})

    response = groq_client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "system", "content": system_prompt}, *history],
        max_tokens=1500,
    )
    return response.choices[0].message.content

@app.post("/conversations/")
async def create_conversation(objectif: str = Form(default="general"), title: str = Form(default="Nouvelle conversation")):
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
    file: Optional[UploadFile] = File(default=None),
    user_profile: str = Form(default="")
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

    # Profil depuis Flutter + données sauvegardées en base
    profile_dict = {}
    if user_profile:
        try:
            profile_dict = json.loads(user_profile)
        except:
            pass

    # Enrichir avec les données sauvegardées
    saved_data = get_user_data(db)
    for k, v in saved_data.items():
        if k not in profile_dict or not profile_dict[k]:
            profile_dict[k] = v

    history = db.query(Message).filter(Message.conversation_id == conv_id).order_by(Message.created_at).all()
    history_list = [{"role": m.role, "content": m.content} for m in history]

    ai_response = get_ai_response(history_list, user_text, conv.objectif, video_data, profile_dict)

    full_response = ai_response
    if video_data:
        full_response = build_video_table(video_data) + ai_response
        # Sauvegarder le score squat
        set_user_data(db, "last_squat_score", str(video_data.get('score', '')))
        set_user_data(db, "last_squat_reps", str(video_data.get('reps', '')))
        set_user_data(db, "last_squat_date", datetime.now().strftime("%d/%m/%Y"))

    # Extraire et sauvegarder les nouvelles infos du message
    extracted = extract_user_data_from_message(user_text, ai_response)
    for k, v in extracted.items():
        if v and str(v).strip() and str(v) != "None":
            set_user_data(db, k, str(v))

    user_msg = Message(conversation_id=conv_id, role="user", content=user_text, video_filename=video_filename)
    assistant_msg = Message(conversation_id=conv_id, role="assistant", content=full_response)
    db.add(user_msg)
    db.add(assistant_msg)

    if len(history) == 0:
        conv.title = user_text[:40] + ("..." if len(user_text) > 40 else "")

    conv.updated_at = datetime.now()
    db.commit()
    db.close()

    return {
        "response": full_response,
        "video_data": video_data,
        "video_filename": video_filename,
        "updated_user_data": extracted,
    }

@app.get("/user-data/")
async def get_all_user_data():
    db = DBSession()
    data = get_user_data(db)
    db.close()
    return data

@app.put("/user-data/")
async def update_user_data(data: str = Form(...)):
    db = DBSession()
    try:
            parsed = json.loads(data)
            for k, v in parsed.items():
                if v:
                    set_user_data(db, k, str(v))
            if 'weight' in parsed and parsed['weight']:
                add_weight_history(db, parsed['weight'], datetime.now().strftime("%d/%m"))
    except:
            pass
    db.close()
    return {"message": "updated"}

@app.get("/daily-message/")
async def get_daily_message():
    db = DBSession()
    user_data = get_user_data(db)
    db.close()

    name = user_data.get('name', '')
    weight = user_data.get('weight', '')
    squat = user_data.get('squat_weight', '')
    streak = user_data.get('streak', '')
    goal = user_data.get('goal', '')
    last_score = user_data.get('last_squat_score', '')
    level = user_data.get('level', '')

    profile_text = f"""
Infos sur l'athlète :
- Prénom : {name if name else 'Non renseigné'}
- Poids : {weight if weight else 'Non renseigné'} kg
- Squat : {squat if squat else 'Non renseigné'} kg
- Streak : {streak if streak else 'Non renseigné'} jours
- Objectif : {goal if goal else 'Non renseigné'}
- Niveau : {level if level else 'Non renseigné'}
- Dernier score squat : {last_score if last_score else 'Non renseigné'}/100
"""

    prompt = f"""Tu es un coach sportif IA. Génère UNE SEULE phrase de motivation personnalisée pour cet athlète.

{profile_text}

Règles STRICTES :
- Maximum 12 mots
- Utilise le prénom si disponible
- Fais référence à une de ses stats si disponible
- Tutoie toujours
- 1 emoji maximum
- Pas de guillemets
- Juste la phrase, rien d'autre"""

    try:
        response = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=50,
        )
        message = response.choices[0].message.content.strip()
        return {"message": message}
    except:
        return {"message": "Prêt à battre ton record aujourd'hui ? 🔥"}