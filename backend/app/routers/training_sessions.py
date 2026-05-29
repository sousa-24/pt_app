"""
Endpoints para criar e listar sessões de treino.
"""
from datetime import datetime, timedelta

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
    """Cria uma nova sessão de treino."""
    now = datetime.now(session.date.tzinfo) if session.date.tzinfo else datetime.now()
    earliest_allowed_date = now + timedelta(hours=24)

    if session.date < now:
        raise HTTPException(
            status_code=400,
            detail="A sessão de treino não pode ser agendada para uma data/hora passada."
        )

    if session.date < earliest_allowed_date:
        raise HTTPException(
            status_code=400,
            detail="A sessão de treino deve ser agendada com pelo menos 24 horas de antecedência."
        )

    client = db.query(models.User).filter(
        models.User.id == session.client_id,
        models.User.role == "client",
        models.User.trainer_id == current_user.id
    ).first()
    if not client:
        raise HTTPException(
            status_code=404,
            detail="Aluno não encontrado para este treinador."
        )

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
    """Lista todas as sessões de treino do utilizador atual."""
    sessions = get_user_items(db, models.TrainingSession, current_user)
    return sessions
