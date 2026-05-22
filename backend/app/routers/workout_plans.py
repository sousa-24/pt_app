"""
Workout plans endpoints: create, list, and update workout plans.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import models, schemas
from app.dependencies import require_trainer, get_user_items, verify_user_ownership
from app.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["workout_plans"])


@router.post("/workout_plans/", response_model=schemas.WorkoutPlanResponse)
def create_workout_plan(
    plan: schemas.WorkoutPlanCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_trainer)
):
    """Create a new workout plan with exercises."""
    new_plan = models.WorkoutPlan(
        title=plan.title,
        trainer_id=current_user.id,
        client_id=plan.client_id
    )
    db.add(new_plan)
    db.commit()
    db.refresh(new_plan)

    for exercise in plan.exercises:
        new_exercise = models.Exercise(
            workout_plan_id=new_plan.id,
            name=exercise.name,
            sets=exercise.sets,
            reps=exercise.reps,
            rest_time=exercise.rest_time,
            notes=exercise.notes
        )
        db.add(new_exercise)

    db.commit()
    db.refresh(new_plan)
    return new_plan


@router.get("/workout_plans/", response_model=list[schemas.WorkoutPlanResponse])
def get_workout_plans(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get all workout plans for the current user (trainer or client)."""
    plans = get_user_items(db, models.WorkoutPlan, current_user)
    return plans


@router.put("/workout_plans/{plan_id}", response_model=schemas.WorkoutPlanResponse)
def update_workout_plan(
    plan_id: int,
    plan_update: schemas.WorkoutPlanUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Update workout plan (e.g., mark as completed)."""
    db_plan = db.query(models.WorkoutPlan).filter(models.WorkoutPlan.id == plan_id).first()
    
    if not db_plan:
        raise HTTPException(status_code=404, detail="Plano de treino não encontrado")
    
    verify_user_ownership(db, db_plan, current_user)
    
    db_plan.completed = plan_update.completed
    db.add(db_plan)
    db.commit()
    db.refresh(db_plan)
    
    return db_plan
