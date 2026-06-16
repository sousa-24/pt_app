"""
Nutrition plans endpoints: create and list nutrition plans with meals.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer, get_user_items
from app.auth import get_current_user
from app.services.notification_services import create_notification

router = APIRouter(prefix="/api/v1", tags=["nutri_plans"])


@router.post("/nutri_plans/", response_model=schemas.NutriPlanResponse)
def create_nutri_plan(
    plan: schemas.NutriPlanCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Create a new nutrition plan with meals."""
    new_plan = models.NutriPlan(
        title=plan.title,
        trainer_id=current_user.id,
        client_id=plan.client_id
    )
    db.add(new_plan)
    db.commit()
    db.refresh(new_plan)

    for meal_data in plan.meals:
        new_meal = models.Meal(
            nutri_plan_id=new_plan.id,
            name=meal_data.name
        )
        db.add(new_meal)
        db.commit()
        db.refresh(new_meal)

        for food_data in meal_data.food_items:
            new_food = models.FoodItem(
                meal_id=new_meal.id,
                **food_data.model_dump()
            )
            db.add(new_food)

    db.commit()
    db.refresh(new_plan)

    if plan.client_id:
        create_notification(
            db=db,
            user_id=plan.client_id,
            title="Novo Plano Nutricional",
            message=f"O treinador {current_user.name} atribuiu-lhe um novo plano nutricional: {plan.title}.",
            type="nutri_plan",
        )

    return new_plan


@router.get("/nutri_plans/", response_model=list[schemas.NutriPlanResponse])
def get_nutri_plans(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get all nutrition plans for the current user."""
    plans = get_user_items(db, models.NutriPlan, current_user)
    return plans


@router.get("/nutri_plans/{plan_id}", response_model=schemas.NutriPlanResponse)
def get_nutri_plan(
    plan_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    plan = db.query(models.NutriPlan).filter(models.NutriPlan.id == plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano nutricional não encontrado")
    if plan.trainer_id != current_user.id and plan.client_id != current_user.id:
        raise HTTPException(status_code=403, detail="Não tens permissão para aceder a este recurso")
    return plan


@router.put("/nutri_plans/{plan_id}", response_model=schemas.NutriPlanResponse)
def update_nutri_plan(
    plan_id: int,
    data: schemas.NutriPlanUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Update a nutrition plan. Providing meals replaces all existing meals."""
    plan = db.query(models.NutriPlan).filter(
        models.NutriPlan.id == plan_id,
        models.NutriPlan.trainer_id == current_user.id
    ).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano nutricional não encontrado")

    if data.title is not None:
        plan.title = data.title

    if data.meals is not None:
        for meal in plan.meals:
            db.query(models.FoodItem).filter(models.FoodItem.meal_id == meal.id).delete()
        db.query(models.Meal).filter(models.Meal.nutri_plan_id == plan_id).delete()
        db.commit()

        for meal_data in data.meals:
            new_meal = models.Meal(nutri_plan_id=plan_id, name=meal_data.name)
            db.add(new_meal)
            db.commit()
            db.refresh(new_meal)
            for food_data in meal_data.food_items:
                db.add(models.FoodItem(meal_id=new_meal.id, **food_data.model_dump()))

    db.commit()
    db.refresh(plan)
    return plan


@router.delete("/nutri_plans/{plan_id}", response_model=schemas.StatusResponse)
def delete_nutri_plan(
    plan_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Delete a nutrition plan and all its meals."""
    plan = db.query(models.NutriPlan).filter(
        models.NutriPlan.id == plan_id,
        models.NutriPlan.trainer_id == current_user.id
    ).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano nutricional não encontrado")
    meal_ids = [row[0] for row in db.query(models.Meal.id).filter(models.Meal.nutri_plan_id == plan_id).all()]
    if meal_ids:
        db.query(models.FoodItem).filter(models.FoodItem.meal_id.in_(meal_ids)).delete(synchronize_session=False)
        db.query(models.Meal).filter(models.Meal.nutri_plan_id == plan_id).delete(synchronize_session=False)
    db.expunge(plan)
    db.execute(models.NutriPlan.__table__.delete().where(models.NutriPlan.id == plan_id))
    db.commit()
    return {"message": "Plano nutricional eliminado com sucesso"}
