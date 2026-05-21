from fastapi import FastAPI, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from app.database import engine, get_db, Base
from app import models, schemas
import os
from fastapi.middleware.cors import CORSMiddleware
import random, string
from datetime import datetime, timedelta, timezone
from app.websocket_manager import manager
from app.auth import pwd_context, create_access_token, get_current_user, get_user_from_token

# Cria as tabelas no banco de dados se ainda não existirem
Base.metadata.create_all(bind=engine)

# Cria a instância FastAPI e configura CORS para permitir chamadas do frontend
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Endpoint de login: valida as credenciais e devolve um token JWT válido
@app.post("/login/", response_model=schemas.Token)
def login(user: schemas.UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if not db_user or not pwd_context.verify(user.password, db_user.password):
        raise HTTPException(status_code=401, detail="Credenciais inválidas")

    access_token = create_access_token(data={"sub": db_user.email, "role": db_user.role})
    return {"access_token": access_token, "token_type": "bearer","role": db_user.role}

# Endpoint de registo: cria um novo utilizador e guarda a password com hash segura
@app.post("/registar/", response_model=schemas.UserResponse)
def registar(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email já registrado")

    # Se o registo for para um cliente, valida o código de convite fornecido
    if user.role == "client":
        if not user.invite_code:
            raise HTTPException(status_code=400, detail="Clients need an invite code to register")

        invite = db.query(models.InviteCodes).filter(
            models.InviteCodes.code == user.invite_code,
            models.InviteCodes.used == False
        ).first()

        if not invite:
            raise HTTPException(status_code=400, detail="Invalid invite code")

        # Verifica se o código de convite ainda é válido
        if invite.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
            raise HTTPException(status_code=400, detail="Invite code has expired")

        invite.used = True
        db.add(invite)

    hashed_password = pwd_context.hash(user.password)

    new_user = models.User(
        name=user.name,
        email=user.email,
        password=hashed_password,
        role=user.role,
        trainer_id=None if user.role == "trainer" else invite.trainer_id     
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user

# Endpoint protegido para obter os dados do utilizador autenticado
@app.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user

# Endpoints de planos de treino: criação e listagem de planos para treinador ou cliente
@app.post("/workout_plans/", response_model=schemas.WorkoutPlanResponse)
def create_workout_plan(plan: schemas.WorkoutPlanCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "trainer":
        raise HTTPException(status_code=403, detail="Apenas treinadores podem criar planos de treino")

    new_plan = models.WorkoutPlan(
        title=plan.title,
        trainer_id=current_user.id,
        client_id=plan.client_id
    )
    db.add(new_plan)
    db.commit()
    db.refresh(new_plan)

    for exercise in plan.exercises:
        new_exercise = models.Exercise(
            workout_plan_id=new_plan.id,
            name=exercise.name,
            sets=exercise.sets,
            reps=exercise.reps,
            rest_time=exercise.rest_time,
            notes=exercise.notes
        )
        db.add(new_exercise)

    db.commit()
    db.refresh(new_plan)

    return new_plan

@app.get("/workout_plans/", response_model=list[schemas.WorkoutPlanResponse])
def get_workout_plans(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role == "trainer":
        plans = db.query(models.WorkoutPlan).filter(models.WorkoutPlan.trainer_id == current_user.id).all()
    else:
        plans = db.query(models.WorkoutPlan).filter(models.WorkoutPlan.client_id == current_user.id).all()
    return plans


# Endpoints de sessões de treino: criação e listagem de sessões para treinador ou cliente
@app.post("/training_sessions/", response_model=schemas.TrainingSessionResponse)
def create_training_session(session: schemas.TrainingSessionCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "trainer":
        raise HTTPException(status_code=403, detail="Apenas treinadores podem criar sessões de treino")

    new_session = models.TrainingSession(
        client_id=session.client_id,
        trainer_id=current_user.id,
        workout_plan_id=session.workout_plan_id,
        date=session.date,
        notes=session.notes
    )
    db.add(new_session)
    db.commit()
    db.refresh(new_session)
    return new_session

@app.get("/training_sessions/", response_model=list[schemas.TrainingSessionResponse])
def get_training_sessions(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # Retorna sessões de treino para o treinador ou para o cliente autenticado
    if current_user.role == "trainer":
        sessions = db.query(models.TrainingSession).filter(models.TrainingSession.trainer_id == current_user.id).all()
    else:
        sessions = db.query(models.TrainingSession).filter(models.TrainingSession.client_id == current_user.id).all()
    return sessions


# Endpoints de progressão: criação e visualização de dados de progresso do utilizador
@app.post("/progression/", response_model=schemas.UserProgressionResponse)
def create_progression(
    progression: schemas.UserProgressionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    new_progression = models.UserProgression(
        client_id=progression.client_id,
        trainer_id=current_user.id,
        date=progression.date,
        weight=progression.weight,
        body_fat_percentage=progression.body_fat_percentage,
        notes=progression.notes
    )
    db.add(new_progression)
    db.commit()
    db.refresh(new_progression)
    return new_progression

@app.get("/progression/", response_model=list[schemas.UserProgressionResponse])
def get_progression(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # Retorna a progressão do cliente ou todos os clientes atribuídos a um treinador
    if current_user.role == "client":
        progression = db.query(models.UserProgression).filter(
            models.UserProgression.client_id == current_user.id
        ).all()
    else:
        progression = db.query(models.UserProgression).filter(
            models.UserProgression.trainer_id == current_user.id
        ).all()
    return progression

#Permite que um treinador veja a progressão de um cliente específico, filtrando por cliente_id e trainer_id para garantir que o treinador só vê os dados dos seus clientes atribuídos.
@app.get("/progression/{client_id}", response_model=list[schemas.UserProgressionResponse])
def get_client_progression(
    client_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "trainer":
        raise HTTPException(status_code=403, detail="Only trainers can view client progression")
    
    progression = db.query(models.UserProgression).filter(
        models.UserProgression.client_id == client_id,
        models.UserProgression.trainer_id == current_user.id
    ).order_by(models.UserProgression.date).all()
    
    return progression

# Gera um código de convite aleatório para permitir registos de clientes
# Apenas treinadores podem criar códigos de convite e partilhá-los com clientes
def generate_code():
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

@app.post("/invite-codes/", response_model=schemas.InviteCodeResponse)
def create_invite_code(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "trainer":
        raise HTTPException(status_code=403, detail="Apenas trainers podem gerar códigos de convite")

    # Ensure generated code is unique (retry a few times to avoid DB unique constraint errors)
    for _ in range(5):
        code = generate_code()
        if not db.query(models.InviteCodes).filter(models.InviteCodes.code == code).first():
            break
    else:
        raise HTTPException(status_code=500, detail="Unable to generate unique invite code")

    new_code = models.InviteCodes(
        code=code,
        trainer_id=current_user.id,
        expires_at=datetime.now(timezone.utc) + timedelta(hours=1)
    )
    
    db.add(new_code)
    db.commit()
    db.refresh(new_code)
    
    return new_code


# Endpoints de planos nutricionais: criação e listagem para treinadores e clientes
@app.post("/nutri_plans/", response_model=schemas.NutriPlanResponse)
def create_nutri_plan(
    plan: schemas.NutriPlanCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "trainer":
        raise HTTPException(status_code=403, detail="Only trainers can create nutrition plans")

    new_plan = models.NutriPlan(
        title=plan.title,
        trainer_id=current_user.id,
        client_id=plan.client_id
    )
    db.add(new_plan)
    db.commit()
    db.refresh(new_plan)

    for meal_data in plan.meals:
        new_meal = models.Meal(
            nutri_plan_id=new_plan.id,
            name=meal_data.name
        )
        db.add(new_meal)
        db.commit()
        db.refresh(new_meal)

        for food_data in meal_data.food_items:
            new_food = models.FoodItem(
                meal_id=new_meal.id,
                **food_data.model_dump()
            )
            db.add(new_food)

    db.commit()
    db.refresh(new_plan)
    return new_plan

@app.get("/nutri_plans/", response_model=list[schemas.NutriPlanResponse])
def get_nutri_plans(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    # Lista planos nutricionais do treinador ou do cliente autenticado
    if current_user.role == "trainer":
        plans = db.query(models.NutriPlan).filter(
            models.NutriPlan.trainer_id == current_user.id
        ).all()
    else:
        plans = db.query(models.NutriPlan).filter(
            models.NutriPlan.client_id == current_user.id
        ).all()
    return plans


@app.websocket("/ws/{user_id}")
@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int):
    db = next(get_db())
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=1008)
        return

    try:
        auth_user = get_user_from_token(token, db)
    except HTTPException:
        await websocket.close(code=1008)
        return

    if auth_user.id != user_id:
        await websocket.close(code=1008)
        return

    await manager.connect(websocket, user_id)

    try:
        while True:
            try:
                data = await websocket.receive_json()
            except Exception:
                await websocket.send_json({"type": "error", "detail": "Invalid JSON payload"})
                continue

            receiver_id = data.get("receiver_id")
            content = data.get("content")
            if receiver_id is None or content is None:
                await websocket.send_json({"type": "error", "detail": "receiver_id and content are required"})
                continue

            try:
                receiver_id = int(receiver_id)
            except (TypeError, ValueError):
                await websocket.send_json({"type": "error", "detail": "receiver_id must be an integer"})
                continue

            new_message = models.Message(
                sender_id=auth_user.id,
                receiver_id=receiver_id,
                content=content,
            )
            db.add(new_message)
            db.commit()
            db.refresh(new_message)

            payload = {
                "type": "message",
                "id": new_message.id,
                "sender_id": auth_user.id,
                "receiver_id": receiver_id,
                "content": new_message.content,
                "created_at": new_message.created_at.isoformat(),
            }

            await manager.send_message(payload, receiver_id)
            await websocket.send_json({"type": "sent", "message": payload})

    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
        await manager.broadcast({"type": "user_left", "user_id": user_id})
    finally:
        db.close()


@app.get("/messages/{other_user_id}", response_model=list[schemas.MessageResponse])
def get_messages(
    other_user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    messages = db.query(models.Message).filter(
        ((models.Message.sender_id == current_user.id) & (models.Message.receiver_id == other_user_id)) |
        ((models.Message.sender_id == other_user_id) & (models.Message.receiver_id == current_user.id))
    ).order_by(models.Message.created_at).all()
    return messages

#endpoint para receber lista de "contactos" (trainer ver os clientes todos/ clientes veem o trainer)
@app.get("/my-contacts/", response_model=list[schemas.UserResponse])
def get_contacts(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role == "trainer":
        clients = db.query(models.User).filter(
            models.User.trainer_id == current_user.id
        ).all()
        return clients
    else:
        trainer = db.query(models.User).filter(
            models.User.id == current_user.trainer_id
        ).first()
        return [trainer] if trainer else []