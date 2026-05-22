"""
Nutrition plans endpoints: create and list nutrition plans with meals.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer, get_user_items
from app.auth import get_current_user

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
    return new_plan


@router.get("/nutri_plans/", response_model=list[schemas.NutriPlanResponse])
def get_nutri_plans(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get all nutrition plans for the current user."""
    plans = get_user_items(db, models.NutriPlan, current_user)
    return plans
