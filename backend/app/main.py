from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import engine, get_db, Base
from app import models, schemas
from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta, timezone
import os
from dotenv import load_dotenv
from fastapi.security import OAuth2PasswordBearer
from fastapi.middleware.cors import CORSMiddleware
import random , string

# Carrega variáveis de ambiente do ficheiro .env
load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Cria as tabelas no banco de dados se ainda não existirem
Base.metadata.create_all(bind=engine)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuração para hash de passwords usando bcrypt
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=12)

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# Define um esquema OAuth2 para usar com tokens Bearer
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login/")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except jwt.JWTError:
        raise credentials_exception

    # Carrega o utilizador da base de dados usando o email presente no token JWT
    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        raise credentials_exception
    return user

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

    # validate invite code for clients
    if user.role == "client":
        if not user.invite_code:
            raise HTTPException(status_code=400, detail="Clients need an invite code to register")
        
        invite = db.query(models.InviteCodes).filter(
            models.InviteCodes.code == user.invite_code,
            models.InviteCodes.used == False
        ).first()

        if not invite:
            raise HTTPException(status_code=400, detail="Invalid invite code")
        #nao funciona >>>>
        if invite.expires_at < datetime.now(timezone.utc):
            raise HTTPException(status_code=400, detail="Invite code has expired")
        
        invite.used = True
        db.add(invite)

    hashed_password = pwd_context.hash(user.password)

    new_user = models.User(
        name=user.name,
        email=user.email,
        password=hashed_password,
        role=user.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user

#Teste do token
@app.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user

# Workout Plan Endpoints
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
    if current_user.role == "trainer":
        sessions = db.query(models.TrainingSession).filter(models.TrainingSession.trainer_id == current_user.id).all()
    else:
        sessions = db.query(models.TrainingSession).filter(models.TrainingSession.client_id == current_user.id).all()
    return sessions


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
    if current_user.role == "client":
        progression = db.query(models.UserProgression).filter(
            models.UserProgression.client_id == current_user.id
        ).all()
    else:
        progression = db.query(models.UserProgression).filter(
            models.UserProgression.trainer_id == current_user.id
        ).all()
    return progression



#Criação code de convite para registo de clientes por parte dos treinadores
def generate_code():
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

@app.post("/invite-codes/", response_model=schemas.InviteCodeResponse)
def create_invite_code(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "trainer":
        raise HTTPException(status_code=403, detail="Apenas trainers podem gerar códigos de convite")

    code = generate_code()
    
    new_code = models.InviteCodes(
        code=code,
        trainer_id=current_user.id,
        expires_at=datetime.now(timezone.utc) + timedelta(hours=1)
    )
    
    db.add(new_code)
    db.commit()
    db.refresh(new_code)
    
    return new_code


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
    if current_user.role == "trainer":
        plans = db.query(models.NutriPlan).filter(
            models.NutriPlan.trainer_id == current_user.id
        ).all()
    else:
        plans = db.query(models.NutriPlan).filter(
            models.NutriPlan.client_id == current_user.id
        ).all()
    return plans