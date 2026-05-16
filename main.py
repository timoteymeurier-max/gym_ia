from fastapi import FastAPI, UploadFile, File, Form, Header
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Text, ForeignKey, Float
from sqlalchemy.pool import NullPool
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
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
engine = create_engine(DATABASE_URL, poolclass=NullPool)
Base = declarative_base()

class Conversation(Base):
    __tablename__ = "conversations"
    id = Column(Integer, primary_key=True)
    device_id = Column(String, default="default")
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
    device_id = Column(String, default="default")
    key = Column(String)
    value = Column(Text)
    updated_at = Column(DateTime, default=datetime.now)


class AIProgram(Base):
    __tablename__ = "ai_programs"
    id = Column(Integer, primary_key=True)
    device_id = Column(String, default="default")
    title = Column(String)
    objective = Column(String)
    content = Column(Text)
    created_at = Column(DateTime, default=datetime.now)

class AINutritionPlan(Base):
    __tablename__ = "ai_nutrition_plans"
    id = Column(Integer, primary_key=True)
    device_id = Column(String, default="default")
    title = Column(String)
    objective = Column(String)
    content = Column(Text)
    created_at = Column(DateTime, default=datetime.now)


class ExercisePerf(Base):
    __tablename__ = "exercise_perfs"
    id = Column(Integer, primary_key=True)
    device_id = Column(String, default="default")
    exercise = Column(String)
    weight = Column(Float, nullable=True)
    reps = Column(Integer, nullable=True)
    sets = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)
    date = Column(String)
    created_at = Column(DateTime, default=datetime.now)

class FoodEntry(Base):
    __tablename__ = "food_entries"
    id = Column(Integer, primary_key=True)
    device_id = Column(String, default="default")
    name = Column(String)
    calories = Column(Float, nullable=True)
    protein = Column(Float, nullable=True)
    carbs = Column(Float, nullable=True)
    fat = Column(Float, nullable=True)
    quantity = Column(String, nullable=True)
    meal_type = Column(String, nullable=True)  # petit_dejeuner, dejeuner, diner, collation
    date = Column(String)
    created_at = Column(DateTime, default=datetime.now)


Base.metadata.create_all(engine)

DBSession = sessionmaker(bind=engine)

# Migration : ajout colonne device_id si elle n'existe pas
from sqlalchemy import text, inspect
inspector = inspect(engine)
cols_user_data = [c['name'] for c in inspector.get_columns('user_data')]
cols_conversations = [c['name'] for c in inspector.get_columns('conversations')]
with engine.connect() as conn:
    if 'device_id' not in cols_user_data:
        conn.execute(text("ALTER TABLE user_data ADD COLUMN device_id VARCHAR DEFAULT 'default'"))
        conn.commit()
    if 'device_id' not in cols_conversations:
        conn.execute(text("ALTER TABLE conversations ADD COLUMN device_id VARCHAR DEFAULT 'default'"))
        conn.commit()
    # Supprimer l'ancienne contrainte unique sur key seul
    try:
        conn.execute(text("ALTER TABLE user_data DROP CONSTRAINT IF EXISTS user_data_key_key"))
        conn.commit()
    except:
        pass

def get_user_data(db, device_id="default"):
    rows = db.query(UserData).filter(UserData.device_id == device_id).all()
    return {r.key: r.value for r in rows}

def set_user_data(db, device_id, key, value):
    row = db.query(UserData).filter(UserData.device_id == device_id, UserData.key == key).first()
    if str(value).strip() == '':
        if row:
            db.delete(row)
            db.commit()
    else:
        if row:
            row.value = str(value)
            row.updated_at = datetime.now()
        else:
            db.add(UserData(device_id=device_id, key=key, value=str(value)))
        db.commit()

def add_weight_history(db, device_id, weight, date):
    row = db.query(UserData).filter(UserData.device_id == device_id, UserData.key == "weight_history").first()
    if row:
        try:
            history = json.loads(row.value)
        except:
            history = []
    else:
        history = []
    history.append({"date": date, "weight": float(weight)})
    history = history[-30:]
    set_user_data(db, device_id, "weight_history", json.dumps(history))

def detect_and_save_program(db, device_id, user_message, ai_response):
    detection_prompt = f"""Analyse cette réponse d'un coach sportif IA.

Réponds UNIQUEMENT avec ce JSON sans aucun texte autour :
{{
  "is_training_program": true ou false,
  "is_nutrition_plan": true ou false,
  "title": "Titre court 3-5 mots",
  "objective": "Objectif 2-3 mots"
}}

Mets true pour is_training_program si la réponse contient :
- Des exercices listés avec séries/reps OU
- Un planning d'entraînement sur plusieurs jours OU
- Une structure de programme (Jour 1, Jour 2... ou Lundi, Mardi...)

Mets true pour is_nutrition_plan si la réponse contient :
- Des repas listés avec calories/macros OU
- Un planning alimentaire sur plusieurs jours OU
- Une liste d'aliments recommandés avec quantités

Réponse à analyser:
{ai_response[:800]}"""

    try:
        detection = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": detection_prompt}],
            max_tokens=4000,
        )
        text = detection.choices[0].message.content.strip()
        text = text.replace("```json", "").replace("```", "").strip()
        data = json.loads(text)

        if data.get("is_training_program"):
            db.add(AIProgram(
                device_id=device_id,
                title=data.get("title", "Programme IA"),
                objective=data.get("objective", "Général"),
                content=json.dumps({"raw": ai_response}),
            ))
            db.commit()
            print(f"Programme entraînement sauvegardé: {data.get('title')}")

        if data.get("is_nutrition_plan"):
            db.add(AINutritionPlan(
                device_id=device_id,
                title=data.get("title", "Plan nutrition IA"),
                objective=data.get("objective", "Général"),
                content=json.dumps({"raw": ai_response}),
            ))
            db.commit()
            print(f"Plan nutrition sauvegardé: {data.get('title')}")

    except Exception as e:
        import traceback
        print(f"Erreur détection programme: {e}")
        traceback.print_exc()

def extract_user_data_from_message(message, ai_response):
    prompt = f"""Analyse ce message et la réponse du coach.
Extrait UNIQUEMENT les infos factuelles sur l'utilisateur.
Message: {message}
Réponse: {ai_response}
Retourne UNIQUEMENT un JSON valide avec les clés pertinentes parmi :
name, age, weight, height, goal, level, squat_weight, bench_weight, deadlift_weight, sessions_per_week, streak, calories
Si aucune info retourne {{}}.
Ne retourne QUE le JSON."""
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
    a, b, c = np.array(a), np.array(b), np.array(c)
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
    angles_knee_left, angles_knee_right = [], []
    angles_hip_left, angles_hip_right = [], []
    angles_back = []
    knee_x_left, knee_x_right = [], []

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
    rep_depths, descent_speeds, time_in_hole = [], [], []
    descent_start = bottom_start = None

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
            descent_start = bottom_start = None

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
        "reps": reps, "score": score,
        "knee_min_left": min_knee_left, "knee_min_right": min_knee_right,
        "hip_avg_left": avg_hip_left, "hip_avg_right": avg_hip_right,
        "back_avg": avg_back, "symmetry": symmetry,
        "knee_stability_left": stab_left, "knee_stability_right": stab_right,
        "max_depth": max_depth, "avg_descent_time": avg_descent_time, "avg_time_in_hole": avg_time_in_hole,
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
        f"| Métrique | Gauche | Droite |\n|----------|--------|--------|\n"
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
[Analyse vidéo]
Score : {video_data.get('score')}/100 · Reps : {video_data['reps']}
Genou G/D : {video_data['knee_min_left']}° / {video_data['knee_min_right']}° ({video_data.get('depth_interpretation')})
Dos : {video_data['back_avg']}° ({video_data.get('back_interpretation')})
Symétrie : {video_data['symmetry']}° ({video_data.get('symmetry_interpretation')})
Vitesse : {video_data.get('avg_descent_time', 'N/A')}s ({video_data.get('speed_interpretation')})
Temps en bas : {video_data.get('avg_time_in_hole', 'N/A')}s
"""
    profile_text = ""
    if user_profile:
        profile_text = f"""
Profil :
- Prénom : {user_profile.get('name', 'Non renseigné')}
- Âge : {user_profile.get('age', 'Non renseigné')} ans
- Poids : {user_profile.get('weight', 'Non renseigné')} kg
- Taille : {user_profile.get('height', 'Non renseigné')} cm
- Niveau : {user_profile.get('level', 'Non renseigné')}
- Objectif : {user_profile.get('goal', 'Non renseigné')}
- Squat : {user_profile.get('squat_weight', 'Non renseigné')} kg
- Bench : {user_profile.get('bench_weight', 'Non renseigné')} kg
- Deadlift : {user_profile.get('deadlift_weight', 'Non renseigné')} kg
"""
    system_prompt = f"""Tu es un coach sportif IA nouvelle génération, expert en musculation et nutrition.
{profile_text}
STYLE : Direct, motivant, tutoie toujours, emojis modérés (max 3).

PROGRAMME D'ENTRAÎNEMENT — quand on te demande un programme, donne TOUJOURS :
- Minimum 4-6 exercices par séance
- Les séries, répétitions et temps de repos pour chaque exercice
- Un programme sur plusieurs jours (ex: PPL = 6 jours, Full Body = 3 jours)
- Structure claire : Jour 1 - Push, Jour 2 - Pull, etc.
- Adapté au niveau et objectif de l'utilisateur
- Pas de limite de mots pour les programmes

PLAN NUTRITIONNEL — quand on te demande un plan nutrition, donne TOUJOURS :
- Les repas de la journée (petit déjeuner, déjeuner, dîner, collations)
- Les aliments avec quantités précises en grammes
- Les calories et macros (protéines, glucides, lipides) par repas
- Un plan sur plusieurs jours
- Adapté à l'objectif (prise de masse, sèche, etc.)
- Pas de limite de mots pour les plans

ANALYSE VIDÉO — structure obligatoire :
**Ce que tu fais bien ✅** (1-2 points)
**Ce qu'on améliore 🎯** (1-2 points avec correction)
**Conseil prochaine séance 💡** (1 conseil actionnable)
**Charge** : Augmenter/Maintenir/Réduire + pourquoi

QUESTIONS SIMPLES : Réponse directe 3-5 phrases, terminer par conseil actionnable.
Réponds toujours en français."""

    history = [{"role": m["role"], "content": m["content"]} for m in messages_history]
    history.append({"role": "user", "content": content})
    response = groq_client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "system", "content": system_prompt}, *history],
        max_tokens=8000,
    )
    return response.choices[0].message.content

@app.post("/conversations/")
async def create_conversation(
    objectif: str = Form(default="general"),
    title: str = Form(default="Nouvelle conversation"),
    x_device_id: str = Header(default="default")
):
    db = DBSession()
    conv = Conversation(title=title, objectif=objectif, device_id=x_device_id)
    db.add(conv)
    db.commit()
    db.refresh(conv)
    result = {"id": conv.id, "title": conv.title, "objectif": conv.objectif, "created_at": conv.created_at.strftime("%d/%m/%Y %H:%M")}
    db.close()
    return result

@app.get("/conversations/")
async def get_conversations(x_device_id: str = Header(default="default")):
    db = DBSession()
    convs = db.query(Conversation).filter(Conversation.device_id == x_device_id).order_by(Conversation.updated_at.desc()).all()
    result = [{"id": c.id, "title": c.title, "objectif": c.objectif, "updated_at": c.updated_at.strftime("%d/%m/%Y %H:%M")} for c in convs]
    db.close()
    return result

@app.delete("/conversations/{conv_id}")
async def delete_conversation(conv_id: int, x_device_id: str = Header(default="default")):
    db = DBSession()
    conv = db.query(Conversation).filter(Conversation.id == conv_id, Conversation.device_id == x_device_id).first()
    if conv:
        db.delete(conv)
        db.commit()
    db.close()
    return {"message": "deleted"}

@app.get("/conversations/{conv_id}/messages")
async def get_messages(conv_id: int, x_device_id: str = Header(default="default")):
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
    user_profile: str = Form(default=""),
    x_device_id: str = Header(default="default")
):
    db = DBSession()
    conv = db.query(Conversation).filter(Conversation.id == conv_id, Conversation.device_id == x_device_id).first()
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

    profile_dict = {}
    if user_profile:
        try:
            profile_dict = json.loads(user_profile)
        except:
            pass

    saved_data = get_user_data(db, x_device_id)
    for k, v in saved_data.items():
        if k not in profile_dict or not profile_dict[k]:
            profile_dict[k] = v

    history = db.query(Message).filter(Message.conversation_id == conv_id).order_by(Message.created_at).all()
    history_list = [{"role": m.role, "content": m.content} for m in history]

    ai_response = get_ai_response(history_list, user_text, conv.objectif, video_data, profile_dict)

    full_response = ai_response
    if video_data:
        full_response = build_video_table(video_data) + ai_response
        set_user_data(db, x_device_id, "last_squat_score", str(video_data.get('score', '')))
        set_user_data(db, x_device_id, "last_squat_reps", str(video_data.get('reps', '')))
        set_user_data(db, x_device_id, "last_squat_date", datetime.now().strftime("%d/%m/%Y"))

    extracted = extract_user_data_from_message(user_text, ai_response)
    for k, v in extracted.items():
        if v and str(v).strip() and str(v) != "None":
            set_user_data(db, x_device_id, k, str(v))

    # Détecter les perfs mentionnées dans le chat
    perf_prompt = f"""Analyse ce message d'un sportif.
Extrait UNIQUEMENT les performances mentionnées avec un exercice ET une charge ou des répétitions.

Message: {user_text}

Retourne UNIQUEMENT un JSON valide comme ceci :
[
  {{"exercise": "Squat", "weight": 100, "reps": 5, "sets": 4}},
  {{"exercise": "Développé couché", "weight": 80, "reps": 8, "sets": 3}}
]

Si aucune perf mentionnée retourne [].
Ne retourne QUE le JSON."""
    try:
        perf_resp = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": perf_prompt}],
            max_tokens=300,
        )
        perf_text = perf_resp.choices[0].message.content.strip()
        perf_text = perf_text.replace("```json", "").replace("```", "").strip()
        perfs = json.loads(perf_text)
        for p in perfs:
            if p.get("exercise") and (p.get("weight") or p.get("reps")):
                db.add(ExercisePerf(
                    device_id=x_device_id,
                    exercise=p["exercise"],
                    weight=p.get("weight"),
                    reps=p.get("reps"),
                    sets=p.get("sets"),
                    date=datetime.now().strftime("%d/%m/%Y"),
                ))
                db.commit()
                print(f"Perf sauvegardée: {p['exercise']} {p.get('weight')}kg")
    except Exception as e:
        print(f"Erreur détection perfs: {e}")

    user_msg = Message(conversation_id=conv_id, role="user", content=user_text, video_filename=video_filename)
    assistant_msg = Message(conversation_id=conv_id, role="assistant", content=full_response)
    db.add(user_msg)
    db.add(assistant_msg)

    if len(history) == 0:
        conv.title = user_text[:40] + ("..." if len(user_text) > 40 else "")

    detect_and_save_program(db, x_device_id, user_text, ai_response)
    conv.updated_at = datetime.now()
    db.commit()
    db.close()

    return {"response": full_response, "video_data": video_data, "video_filename": video_filename, "updated_user_data": extracted}


@app.get("/migrate/")
async def migrate():
    from sqlalchemy import text
    with engine.connect() as conn:
        conn.execute(text("ALTER TABLE user_data ADD COLUMN IF NOT EXISTS device_id VARCHAR DEFAULT 'default'"))
        conn.execute(text("ALTER TABLE conversations ADD COLUMN IF NOT EXISTS device_id VARCHAR DEFAULT 'default'"))
        conn.commit()
    return {"message": "Migration OK"}


@app.get("/user-data/")
async def get_all_user_data(x_device_id: str = Header(default="default")):
    db = DBSession()
    data = get_user_data(db, x_device_id)
    db.close()
    return data

@app.put("/user-data/")
async def update_user_data(data: str = Form(...), x_device_id: str = Header(default="default")):
    db = DBSession()
    try:
        parsed = json.loads(data)
        for k, v in parsed.items():
            set_user_data(db, x_device_id, k, str(v))
        if 'weight' in parsed and parsed['weight']:
            add_weight_history(db, x_device_id, parsed['weight'], datetime.now().strftime("%d/%m"))
    except Exception as e:
        print(f"Erreur update_user_data: {e}")
    db.close()
    return {"message": "updated"}

@app.get("/ai-programs/")
async def get_ai_programs(x_device_id: str = Header(default="default")):
    db = DBSession()
    programs = db.query(AIProgram).filter(AIProgram.device_id == x_device_id).order_by(AIProgram.created_at.desc()).all()
    result = [{"id": p.id, "title": p.title, "objective": p.objective, "content": p.content, "created_at": p.created_at.strftime("%d/%m/%Y")} for p in programs]
    db.close()
    return result

@app.delete("/ai-programs/{program_id}")
async def delete_ai_program(program_id: int, x_device_id: str = Header(default="default")):
    db = DBSession()
    program = db.query(AIProgram).filter(AIProgram.id == program_id, AIProgram.device_id == x_device_id).first()
    if program:
        db.delete(program)
        db.commit()
    db.close()
    return {"message": "deleted"}

@app.get("/ai-nutrition-plans/")
async def get_ai_nutrition_plans(x_device_id: str = Header(default="default")):
    db = DBSession()
    plans = db.query(AINutritionPlan).filter(AINutritionPlan.device_id == x_device_id).order_by(AINutritionPlan.created_at.desc()).all()
    result = [{"id": p.id, "title": p.title, "objective": p.objective, "content": p.content, "created_at": p.created_at.strftime("%d/%m/%Y")} for p in plans]
    db.close()
    return result

@app.delete("/ai-nutrition-plans/{plan_id}")
async def delete_ai_nutrition_plan(plan_id: int, x_device_id: str = Header(default="default")):
    db = DBSession()
    plan = db.query(AINutritionPlan).filter(AINutritionPlan.id == plan_id, AINutritionPlan.device_id == x_device_id).first()
    if plan:
        db.delete(plan)
        db.commit()
    db.close()
    return {"message": "deleted"}

@app.get("/exercise-perfs/")
async def get_exercise_perfs(exercise: str = "", x_device_id: str = Header(default="default")):
    db = DBSession()
    query = db.query(ExercisePerf).filter(ExercisePerf.device_id == x_device_id)
    if exercise:
        query = query.filter(ExercisePerf.exercise == exercise)
    perfs = query.order_by(ExercisePerf.date.desc()).all()
    result = [{"id": p.id, "exercise": p.exercise, "weight": p.weight, "reps": p.reps, "sets": p.sets, "notes": p.notes, "date": p.date} for p in perfs]
    db.close()
    return result

@app.post("/exercise-perfs/")
async def add_exercise_perf(
    exercise: str = Form(...),
    weight: float = Form(default=0),
    reps: int = Form(default=0),
    sets: int = Form(default=0),
    notes: str = Form(default=""),
    date: str = Form(default=""),
    x_device_id: str = Header(default="default")
):
    db = DBSession()
    perf = ExercisePerf(
        device_id=x_device_id,
        exercise=exercise,
        weight=weight if weight > 0 else None,
        reps=reps if reps > 0 else None,
        sets=sets if sets > 0 else None,
        notes=notes if notes else None,
        date=date if date else datetime.now().strftime("%d/%m/%Y"),
    )
    db.add(perf)
    db.commit()
    db.refresh(perf)
    result = {"id": perf.id, "exercise": perf.exercise, "weight": perf.weight, "reps": perf.reps, "sets": perf.sets, "notes": perf.notes, "date": perf.date}
    db.close()
    return result

@app.delete("/exercise-perfs/{perf_id}")
async def delete_exercise_perf(perf_id: int, x_device_id: str = Header(default="default")):
    db = DBSession()
    perf = db.query(ExercisePerf).filter(ExercisePerf.id == perf_id, ExercisePerf.device_id == x_device_id).first()
    if perf:
        db.delete(perf)
        db.commit()
    db.close()
    return {"message": "deleted"}


@app.get("/food-entries/")
async def get_food_entries(date: str = "", x_device_id: str = Header(default="default")):
    db = DBSession()
    query = db.query(FoodEntry).filter(FoodEntry.device_id == x_device_id)
    if date:
        query = query.filter(FoodEntry.date == date)
    entries = query.order_by(FoodEntry.created_at.desc()).all()
    result = [{"id": e.id, "name": e.name, "calories": e.calories, "protein": e.protein, "carbs": e.carbs, "fat": e.fat, "quantity": e.quantity, "meal_type": e.meal_type, "date": e.date} for e in entries]
    db.close()
    return result

@app.post("/food-entries/")
async def add_food_entry(
    name: str = Form(...),
    calories: float = Form(default=0),
    protein: float = Form(default=0),
    carbs: float = Form(default=0),
    fat: float = Form(default=0),
    quantity: str = Form(default=""),
    meal_type: str = Form(default="dejeuner"),
    date: str = Form(default=""),
    x_device_id: str = Header(default="default")
):
    db = DBSession()
    entry = FoodEntry(
        device_id=x_device_id,
        name=name,
        calories=calories if calories > 0 else None,
        protein=protein if protein > 0 else None,
        carbs=carbs if carbs > 0 else None,
        fat=fat if fat > 0 else None,
        quantity=quantity if quantity else None,
        meal_type=meal_type,
        date=date if date else datetime.now().strftime("%d/%m/%Y"),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    result = {"id": entry.id, "name": entry.name, "calories": entry.calories, "protein": entry.protein, "carbs": entry.carbs, "fat": entry.fat, "quantity": entry.quantity, "meal_type": entry.meal_type, "date": entry.date}
    db.close()
    return result

@app.delete("/food-entries/{entry_id}")
async def delete_food_entry(entry_id: int, x_device_id: str = Header(default="default")):
    db = DBSession()
    entry = db.query(FoodEntry).filter(FoodEntry.id == entry_id, FoodEntry.device_id == x_device_id).first()
    if entry:
        db.delete(entry)
        db.commit()
    db.close()
    return {"message": "deleted"}

@app.post("/analyze-food-photo/")
async def analyze_food_photo(
    file: UploadFile = File(...),
    x_device_id: str = Header(default="default")
):
    try:
        import base64
        contents = await file.read()
        b64 = base64.b64encode(contents).decode()
        
        prompt = f"""Analyse cette photo de plat et estime les valeurs nutritionnelles.
Réponds UNIQUEMENT avec ce JSON :
{{
  "name": "Nom du plat",
  "calories": 500,
  "protein": 30,
  "carbs": 45,
  "fat": 15,
  "quantity": "1 portion estimée",
  "ingredients": ["ingrédient 1", "ingrédient 2"]
}}
Donne des estimations réalistes."""

        response = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=300,
        )
        text = response.choices[0].message.content.strip()
        text = text.replace("```json", "").replace("```", "").strip()
        data = json.loads(text)
        return data
    except Exception as e:
        print(f"Erreur analyse photo: {e}")
        return {"name": "Plat analysé", "calories": 400, "protein": 25, "carbs": 40, "fat": 12, "quantity": "1 portion", "ingredients": []}
    

@app.get("/daily-message/")
async def get_daily_message(x_device_id: str = Header(default="default")):
    db = DBSession()
    user_data = get_user_data(db, x_device_id)
    db.close()

    name = user_data.get('name', '')
    weight = user_data.get('weight', '')
    squat = user_data.get('squat_weight', '')
    streak = user_data.get('streak', '')
    goal = user_data.get('goal', '')
    last_score = user_data.get('last_squat_score', '')
    level = user_data.get('level', '')

    has_profile = any([name, weight, squat, goal])

    if has_profile:
        prompt = f"""Tu es un coach sportif IA moderne style TikTok fitness. Génère UNE phrase d'accroche percutante pour cet athlète.

Profil :
- Prénom : {name or 'Non renseigné'}
- Poids : {weight or 'Non renseigné'} kg
- Squat : {squat or 'Non renseigné'} kg
- Streak : {streak or 'Non renseigné'} jours
- Objectif : {goal or 'Non renseigné'}
- Niveau : {level or 'Non renseigné'}
- Dernier score : {last_score or 'Non renseigné'}/100

Varie le style : question directe, défi, référence aux stats, motivation raw, humour sportif.
Règles : max 15 mots, utilise le prénom si disponible, tutoie, 1 emoji max, pas de guillemets, juste la phrase."""
    else:
        prompt = """Tu es un coach sportif IA moderne style TikTok fitness. Génère UNE phrase de motivation sportive générale.
Varie le style : question, défi, motivation raw, humour sportif.
Règles : max 15 mots, tutoie, 1 emoji max, pas de guillemets, juste la phrase."""

    try:
        response = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=50,
        )
        message = response.choices[0].message.content.strip()
        return {"message": message}
    except Exception as e:
        print(f"Erreur Groq daily-message: {e}")
        return {"message": "Erreur serveur"}