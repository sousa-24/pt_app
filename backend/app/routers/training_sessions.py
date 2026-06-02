"""
Endpoints para criar e listar sessões de treino.
"""
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer, require_client
from app.auth import get_current_user
from app.services.notification_services import create_notification

router = APIRouter(prefix="/api/v1", tags=["training_sessions"])


def validate_session_date(date: datetime):
    now = datetime.now(date.tzinfo) if date.tzinfo else datetime.now()
    earliest_allowed_date = now + timedelta(hours=24)

    validate_future_session_date(date)

    if date < earliest_allowed_date:
        raise HTTPException(
            status_code=400,
            detail="A sessão de treino deve ser agendada com pelo menos 24 horas de antecedência."
        )


def validate_future_session_date(date: datetime):
    now = datetime.now(date.tzinfo) if date.tzinfo else datetime.now()

    if date < now:
        raise HTTPException(
            status_code=400,
            detail="A sessão de treino não pode ser agendada para uma data/hora passada."
        )


def session_response(session: models.TrainingSession, current_user: models.User):
    registrations = getattr(session, "registrations", []) or []
    registered_students = len(registrations)
    is_enrolled = any(
        registration.client_id == current_user.id for registration in registrations
    )

    return {
        "id": session.id,
        "client_id": session.client_id,
        "trainer_id": session.trainer_id,
        "workout_plan_id": session.workout_plan_id,
        "date": session.date,
        "session_type": session.session_type or "individual",
        "max_students": session.max_students,
        "registered_students": registered_students,
        "is_enrolled": is_enrolled,
        "status": session.status,
        "notes": session.notes,
        "created_at": session.created_at,
    }


@router.post("/training_sessions/", response_model=schemas.TrainingSessionResponse)
def create_training_session(
    session: schemas.TrainingSessionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Cria uma nova sessão de treino."""
    validate_session_date(session.date)

    client = None
    if session.session_type == schemas.TrainingSessionType.individual:
        if session.client_id is None:
            raise HTTPException(status_code=400, detail="Indica o ID do aluno.")

        client = db.query(models.User).filter(
            models.User.id == session.client_id,
            models.User.role == "client",
            models.User.trainer_id == current_user.id
        ).first()
        if not client:
            raise HTTPException(
                status_code=404,
                detail="Aluno não encontrado para este treinador."
            )
    else:
        if session.max_students is None or session.max_students < 1:
            raise HTTPException(
                status_code=400,
                detail="Indica um limite de alunos válido para a aula em grupo."
            )

    new_session = models.TrainingSession(
        client_id=session.client_id if client else None,
        trainer_id=current_user.id,
        workout_plan_id=session.workout_plan_id,
        date=session.date,
        session_type=session.session_type.value,
        max_students=session.max_students if session.session_type == schemas.TrainingSessionType.group else None,
        notes=session.notes
    )
    db.add(new_session)
    db.commit()
    db.refresh(new_session)

    if client:
        create_notification(
            db=db,
            user_id=session.client_id,
            title="Nova Sessão de Treino",
            message=f"O treinador {current_user.name} agendou uma nova sessão de treino para si no dia {session.date.strftime('%Y-%m-%d %H:%M')}.",
            type="training_session"
        )

    return session_response(new_session, current_user)


@router.get("/training_sessions/", response_model=list[schemas.TrainingSessionResponse])
def get_training_sessions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Lista todas as sessões de treino do utilizador atual."""
    if current_user.role == "trainer":
        sessions = db.query(models.TrainingSession).filter(
            models.TrainingSession.trainer_id == current_user.id
        ).all()
    else:
        registered_session_ids = db.query(
            models.GroupSessionRegistration.session_id
        ).filter(
            models.GroupSessionRegistration.client_id == current_user.id
        )
        sessions = db.query(models.TrainingSession).filter(
            (
                (models.TrainingSession.session_type == "individual") &
                (models.TrainingSession.client_id == current_user.id)
            ) |
            (
                (models.TrainingSession.session_type == "group") &
                (models.TrainingSession.id.in_(registered_session_ids))
            )
        ).all()

    return [session_response(session, current_user) for session in sessions]


@router.get("/group_training_sessions/available", response_model=list[schemas.TrainingSessionResponse])
def get_available_group_training_sessions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_client)
):
    """Lista aulas em grupo disponíveis para inscrição do cliente."""
    sessions = db.query(models.TrainingSession).filter(
        models.TrainingSession.trainer_id == current_user.trainer_id,
        models.TrainingSession.session_type == "group",
        models.TrainingSession.status == "scheduled",
        models.TrainingSession.date >= datetime.now()
    ).all()

    return [
        session_response(session, current_user)
        for session in sessions
        if session.max_students is None or len(session.registrations) < session.max_students
    ]


@router.post("/group_training_sessions/{session_id}/enroll", response_model=schemas.TrainingSessionResponse)
def enroll_group_training_session(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_client)
):
    """Inscreve o cliente numa aula em grupo."""
    session = db.query(models.TrainingSession).filter(
        models.TrainingSession.id == session_id,
        models.TrainingSession.trainer_id == current_user.trainer_id,
        models.TrainingSession.session_type == "group",
        models.TrainingSession.status == "scheduled"
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Aula em grupo não encontrada.")

    validate_future_session_date(session.date)

    already_enrolled = db.query(models.GroupSessionRegistration).filter(
        models.GroupSessionRegistration.session_id == session.id,
        models.GroupSessionRegistration.client_id == current_user.id
    ).first()
    if already_enrolled:
        return session_response(session, current_user)

    if session.max_students is not None and len(session.registrations) >= session.max_students:
        raise HTTPException(status_code=400, detail="Esta aula em grupo já está lotada.")

    registration = models.GroupSessionRegistration(
        session_id=session.id,
        client_id=current_user.id
    )
    db.add(registration)
    db.commit()
    db.refresh(session)

    create_notification(
        db=db,
        user_id=session.trainer_id,
        title="Nova inscrição em aula de grupo",
        message=f"{current_user.name} inscreveu-se na aula em grupo de {session.date.strftime('%Y-%m-%d %H:%M')}.",
        type="training_session"
    )

    return session_response(session, current_user)
