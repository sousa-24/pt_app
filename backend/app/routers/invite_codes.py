"""
Invite codes endpoints: generate, list, and delete invite codes.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone, timedelta
import random
import string
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer

router = APIRouter(prefix="/api/v1", tags=["invite_codes"])


def generate_code():
    """Generate a random 8-character alphanumeric code."""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))


@router.post("/invite-codes/", response_model=schemas.InviteCodeResponse)
def create_invite_code(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Generate a new invite code for a trainer to share with clients."""
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


@router.get("/invite-codes/", response_model=list[schemas.InviteCodeResponse])
def list_invite_codes(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    return db.query(models.InviteCodes).filter(models.InviteCodes.trainer_id == current_user.id).all()


@router.delete("/invite-codes/{code_id}", response_model=schemas.StatusResponse)
def delete_invite_code(
    code_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    code = db.query(models.InviteCodes).filter(
        models.InviteCodes.id == code_id,
        models.InviteCodes.trainer_id == current_user.id
    ).first()
    if not code:
        raise HTTPException(status_code=404, detail="Invite code not found")
    db.delete(code)
    db.commit()
    return {"message": "Código de convite eliminado."}
