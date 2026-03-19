import uuid
from datetime import datetime, date

from sqlalchemy import String, Integer, DateTime, Date, ForeignKey, Text, Boolean, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class DietPlan(Base):
    __tablename__ = "diet_plans"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)

    plan_name: Mapped[str] = mapped_column(String(255), nullable=False)
    plan_type: Mapped[str] = mapped_column(String(50), nullable=False)  # "weekly", "monthly"
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Nutritional targets
    daily_calories: Mapped[int] = mapped_column(Integer, nullable=False)
    protein_g: Mapped[int] = mapped_column(Integer, nullable=False)
    carbs_g: Mapped[int] = mapped_column(Integer, nullable=False)
    fat_g: Mapped[int] = mapped_column(Integer, nullable=False)
    fiber_g: Mapped[int] = mapped_column(Integer, nullable=False)

    # The actual meal plan - structured as JSON
    # {
    #   "monday": {
    #     "early_morning": {"time": "6:30", "items": [{"name": "warm lemon water", "qty": "1 glass", "calories": 10}]},
    #     "breakfast": {"time": "8:00", "items": [...]},
    #     "mid_morning_snack": {"time": "10:30", "items": [...]},
    #     "lunch": {"time": "13:00", "items": [...]},
    #     "evening_snack": {"time": "16:30", "items": [...]},
    #     "dinner": {"time": "20:00", "items": [...]},
    #     "before_bed": {"time": "22:00", "items": [...]}
    #   },
    #   ...
    # }
    meal_plan: Mapped[dict] = mapped_column(JSONB, nullable=False)

    # Supplements recommendation
    # [{"name": "Vitamin D3", "dosage": "2000 IU", "when": "morning with breakfast",
    #   "reason": "85% Indians are Vitamin D deficient (ICMR 2024)",
    #   "safety": "No side effects at recommended dose", "cost_inr": 300}]
    supplements: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    # Foods to emphasize and avoid
    foods_to_emphasize: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    foods_to_avoid: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    # Scientific backing
    research_references: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # [{"claim": "Turmeric reduces inflammation", "source": "PMID: 12345", "summary": "..."}]

    # Health goal specific notes
    goal_specific_notes: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    # AI generation metadata
    ai_model_used: Mapped[str | None] = mapped_column(String(100), nullable=True)
    generation_prompt_hash: Mapped[str | None] = mapped_column(String(64), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="diet_plans")


class ExercisePlan(Base):
    __tablename__ = "exercise_plans"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)

    plan_name: Mapped[str] = mapped_column(String(255), nullable=False)
    plan_type: Mapped[str] = mapped_column(String(50), nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    location: Mapped[str] = mapped_column(String(50), nullable=False)  # "home", "gym", "both"
    difficulty: Mapped[str] = mapped_column(String(50), nullable=False)  # "beginner", "intermediate", "advanced"
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    days_per_week: Mapped[int] = mapped_column(Integer, nullable=False)

    # The workout plan
    # {
    #   "monday": {
    #     "focus": "Upper Body Push",
    #     "warmup": [{"name": "Arm circles", "duration": "2 min"}],
    #     "exercises": [
    #       {"name": "Push-ups", "sets": 3, "reps": 12, "rest_sec": 60,
    #        "muscle_group": "chest", "video_url": null, "instructions": "...",
    #        "alternatives": ["Wall push-ups", "Knee push-ups"]}
    #     ],
    #     "cooldown": [{"name": "Chest stretch", "duration": "1 min"}],
    #     "total_duration_min": 30
    #   },
    #   ...
    # }
    workout_plan: Mapped[dict] = mapped_column(JSONB, nullable=False)

    # Yoga/meditation component
    yoga_plan: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    # Progressive overload plan
    progression: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    # Goal-specific exercise notes
    goal_specific_notes: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    research_references: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="exercise_plans")


class Timetable(Base):
    __tablename__ = "timetables"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)

    plan_name: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Full daily timetable
    # {
    #   "weekday": {
    #     "05:30": {"activity": "Wake up", "category": "routine"},
    #     "05:45": {"activity": "Oil pulling + tongue scraping", "category": "health"},
    #     "06:00": {"activity": "Warm lemon water + soaked almonds", "category": "diet"},
    #     "06:15": {"activity": "Morning walk / Surya Namaskar", "category": "exercise"},
    #     "07:00": {"activity": "Shower", "category": "routine"},
    #     "07:30": {"activity": "Breakfast", "category": "diet"},
    #     "08:30": {"activity": "Work starts", "category": "work"},
    #     "10:30": {"activity": "Mid-morning snack + water", "category": "diet"},
    #     "13:00": {"activity": "Lunch + 10 min walk", "category": "diet"},
    #     "15:00": {"activity": "Green tea + stretching", "category": "diet"},
    #     "17:00": {"activity": "Work ends", "category": "work"},
    #     "17:30": {"activity": "Gym / Home workout", "category": "exercise"},
    #     "19:00": {"activity": "Evening snack", "category": "diet"},
    #     "20:30": {"activity": "Dinner", "category": "diet"},
    #     "21:30": {"activity": "Screen off + reading / journaling", "category": "routine"},
    #     "22:00": {"activity": "Pranayama / meditation", "category": "health"},
    #     "22:30": {"activity": "Sleep", "category": "routine"}
    #   },
    #   "weekend": { ... }
    # }
    schedule: Mapped[dict] = mapped_column(JSONB, nullable=False)

    # Weekly goals
    weekly_goals: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    monthly_goals: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="timetables")
