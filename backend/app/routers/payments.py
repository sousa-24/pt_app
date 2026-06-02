from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer, get_user_items, verify_user_ownership
from app.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["payments"])


@router.post("/payments/", response_model=schemas.PaymentResponse)
def create_payment(
    data: schemas.PaymentCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Cria um registo de pagamento para um cliente."""
    client = db.query(models.User).filter(
        models.User.id == data.client_id,
        models.User.role == "client",
        models.User.trainer_id == current_user.id
    ).first()
    if not client:
        raise HTTPException(status_code=404, detail="Cliente não encontrado para este treinador.")

    payment = models.Payment(
        trainer_id=current_user.id,
        client_id=data.client_id,
        type_of_service=data.type_of_service,
        cost=data.cost,
        due_date=data.due_date,
        payment_method=data.payment_method,
        notes=data.notes,
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)
    return payment


@router.get("/payments/", response_model=list[schemas.PaymentResponse])
def get_payments(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Lista todos os pagamentos do utilizador atual."""
    return get_user_items(db, models.Payment, current_user)


@router.get("/payments/{payment_id}", response_model=schemas.PaymentResponse)
def get_payment(
    payment_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Devolve um pagamento específico."""
    payment = db.query(models.Payment).filter(models.Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Pagamento não encontrado.")
    verify_user_ownership(db, payment, current_user)
    return payment


@router.put("/payments/{payment_id}", response_model=schemas.PaymentResponse)
def update_payment(
    payment_id: int,
    data: schemas.PaymentUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Atualiza um registo de pagamento."""
    payment = db.query(models.Payment).filter(
        models.Payment.id == payment_id,
        models.Payment.trainer_id == current_user.id
    ).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Pagamento não encontrado.")

    if data.type_of_service is not None:
        payment.type_of_service = data.type_of_service
    if data.cost is not None:
        payment.cost = data.cost
    if data.status is not None:
        valid = {"pending", "paid", "overdue", "cancelled"}
        if data.status not in valid:
            raise HTTPException(status_code=400, detail=f"Estado inválido. Valores aceites: {valid}")
        payment.status = data.status
    if data.due_date is not None:
        payment.due_date = data.due_date
    if data.paid_at is not None:
        payment.paid_at = data.paid_at
    if data.payment_method is not None:
        payment.payment_method = data.payment_method
    if data.notes is not None:
        payment.notes = data.notes

    db.commit()
    db.refresh(payment)
    return payment


@router.delete("/payments/{payment_id}", response_model=schemas.StatusResponse)
def delete_payment(
    payment_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Elimina um registo de pagamento."""
    payment = db.query(models.Payment).filter(
        models.Payment.id == payment_id,
        models.Payment.trainer_id == current_user.id
    ).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Pagamento não encontrado.")

    db.delete(payment)
    db.commit()
    return {"message": "Pagamento eliminado com sucesso."}
