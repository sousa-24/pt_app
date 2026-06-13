from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.auth import pwd_context, get_current_user
from app import cloudinary_config  # noqa: F401 - configures the Cloudinary SDK on import
import cloudinary.uploader

router = APIRouter(prefix="/api/v1/profile", tags=["profile"])


@router.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user


@router.patch("/me", response_model=schemas.UserResponse)
def update_me(
    updated_user: schemas.UserProfileUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if updated_user.name is not None:
        current_user.name = updated_user.name
    if updated_user.email is not None:
        existing = db.query(models.User).filter(models.User.email == updated_user.email).first()
        if existing and existing.id != current_user.id:
            raise HTTPException(status_code=400, detail="Email já em uso")
        current_user.email = updated_user.email
    if updated_user.password is not None:
        current_user.password = pwd_context.hash(updated_user.password)
    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/me/picture", response_model=schemas.UserResponse)
def upload_profile_picture(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if file.content_type not in ("image/jpeg", "image/png", "image/webp"):
        raise HTTPException(status_code=400, detail="Formato de imagem inválido")

    result = cloudinary.uploader.upload(
        file.file,
        folder="profile_pictures",
        public_id=f"user_{current_user.id}",
        overwrite=True,
    )

    current_user.profile_picture_url = result["secure_url"]
    db.commit()
    db.refresh(current_user)
    return current_user
