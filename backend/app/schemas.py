from datetime import datetime
from pydantic import BaseModel, EmailStr, model_validator
from enum import Enum

# Esquemas Pydantic usados para validação de entrada e serialização de respostas.
# Cada classe define os campos esperados nas requisições e nas respostas da API.

class RoleEnum(str, Enum):
    trainer = "trainer"
    client = "client"


# Esquema para criar um novo utilizador no sistema.
class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: RoleEnum
    invite_code: str | None = None


# Esquema usado ao devolver dados de utilizador para o cliente.
class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: str
    trainer_id: int | None = None

    model_config = {"from_attributes": True}


# Esquema de login que apenas recebe email e password.
class UserLogin(BaseModel):
    email: EmailStr
    password: str


# Esquema do token JWT devolvido após autenticação.
class Token(BaseModel):
    access_token: str
    token_type: str
    role: str


# Esquema para criar um exercício dentro de um plano de treino.
class ExerciseCreate(BaseModel):
    name: str
    sets: int
    reps: int
    rest_time: int | None = None
    notes: str | None = None


# Esquema de resposta para um exercício criado ou recuperado.
class ExerciseResponse(BaseModel):
    id: int
    name: str
    sets: int
    reps: int
    rest_time: int | None = None
    notes: str | None = None
    model_config = {"from_attributes": True}


# Esquema para criar um plano de treino com vários exercícios.
class WorkoutPlanCreate(BaseModel):
    title: str
    client_id: int
    exercises: list[ExerciseCreate]


# Esquema para atualizar um plano de treino (ex: marcar como completo).
class WorkoutPlanUpdate(BaseModel):
    completed: bool


# Esquema de resposta para um plano de treino, incluindo exercícios e metadados.
class WorkoutPlanResponse(BaseModel):
    id: int
    title: str
    trainer_id: int
    client_id: int
    exercises: list[ExerciseResponse]
    completed: bool
    created_at: datetime
    model_config = {"from_attributes": True}


# Esquema para agendar ou atualizar uma sessão de treino.
class TrainingSessionCreate(BaseModel):
    client_id: int
    workout_plan_id: int | None = None
    date: datetime
    notes: str | None = None


# Esquema de resposta para sessões de treino agendadas.
class TrainingSessionResponse(BaseModel):
    id: int
    client_id: int
    trainer_id: int
    workout_plan_id: int | None = None
    date: datetime
    status: str
    notes: str | None = None
    created_at: datetime
    model_config = {"from_attributes": True}


# Esquema para registar um novo registo de progressão do cliente.
class UserProgressionCreate(BaseModel):
    client_id: int
    date: datetime
    weight: float | None = None
    body_fat_percentage: float | None = None
    notes: str | None = None


# Esquema de resposta para os dados de progressão do cliente.
class UserProgressionResponse(BaseModel):
    id: int
    client_id: int
    date: datetime
    weight: float | None = None
    body_fat_percentage: float | None = None
    notes: str | None = None
    created_at: datetime
    model_config = {"from_attributes": True}


# Esquema para criação de código de convite (pode ser preenchido no servidor).
class InviteCodeCreate(BaseModel):
    pass


# Esquema de resposta para um código de convite existente.
class InviteCodeResponse(BaseModel):
    id: int
    code: str
    used: bool
    expires_at: datetime
    created_at: datetime
    model_config = {"from_attributes": True}


# Esquema para adicionar um item alimentar a uma refeição.
class FoodItemCreate(BaseModel):
    name: str
    weight: float
    calories: float
    protein: float
    carbs: float
    fats: float
    notes: str | None = None


# Esquema de resposta para um item alimentar.
class FoodItemResponse(BaseModel):
    id: int
    name: str
    weight: float
    calories: float
    protein: float
    carbs: float
    fats: float
    notes: str | None = None
    model_config = {"from_attributes": True}


# Esquema para criar uma refeição com vários itens alimentares.
class MealCreate(BaseModel):
    name: str
    food_items: list[FoodItemCreate]


# Esquema de resposta para uma refeição dentro de um plano nutricional.
class MealResponse(BaseModel):
    id: int
    name: str
    food_items: list[FoodItemResponse]
    model_config = {"from_attributes": True}


# Esquema para criar um plano nutricional completo.
class NutriPlanCreate(BaseModel):
    title: str
    client_id: int
    meals: list[MealCreate]


# Esquema de resposta para um plano nutricional.
class NutriPlanResponse(BaseModel):
    id: int
    title: str
    trainer_id: int
    client_id: int
    meals: list[MealResponse]
    created_at: datetime
    model_config = {"from_attributes": True}


# Esquema para criar uma mensagem entre utilizadores.
class MessageCreate(BaseModel):
    receiver_id: int
    content: str


# Esquema de resposta para mensagens enviadas e recebidas.
class MessageResponse(BaseModel):
    id: int
    sender_id: int
    receiver_id: int
    content: str
    created_at: datetime
    model_config = {"from_attributes": True}

#Esquema para introdução de progresso do cliente
class UserProgressionCreate(BaseModel):
    client_id: int
    date: datetime
    weight: float | None = None
    body_fat_percentage: float | None = None
    notes: str | None = None

# Esquema de resposta para os dados de progressão do cliente.
class UserProgressionResponse(BaseModel):
    id: int
    client_id: int
    date: datetime
    weight: float | None = None
    body_fat_percentage: float | None = None
    muscle_mass: float | None = None
    notes: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}

#Calcula a massa muscular com base no peso e na percentagem de gordura corporal, se ambos os valores forem fornecidos.
    @model_validator(mode='after')
    def calculate_muscle_mass(self):
        if self.weight is not None and self.body_fat_percentage is not None:
            self.muscle_mass = round(self.weight * (1 - self.body_fat_percentage / 100), 2)
        return self
    
#Esquema para criação do feedback do cliente
class ClientSessionFeedbackCreate(BaseModel):
    session_id: int
    rating: int
    notes: str | None = None

# Esquema de resposta para o feedback do cliente.
class ClientSessionFeedbackResponse(BaseModel):
    id: int
    session_id: int
    cliente_id: int
    trainer_id: int
    rating: int
    notes: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}

# Esquema para criação da performance da sessão de treino
class SessionPerformanceCreate(BaseModel):
    session_id: int
    client_id: int
    performance_rating: int
    notes: str | None = None

# Esquema de resposta para a performance da sessão de treino
class SessionPerformanceResponse(BaseModel):
    id: int
    session_id: int
    cliente_id: int
    trainer_id: int
    performance_rating: int
    notes: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


