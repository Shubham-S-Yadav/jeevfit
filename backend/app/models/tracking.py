import uuid
from datetime import datetime, date

from sqlalchemy import String, Float, Integer, DateTime, Date, ForeignKey, Text, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class MealLog(Base):
    __tablename__ = "meal_logs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    log_date: Mapped[date] = mapped_column(Date, nullable=False)
    meal_type: Mapped[str] = mapped_column(String(50), nullable=False)
    # "early_morning", "breakfast", "mid_morning_snack", "lunch", "evening_snack", "dinner", "before_bed"
    items: Mapped[dict] = mapped_column(JSONB, nullable=False)
    # [{"name": "Poha", "qty": "1 plate", "calories": 250, "protein": 5, "carbs": 45, "fat": 5}]
    total_calories: Mapped[int | None] = mapped_column(Integer, nullable=True)
    followed_plan: Mapped[bool | None] = mapped_column(default=None)  # Did they follow the diet plan?
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="meal_logs")


class ExerciseLog(Base):
    __tablename__ = "exercise_logs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    log_date: Mapped[date] = mapped_column(Date, nullable=False)
    exercise_type: Mapped[str] = mapped_column(String(100), nullable=False)
    # "strength", "cardio", "yoga", "stretching", "hiit"
    exercises: Mapped[dict] = mapped_column(JSONB, nullable=False)
    # [{"name": "Push-ups", "sets": 3, "reps": [12, 10, 8], "weight_kg": null}]
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    calories_burned: Mapped[int | None] = mapped_column(Integer, nullable=True)
    followed_plan: Mapped[bool | None] = mapped_column(default=None)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="exercise_logs")


class ProgressEntry(Base):
    __tablename__ = "progress_entries"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    entry_date: Mapped[date] = mapped_column(Date, nullable=False)

    # Body measurements
    weight_kg: Mapped[float | None] = mapped_column(Float, nullable=True)
    body_fat_pct: Mapped[float | None] = mapped_column(Float, nullable=True)
    waist_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    chest_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    hip_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    arm_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    thigh_cm: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Lifestyle metrics
    sleep_hours: Mapped[float | None] = mapped_column(Float, nullable=True)
    sleep_quality: Mapped[int | None] = mapped_column(Integer, nullable=True)  # 1-10
    stress_level: Mapped[int | None] = mapped_column(Integer, nullable=True)  # 1-10
    energy_level: Mapped[int | None] = mapped_column(Integer, nullable=True)  # 1-10
    mood: Mapped[int | None] = mapped_column(Integer, nullable=True)  # 1-10
    water_liters: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Appearance
    skin_rating: Mapped[int | None] = mapped_column(Integer, nullable=True)  # 1-10
    hair_rating: Mapped[int | None] = mapped_column(Integer, nullable=True)  # 1-10

    # Photos
    photo_front: Mapped[str | None] = mapped_column(String(500), nullable=True)
    photo_side: Mapped[str | None] = mapped_column(String(500), nullable=True)

    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="progress_entries")
