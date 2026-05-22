"""
Session feedback endpoints: client feedback and trainer performance evaluation.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer, require_client
from app.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["session_feedback"])


@router.post("/session-feedback/", response_model=schemas.ClientSessionFeedbackResponse)
def create_session_feedback(
    feedback: schemas.ClientSessionFeedbackCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_client)
):
    """Client provides feedback about a training session."""
    session = db.query(models.TrainingSession).filter(
        models.TrainingSession.id == feedback.session_id,
        models.TrainingSession.client_id == current_user.id
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Training session not found")

    new_feedback = models.ClientSessionFeedback(
        session_id=feedback.session_id,
        client_id=current_user.id,
        trainer_id=session.trainer_id,
        rating=feedback.rating,
        notes=feedback.notes
    )
    db.add(new_feedback)
    db.commit()
    db.refresh(new_feedback)
    return new_feedback


@router.post("/session-performance/", response_model=schemas.SessionPerformanceResponse)
def create_session_performance(
    performance: schemas.SessionPerformanceCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Trainer evaluates client's performance during a training session."""
    session = db.query(models.TrainingSession).filter(
        models.TrainingSession.id == performance.session_id,
        models.TrainingSession.trainer_id == current_user.id
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Training session not found")

    new_performance = models.SessionPerformance(
        session_id=performance.session_id,
        client_id=performance.client_id,
        trainer_id=current_user.id,
        performance_rating=performance.performance_rating,
        notes=performance.notes
    )
    db.add(new_performance)
    db.commit()
    db.refresh(new_performance)
    return new_performance


@router.get("/session-feedback/{session_id}", response_model=list[schemas.ClientSessionFeedbackResponse])
def get_session_feedback(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Trainer retrieves client feedback for a specific session."""
    session = db.query(models.TrainingSession).filter(
        models.TrainingSession.id == session_id,
        models.TrainingSession.trainer_id == current_user.id
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Training session not found")

    feedback = db.query(models.ClientSessionFeedback).filter(
        models.ClientSessionFeedback.session_id == session_id
    ).all()
    return feedback


@router.get("/session-performance/{session_id}", response_model=list[schemas.SessionPerformanceResponse])
def get_session_performance(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get performance evaluation for a specific session."""
    session = db.query(models.TrainingSession).filter(
        models.TrainingSession.id == session_id,
        models.TrainingSession.client_id == current_user.id
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Training session not found")

    performance = db.query(models.SessionPerformance).filter(
        models.SessionPerformance.session_id == session_id
    ).all()
    return performance
