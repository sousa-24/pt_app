

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app import models, schemas
from app.auth import get_current_user
from app.database import get_db

router = APIRouter(prefix="/api/v1", tags=["notifications"])

@router.get("/notifications/", response_model=list[schemas.NotificationResponse])
def get_notifications(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get all notifications for the current user."""
    notifications = db.query(models.Notification).filter(models.Notification.user_id == current_user.id).order_by(models.Notification.created_at.desc()).all()
    return notifications    

@router.get("/notifications/unread_count/", response_model=schemas.NotificationCountResponse)
def get_unread_notifications_count(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get the count of unread notifications for the current user."""
    count = db.query(models.Notification).filter(models.Notification.user_id == current_user.id, models.Notification.read == False).count()
    return {"count": count}

@router.put(
    "/notifications/{notification_id}/read/",
    response_model=schemas.StatusResponse
)
def mark_notification_as_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Mark a notification as read."""

    notification = (
        db.query(models.Notification)
        .filter(
            models.Notification.id == notification_id,
            models.Notification.user_id == current_user.id
        )
        .first()
    )

    if not notification:
        raise HTTPException(
            status_code=404,
            detail="Notification not found"
        )

    notification.read = True

    db.commit()

    return {"message": "Notification marked as read"}


@router.put(
    "/notifications/read_all/",
    response_model=schemas.StatusResponse
)
def mark_all_notifications_as_read(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Mark all notifications as read."""

    (
        db.query(models.Notification)
        .filter(
            models.Notification.user_id == current_user.id,
            models.Notification.read == False
        )
        .update({"read": True})
    )

    db.commit()

    return {"message": "All notifications marked as read"}


@router.delete("/notifications/{notification_id}", response_model=schemas.StatusResponse)
def delete_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    notification = db.query(models.Notification).filter(
        models.Notification.id == notification_id,
        models.Notification.user_id == current_user.id,
    ).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    db.delete(notification)
    db.commit()
    return {"message": "Notification deleted"}