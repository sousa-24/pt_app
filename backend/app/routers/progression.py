"""
User progression endpoints: track weight, body composition, and fitness progress.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer, get_user_items
from app.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["progression"])


@router.post("/progression/", response_model=schemas.UserProgressionResponse)
def create_progression(
    progression: schemas.UserProgressionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Create a new progression record."""
    if current_user.role == "trainer":
        if progression.client_id is None:
            raise HTTPException(
                status_code=400,
                detail="client_id e obrigatorio para treinadores"
            )
        client_id = progression.client_id
        trainer_id = current_user.id
    else:
        if current_user.trainer_id is None:
            raise HTTPException(
                status_code=400,
                detail="Cliente sem treinador associado"
            )
        client_id = current_user.id
        trainer_id = current_user.trainer_id

    muscle_mass = progression.muscle_mass
    if (
        muscle_mass is None
        and progression.weight is not None
        and progression.body_fat_percentage is not None
    ):
        muscle_mass = round(
            progression.weight * (1 - progression.body_fat_percentage / 100),
            2
        )

    new_progression = models.UserProgression(
        client_id=client_id,
        trainer_id=trainer_id,
        date=progression.date,
        weight=progression.weight,
        body_fat_percentage=progression.body_fat_percentage,
        muscle_mass=muscle_mass,
        notes=progression.notes
    )
    db.add(new_progression)
    db.commit()
    db.refresh(new_progression)
    return new_progression


@router.get("/progression/", response_model=list[schemas.UserProgressionResponse])
def get_progression(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get all progression records for the current user."""
    progression = get_user_items(db, models.UserProgression, current_user)
    return progression


@router.get("/progression/{client_id}", response_model=list[schemas.UserProgressionResponse])
def get_client_progression(
    client_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Get progression records for a specific client. Only trainers can access."""
    progression = db.query(models.UserProgression).filter(
        models.UserProgression.client_id == client_id,
        models.UserProgression.trainer_id == current_user.id
    ).order_by(models.UserProgression.date).all()
    
    return progression
