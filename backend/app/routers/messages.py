"""
Messages endpoints: retrieve messages between users.
Note: WebSocket messaging is handled in main.py
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from app.database import get_db
from app import models, schemas
from app.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["messages"])


@router.get("/messages/{other_user_id}", response_model=list[schemas.MessageResponse])
def get_messages(
    other_user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Get all messages between current user and another user."""
    messages = db.query(models.Message).filter(
        ((models.Message.sender_id == current_user.id) & (models.Message.receiver_id == other_user_id)) |
        ((models.Message.sender_id == other_user_id) & (models.Message.receiver_id == current_user.id))
    ).order_by(models.Message.created_at).all()
    return messages


@router.get("/conversations/", response_model=list[schemas.ConversationResponse])
def get_conversations(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Get all conversations for the current user, ordered by most recent message."""
    messages = db.query(models.Message).filter(
        or_(
            models.Message.sender_id == current_user.id,
            models.Message.receiver_id == current_user.id,
        )
    ).order_by(models.Message.created_at.desc()).all()

    seen = {}
    for msg in messages:
        other_id = msg.receiver_id if msg.sender_id == current_user.id else msg.sender_id
        if other_id not in seen:
            seen[other_id] = msg

    conversations = []
    for other_id, last_msg in seen.items():
        other_user = db.query(models.User).filter(models.User.id == other_id).first()
        if other_user:
            conversations.append({
                "user": other_user,
                "last_message": last_msg.content,
                "last_message_at": last_msg.created_at,
            })

    return conversations
