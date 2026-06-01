"""
Session feedback endpoints: client feedback and trainer performance evaluation.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer, require_client, verify_user_ownership
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


@router.put("/session-feedback/{feedback_id}", response_model=schemas.ClientSessionFeedbackResponse)
def update_session_feedback(
    feedback_id: int,
    data: schemas.ClientSessionFeedbackUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_client)
):
    """Client updates their own session feedback."""
    feedback = db.query(models.ClientSessionFeedback).filter(
        models.ClientSessionFeedback.id == feedback_id,
        models.ClientSessionFeedback.client_id == current_user.id
    ).first()
    if not feedback:
        raise HTTPException(status_code=404, detail="Feedback não encontrado")
    if data.rating is not None:
        feedback.rating = data.rating
    if data.notes is not None:
        feedback.notes = data.notes
    db.commit()
    db.refresh(feedback)
    return feedback


@router.delete("/session-feedback/{feedback_id}", response_model=schemas.StatusResponse)
def delete_session_feedback(
    feedback_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_client)
):
    """Client deletes their own session feedback."""
    feedback = db.query(models.ClientSessionFeedback).filter(
        models.ClientSessionFeedback.id == feedback_id,
        models.ClientSessionFeedback.client_id == current_user.id
    ).first()
    if not feedback:
        raise HTTPException(status_code=404, detail="Feedback não encontrado")
    db.delete(feedback)
    db.commit()
    return {"message": "Feedback eliminado com sucesso"}


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


@router.put("/session-performance/{performance_id}", response_model=schemas.SessionPerformanceResponse)
def update_session_performance(
    performance_id: int,
    data: schemas.SessionPerformanceUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Trainer updates a session performance record."""
    performance = db.query(models.SessionPerformance).filter(
        models.SessionPerformance.id == performance_id,
        models.SessionPerformance.trainer_id == current_user.id
    ).first()
    if not performance:
        raise HTTPException(status_code=404, detail="Avaliação de performance não encontrada")
    if data.performance_rating is not None:
        performance.performance_rating = data.performance_rating
    if data.notes is not None:
        performance.notes = data.notes
    db.commit()
    db.refresh(performance)
    return performance


@router.delete("/session-performance/{performance_id}", response_model=schemas.StatusResponse)
def delete_session_performance(
    performance_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Trainer deletes a session performance record."""
    performance = db.query(models.SessionPerformance).filter(
        models.SessionPerformance.id == performance_id,
        models.SessionPerformance.trainer_id == current_user.id
    ).first()
    if not performance:
        raise HTTPException(status_code=404, detail="Avaliação de performance não encontrada")
    db.delete(performance)
    db.commit()
    return {"message": "Avaliação de performance eliminada com sucesso"}


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
