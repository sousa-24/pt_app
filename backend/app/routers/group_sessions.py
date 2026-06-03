"""
Endpoints para criar e gerir aulas em grupo.
"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer, require_client
from app.auth import get_current_user
from app.services.notification_services import create_notification

router = APIRouter(prefix="/api/v1", tags=["group_sessions"])


def _validate_session_date(date: datetime):
    now = datetime.now(date.tzinfo) if date.tzinfo else datetime.now()
    if date < now + timedelta(hours=24):
        raise HTTPException(
            status_code=400,
            detail="A aula deve ser agendada com pelo menos 24 horas de antecedência.",
        )


def _session_response(session: models.GroupSession, current_user: models.User) -> dict:
    registrations = session.registrations or []
    return {
        "id": session.id,
        "trainer_id": session.trainer_id,
        "date": session.date,
        "max_students": session.max_students,
        "registered_students": len(registrations),
        "is_enrolled": any(r.client_id == current_user.id for r in registrations),
        "status": session.status,
        "notes": session.notes,
        "created_at": session.created_at,
    }


@router.post("/group_sessions/", response_model=schemas.GroupSessionResponse)
def create_group_session(
    data: schemas.GroupSessionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer),
):
    """Cria uma nova aula em grupo."""
    _validate_session_date(data.date)

    if data.max_students < 1:
        raise HTTPException(status_code=400, detail="Indica um limite de alunos válido.")

    session = models.GroupSession(
        trainer_id=current_user.id,
        date=data.date,
        max_students=data.max_students,
        notes=data.notes,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return _session_response(session, current_user)


@router.get("/group_sessions/", response_model=list[schemas.GroupSessionResponse])
def get_group_sessions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Lista aulas em grupo: treinador vê as suas, cliente vê as em que está inscrito."""
    if current_user.role == "trainer":
        sessions = db.query(models.GroupSession).filter(
            models.GroupSession.trainer_id == current_user.id
        ).all()
    else:
        enrolled_ids = db.query(models.GroupSessionRegistration.session_id).filter(
            models.GroupSessionRegistration.client_id == current_user.id
        )
        sessions = db.query(models.GroupSession).filter(
            models.GroupSession.id.in_(enrolled_ids)
        ).all()

    return [_session_response(s, current_user) for s in sessions]


@router.get("/group_sessions/available", response_model=list[schemas.GroupSessionResponse])
def get_available_group_sessions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_client),
):
    """Lista aulas em grupo disponíveis para inscrição do cliente."""
    now = datetime.now(timezone.utc)
    sessions = db.query(models.GroupSession).filter(
        models.GroupSession.trainer_id == current_user.trainer_id,
        models.GroupSession.status == "scheduled",
        models.GroupSession.date >= now,
    ).all()

    return [
        _session_response(s, current_user)
        for s in sessions
        if len(s.registrations) < s.max_students
        and not any(r.client_id == current_user.id for r in s.registrations)
    ]


@router.post("/group_sessions/{session_id}/enroll", response_model=schemas.GroupSessionResponse)
def enroll_group_session(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_client),
):
    """Inscreve o cliente numa aula em grupo."""
    session = db.query(models.GroupSession).filter(
        models.GroupSession.id == session_id,
        models.GroupSession.trainer_id == current_user.trainer_id,
        models.GroupSession.status == "scheduled",
    ).first()
    if not session:
        raise HTTPException(status_code=404, detail="Aula em grupo não encontrada.")

    now = datetime.now(session.date.tzinfo) if session.date.tzinfo else datetime.now()
    if session.date < now:
        raise HTTPException(status_code=400, detail="Esta aula já passou.")

    already_enrolled = db.query(models.GroupSessionRegistration).filter(
        models.GroupSessionRegistration.session_id == session_id,
        models.GroupSessionRegistration.client_id == current_user.id,
    ).first()
    if already_enrolled:
        return _session_response(session, current_user)

    if len(session.registrations) >= session.max_students:
        raise HTTPException(status_code=400, detail="Esta aula em grupo já está lotada.")

    db.add(models.GroupSessionRegistration(
        session_id=session_id,
        client_id=current_user.id,
    ))
    db.commit()
    db.refresh(session)

    create_notification(
        db=db,
        user_id=session.trainer_id,
        title="Nova inscrição em aula de grupo",
        message=f"{current_user.name} inscreveu-se na aula em grupo de {session.date.strftime('%Y-%m-%d %H:%M')}.",
        type="training_session",
    )

    return _session_response(session, current_user)


@router.put("/group_sessions/{session_id}", response_model=schemas.GroupSessionResponse)
def update_group_session(
    session_id: int,
    data: schemas.GroupSessionUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer),
):
    """Atualiza uma aula em grupo."""
    session = db.query(models.GroupSession).filter(
        models.GroupSession.id == session_id,
        models.GroupSession.trainer_id == current_user.id,
    ).first()
    if not session:
        raise HTTPException(status_code=404, detail="Aula em grupo não encontrada.")

    if data.date is not None:
        _validate_session_date(data.date)
        session.date = data.date
    if data.max_students is not None:
        if data.max_students < len(session.registrations):
            raise HTTPException(
                status_code=400,
                detail="O novo limite é inferior ao número de alunos já inscritos.",
            )
        session.max_students = data.max_students
    if data.notes is not None:
        session.notes = data.notes
    if data.status is not None:
        session.status = data.status

    db.commit()
    db.refresh(session)
    return _session_response(session, current_user)


@router.delete("/group_sessions/{session_id}", response_model=schemas.StatusResponse)
def delete_group_session(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer),
):
    """Elimina uma aula em grupo e todas as inscrições associadas."""
    session = db.query(models.GroupSession).filter(
        models.GroupSession.id == session_id,
        models.GroupSession.trainer_id == current_user.id,
    ).first()
    if not session:
        raise HTTPException(status_code=404, detail="Aula em grupo não encontrada.")

    db.query(models.GroupSessionRegistration).filter(
        models.GroupSessionRegistration.session_id == session_id
    ).delete(synchronize_session=False)
    db.delete(session)
    db.commit()
    return {"message": "Aula em grupo eliminada com sucesso"}
