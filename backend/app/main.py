from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Depends
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
    profile,
    workout_plans,
    training_sessions,
    group_sessions,
    progression,
    nutri_plans,
    invite_codes,
    messages,
    contacts,
    session_feedback,
    notifications,
    payments
)

# Create tables if they don't exist
Base.metadata.create_all(bind=engine)

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
app.include_router(profile.router)
app.include_router(workout_plans.router)
app.include_router(training_sessions.router)
app.include_router(group_sessions.router)
app.include_router(progression.router)
app.include_router(nutri_plans.router)
app.include_router(invite_codes.router)
app.include_router(messages.router)
app.include_router(contacts.router)
app.include_router(session_feedback.router)
app.include_router(notifications.router)
app.include_router(payments.router)

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
