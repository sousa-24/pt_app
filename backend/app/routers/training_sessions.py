"""
Endpoints para criar, listar, atualizar e eliminar sessões de treino individuais.
"""
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer
from app.auth import get_current_user
from app.services.notification_services import create_notification

router = APIRouter(prefix="/api/v1", tags=["training_sessions"])


def _validate_session_date(date: datetime):
    now = datetime.now(date.tzinfo) if date.tzinfo else datetime.now()
    if date < now + timedelta(hours=24):
        raise HTTPException(
            status_code=400,
            detail="A sessão de treino deve ser agendada com pelo menos 24 horas de antecedência.",
        )


@router.post("/training_sessions/", response_model=schemas.TrainingSessionResponse)
def create_training_session(
    session: schemas.TrainingSessionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer),
):
    """Cria uma nova sessão de treino individual."""
    _validate_session_date(session.date)

    client = db.query(models.User).filter(
        models.User.id == session.client_id,
        models.User.role == "client",
        models.User.trainer_id == current_user.id,
    ).first()
    if not client:
        raise HTTPException(
            status_code=404,
            detail="Aluno não encontrado para este treinador.",
        )

    new_session = models.TrainingSession(
        client_id=session.client_id,
        trainer_id=current_user.id,
        workout_plan_id=session.workout_plan_id,
        date=session.date,
        notes=session.notes,
    )
    db.add(new_session)
    db.commit()
    db.refresh(new_session)

    create_notification(
        db=db,
        user_id=session.client_id,
        title="Nova Sessão de Treino",
        message=f"O treinador {current_user.name} agendou uma nova sessão de treino para si no dia {session.date.strftime('%Y-%m-%d %H:%M')}.",
        type="training_session",
    )

    return new_session


@router.get("/training_sessions/", response_model=list[schemas.TrainingSessionResponse])
def get_training_sessions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Lista todas as sessões de treino do utilizador atual."""
    if current_user.role == "trainer":
        return db.query(models.TrainingSession).filter(
            models.TrainingSession.trainer_id == current_user.id
        ).all()
    return db.query(models.TrainingSession).filter(
        models.TrainingSession.client_id == current_user.id
    ).all()


@router.put(
    "/training_sessions/{session_id}",
    response_model=schemas.TrainingSessionResponse,
)
def update_training_session(
    session_id: int,
    data: schemas.TrainingSessionUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer),
):
    """Atualiza uma sessão de treino individual."""
    session = db.query(models.TrainingSession).filter(
        models.TrainingSession.id == session_id,
        models.TrainingSession.trainer_id == current_user.id,
    ).first()
    if not session:
        raise HTTPException(status_code=404, detail="Sessão de treino não encontrada.")

    if data.date is not None:
        _validate_session_date(data.date)
        session.date = data.date
    if data.workout_plan_id is not None:
        session.workout_plan_id = data.workout_plan_id if data.workout_plan_id > 0 else None
    if data.notes is not None:
        session.notes = data.notes
    if data.status is not None:
        session.status = data.status

    db.commit()
    db.refresh(session)
    return session


@router.delete("/training_sessions/{session_id}", response_model=schemas.StatusResponse)
def delete_training_session(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer),
):
    """Elimina uma sessão de treino individual."""
    session = db.query(models.TrainingSession).filter(
        models.TrainingSession.id == session_id,
        models.TrainingSession.trainer_id == current_user.id,
    ).first()
    if not session:
        raise HTTPException(status_code=404, detail="Sessão de treino não encontrada.")

    db.query(models.ClientSessionFeedback).filter(
        models.ClientSessionFeedback.session_id == session_id
    ).delete(synchronize_session=False)
    db.query(models.SessionPerformance).filter(
        models.SessionPerformance.session_id == session_id
    ).delete(synchronize_session=False)
    db.delete(session)
    db.commit()
    return {"message": "Sessão de treino eliminada com sucesso"}
