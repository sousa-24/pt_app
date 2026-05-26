"""
Authentication endpoints: login, register, and user profile.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone, timedelta
from app.database import get_db
from app import models, schemas
from app.auth import pwd_context, create_access_token, get_current_user
from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter(prefix="/api/v1", tags=["auth"])


@router.post("/login/", response_model=schemas.Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """Login endpoint: validates credentials and returns JWT token."""
    db_user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not db_user or not pwd_context.verify(form_data.password, db_user.password):
        raise HTTPException(status_code=401, detail="Credenciais inválidas")

    access_token = create_access_token(data={"sub": db_user.email, "role": db_user.role})
    return {"access_token": access_token, "token_type": "bearer", "role": db_user.role}

@router.post("/registar/", response_model=schemas.UserResponse)
def registar(user: schemas.UserCreate, db: Session = Depends(get_db)):
    """Register endpoint: creates a new user with secure password hashing."""
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email já registrado")

    trainer_id = None
    
    # If registering as client, validate invite code
    if user.role == "client":
        if not user.invite_code:
            raise HTTPException(status_code=400, detail="Clients need an invite code to register")

        invite = db.query(models.InviteCodes).filter(
            models.InviteCodes.code == user.invite_code,
            models.InviteCodes.used == False
        ).first()

        if not invite:
            raise HTTPException(status_code=400, detail="Invalid invite code")

        # Check if invite code is still valid
        if invite.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
            raise HTTPException(status_code=400, detail="Invite code has expired")

        trainer_id = invite.trainer_id
        invite.used = True
        db.add(invite)

    hashed_password = pwd_context.hash(user.password)

    new_user = models.User(
        name=user.name,
        email=user.email,
        password=hashed_password,
        role=user.role,
        trainer_id=trainer_id
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user


@router.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(get_current_user)):
    """Get current authenticated user's profile."""
    return current_user

@router.post("/me", response_model=schemas.UserResponse)
def update_me(updated_user: schemas.UserCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if updated_user.name:
        current_user.name = updated_user.name
    if updated_user.email:
        existing_user = db.query(models.User).filter(models.User.email == updated_user.email).first()
        if existing_user and existing_user.id != current_user.id:
            raise HTTPException(status_code=400, detail="Email já em uso")
        current_user.email = updated_user.email
    if updated_user.password:
        current_user.password = pwd_context.hash(updated_user.password)
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user