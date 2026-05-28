"""
Training sessions endpoints: create and list training sessions.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer, get_user_items
from app.auth import get_current_user
from app.services.notification_services import create_notification

router = APIRouter(prefix="/api/v1", tags=["training_sessions"])


@router.post("/training_sessions/", response_model=schemas.TrainingSessionResponse)
def create_training_session(
    session: schemas.TrainingSessionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Create a new training session."""
    new_session = models.TrainingSession(
        client_id=session.client_id,
        trainer_id=current_user.id,
        workout_plan_id=session.workout_plan_id,
        date=session.date,
        notes=session.notes
    )
    db.add(new_session)
    db.commit()
    create_notification(
        db=db,
        user_id=session.client_id,
        title="Nova Sessão de Treino",
        message=f"O treinador {current_user.name} agendou uma nova sessão de treino para si no dia {session.date.strftime('%Y-%m-%d %H:%M')}.",
        type="training_session"
    )
    db.refresh(new_session)
    return new_session


@router.get("/training_sessions/", response_model=list[schemas.TrainingSessionResponse])
def get_training_sessions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get all training sessions for the current user."""
    sessions = get_user_items(db, models.TrainingSession, current_user)
    return sessions
