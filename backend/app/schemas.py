from datetime import datetime
from pydantic import BaseModel, EmailStr
from enum import Enum

class RoleEnum(str, Enum):
    trainer = "trainer"
    client = "client"

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: RoleEnum
    invite_code: str | None = None

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: str

    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    role: str

class ExerciseCreate(BaseModel):
    name: str
    sets: int
    reps: int
    rest_time: int | None = None
    notes: str | None = None

class ExerciseResponse(BaseModel):
    id: int
    name: str
    sets: int
    reps: int
    rest_time: int | None = None
    notes: str | None = None

    class Config:
        from_attributes = True

class WorkoutPlanCreate(BaseModel):
    title: str
    client_id: int
    exercises: list[ExerciseCreate]

class WorkoutPlanResponse(BaseModel):
    id: int
    title: str
    trainer_id: int
    client_id: int
    exercises: list[ExerciseResponse]
    created_at: datetime

    class Config:
        from_attributes = True


class TrainingSessionCreate(BaseModel):
    client_id: int
    workout_plan_id: int | None = None
    date: datetime
    notes: str | None = None

class TrainingSessionResponse(BaseModel):
    id: int
    client_id: int
    trainer_id: int
    workout_plan_id: int | None = None
    date: datetime
    status: str
    notes: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True

class UserProgressionCreate(BaseModel):
    client_id: int
    date: datetime
    weight: float | None = None
    body_fat_percentage: float | None = None
    notes: str | None = None

class UserProgressionResponse(BaseModel):
    id: int
    client_id: int
    date: datetime
    weight: float | None = None
    body_fat_percentage: float | None = None
    notes: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True

class InviteCodeCreate(BaseModel):
    pass

class InviteCodeResponse(BaseModel):
    id: int
    code: str
    used: bool
    expires_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True