"""
Contacts endpoints: retrieve contacts (trainers see clients, clients see trainer).
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["contacts"])


@router.get("/my-contacts/", response_model=list[schemas.UserResponse])
def get_contacts(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Get contacts list.
    - Trainers see all their clients
    - Clients see their assigned trainer
    """
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
