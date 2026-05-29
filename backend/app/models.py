from sqlalchemy import Column, Integer, String, Enum, DateTime, Text, ForeignKey, Float, Boolean
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime, timezone


# Modelo de utilizador do sistema, com email, password e papel (treinador ou cliente).
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    trainer_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    password = Column(String(255), nullable=False)
    role = Column(Enum("trainer", "client"), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


# Plano de treino atribuído por um treinador a um cliente.
class WorkoutPlan(Base):
    __tablename__ = "workout_plans"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(100), nullable=False)
    trainer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    client_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    completed = Column(Boolean, default=False)

    # Relação com os exercícios deste plano de treino.
    exercises = relationship("Exercise", back_populates="workout_plan")


# Exercício dentro de um plano de treino.
class Exercise(Base):
    __tablename__ = "exercises"

    id = Column(Integer, primary_key=True, index=True)
    workout_plan_id = Column(Integer, ForeignKey("workout_plans.id"), nullable=False)
    name = Column(String(100), nullable=False)
    sets = Column(Integer, nullable=False)
    reps = Column(Integer, nullable=False)
    rest_time = Column(Integer, nullable=True)
    notes = Column(String(255), nullable=True)

    # Relação inversa para recuperar o plano de treino.
    workout_plan = relationship("WorkoutPlan", back_populates="exercises")


# Sessão de treino agendada entre um cliente e um treinador.
class TrainingSession(Base):
    __tablename__ = "training_sessions"

    id = Column(Integer, primary_key=True, index=True)
    client_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    trainer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    workout_plan_id = Column(Integer, ForeignKey("workout_plans.id"), nullable=True)
    date = Column(DateTime, nullable=False)
    status = Column(Enum("scheduled", "completed", "cancelled"), default="scheduled")
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    feedback = relationship("ClientSessionFeedback", back_populates="session")
    performance = relationship("SessionPerformance", back_populates="session")


# Registos de progressão do cliente, usados para acompanhar peso e composição corporal.
class UserProgression(Base):
    __tablename__ = "user_progression"

    id = Column(Integer, primary_key=True, index=True)
    client_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    trainer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date = Column(DateTime, nullable=False)
    weight = Column(Float, nullable=True)
    body_fat_percentage = Column(Float, nullable=True)
    muscle_mass = Column(Float, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


# Códigos de convite usados para permitir que clientes se registem via treinador.
class InviteCodes(Base):
    __tablename__ = "invite_codes"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(100), unique=True, nullable=False)
    trainer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    used = Column(Boolean, default=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


# Plano nutricional atribuído a um cliente por um treinador.
class NutriPlan(Base):
    __tablename__ = "nutri_plans"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(100), nullable=False)
    trainer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    client_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Relação com as refeições deste plano nutricional.
    meals = relationship("Meal", back_populates="nutri_plan")


# Refeição dentro de um plano nutricional.
class Meal(Base):
    __tablename__ = "meals"

    id = Column(Integer, primary_key=True, index=True)
    nutri_plan_id = Column(Integer, ForeignKey("nutri_plans.id"), nullable=False)
    name = Column(String(100), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    food_items = relationship("FoodItem", back_populates="meal")
    nutri_plan = relationship("NutriPlan", back_populates="meals")


# Item alimentar associado a uma refeição do plano nutricional.
class FoodItem(Base):
    __tablename__ = "food_items"

    id = Column(Integer, primary_key=True, index=True)
    meal_id = Column(Integer, ForeignKey("meals.id"), nullable=False)
    name = Column(String(100), nullable=False)
    weight = Column(Float, nullable=False)
    calories = Column(Float, nullable=False)
    protein = Column(Float, nullable=False)
    carbs = Column(Float, nullable=False)
    fats = Column(Float, nullable=False)
    notes = Column(String(255), nullable=True)

    meal = relationship("Meal", back_populates="food_items")


# Mensagens enviadas entre utilizadores dentro da aplicação.
class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])

# Avalição de um cliente à sessao de treino, usada para feedback e melhoria contínua.
class ClientSessionFeedback(Base):
    __tablename__ = "client_session_feedback"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("training_sessions.id"), nullable=False)
    client_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    trainer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    rating = Column(Integer, nullable=False)  # Classificação de 1 a 5
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    session = relationship("TrainingSession", back_populates="feedback")
    client = relationship("User", foreign_keys=[client_id])
    trainer = relationship("User", foreign_keys=[trainer_id])

# Avaliação da performance do cliente durante a sessão de treino, usada para acompanhamento e ajustes futuros.
class SessionPerformance(Base):
    __tablename__ = "session_performance"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("training_sessions.id"), nullable=False)
    client_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    trainer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    performance_rating = Column(Integer, nullable=False)  # Classificação de 1 a 5
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    session = relationship("TrainingSession", back_populates="performance")
    client = relationship("User", foreign_keys=[client_id])
    trainer = relationship("User", foreign_keys=[trainer_id])

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(100), nullable=False)
    content = Column(Text, nullable=False)
    type = Column(String(50), nullable=False)
    read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="notifications")