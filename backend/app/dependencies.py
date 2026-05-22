"""
Shared dependencies and utilities for authentication and authorization.
"""
from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session
from app.auth import get_current_user
from app import models
from app.database import get_db


async def require_trainer(current_user: models.User = Depends(get_current_user)):
    """Dependency to ensure only trainers can access an endpoint."""
    if current_user.role != "trainer":
        raise HTTPException(
            status_code=403,
            detail="Apenas treinadores podem realizar esta ação"
        )
    return current_user


async def require_client(current_user: models.User = Depends(get_current_user)):
    """Dependency to ensure only clients can access an endpoint."""
    if current_user.role != "client":
        raise HTTPException(
            status_code=403,
            detail="Apenas clientes podem realizar esta ação"
        )
    return current_user


def get_user_items(
    db: Session,
    model,
    current_user: models.User,
    trainer_field: str = "trainer_id",
    client_field: str = "client_id"
):
    """
    Generic function to retrieve items filtered by user role.
    Trainers see items where trainer_id matches their ID.
    Clients see items where client_id matches their ID.
    """
    if current_user.role == "trainer":
        return db.query(model).filter(
            getattr(model, trainer_field) == current_user.id
        ).all()
    else:
        return db.query(model).filter(
            getattr(model, client_field) == current_user.id
        ).all()


def verify_user_ownership(
    db: Session,
    resource,
    current_user: models.User,
    trainer_field: str = "trainer_id",
    client_field: str = "client_id"
):
    """
    Verify that the current user owns the resource.
    Raises HTTPException if the user doesn't have access.
    """
    if current_user.role == "trainer":
        if current_user.id != getattr(resource, trainer_field):
            raise HTTPException(
                status_code=403,
                detail="Não tens permissão para aceder a este recurso"
            )
    else:
        if current_user.id != getattr(resource, client_field):
            raise HTTPException(
                status_code=403,
                detail="Não tens permissão para aceder a este recurso"
            )
    return True
