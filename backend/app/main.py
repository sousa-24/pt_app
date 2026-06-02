from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.database import engine, get_db, Base
from app import models, schemas
from fastapi.middleware.cors import CORSMiddleware
from app.websocket_manager import manager
from app.auth import get_user_from_token
from app.services.notification_services import create_notification

# Import all routers
from app.routers import (
    auth,
    workout_plans,
    training_sessions,
    progression,
    nutri_plans,
    invite_codes,
    messages,
    contacts,
    session_feedback,
    notifications
)

def ensure_training_session_group_columns():
    """Adds group-session columns when the table already exists."""
    with engine.begin() as connection:
        existing_columns = {
            row[0]
            for row in connection.execute(text("SHOW COLUMNS FROM training_sessions"))
        }

        if "session_type" not in existing_columns:
            connection.execute(
                text(
                    "ALTER TABLE training_sessions "
                    "ADD COLUMN session_type VARCHAR(20) NOT NULL DEFAULT 'individual'"
                )
            )

        if "max_students" not in existing_columns:
            connection.execute(
                text("ALTER TABLE training_sessions ADD COLUMN max_students INT NULL")
            )

        if "client_id" in existing_columns:
            connection.execute(
                text("ALTER TABLE training_sessions MODIFY COLUMN client_id INT NULL")
            )


# Create tables if they don't exist
Base.metadata.create_all(bind=engine)
ensure_training_session_group_columns()

# Create FastAPI instance and configure CORS
app = FastAPI(title="FITPRO API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register all routers
app.include_router(auth.router)
app.include_router(workout_plans.router)
app.include_router(training_sessions.router)
app.include_router(progression.router)
app.include_router(nutri_plans.router)
app.include_router(invite_codes.router)
app.include_router(messages.router)
app.include_router(contacts.router)
app.include_router(session_feedback.router)
app.include_router(notifications.router)

# WebSocket endpoint for real-time messaging
@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int):
    """WebSocket endpoint for real-time messaging between users."""
    db = next(get_db())
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=1008)
        return

    try:
        auth_user = get_user_from_token(token, db)
    except HTTPException:
        await websocket.close(code=1008)
        return

    if auth_user.id != user_id:
        await websocket.close(code=1008)
        return

    await manager.connect(websocket, user_id)

    try:
        while True:
            try:
                data = await websocket.receive_json()
            except WebSocketDisconnect:
                raise
            except Exception:
                continue

            receiver_id = data.get("receiver_id")
            content = data.get("content")
            if receiver_id is None or content is None:
                continue

            try:
                receiver_id = int(receiver_id)
            except (TypeError, ValueError):
                continue

            new_message = models.Message(
                sender_id=auth_user.id,
                receiver_id=receiver_id,
                content=content,
            )
            db.add(new_message)
            db.commit()
            db.refresh(new_message)

            payload = {
                "type": "message",
                "id": new_message.id,
                "sender_id": auth_user.id,
                "receiver_id": receiver_id,
                "content": new_message.content,
                "created_at": new_message.created_at.isoformat(),
            }

            await manager.send_message(payload, receiver_id)
            await websocket.send_json({"type": "sent", "message": payload})

            create_notification(
                db=db,
                user_id=receiver_id,
                title="Nova mensagem",
                message=f"{auth_user.name} enviou-lhe uma mensagem.",
                type="message",
            )
            await manager.send_message({"type": "new_notification"}, receiver_id)

    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
        await manager.broadcast({"type": "user_left", "user_id": user_id})
    finally:
        db.close()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
