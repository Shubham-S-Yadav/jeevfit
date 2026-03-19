from typing import Any
from pydantic import BaseModel
from uuid import UUID
from datetime import datetime, date


class DietPlanResponse(BaseModel):
    id: UUID
    user_id: UUID
    plan_name: str
    plan_type: str
    start_date: date
    end_date: date
    is_active: bool
    daily_calories: int
    protein_g: int
    carbs_g: int
    fat_g: int
    fiber_g: int
    meal_plan: Any
    supplements: Any | None
    foods_to_emphasize: Any | None
    foods_to_avoid: Any | None
    research_references: Any | None
    goal_specific_notes: Any | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ExercisePlanResponse(BaseModel):
    id: UUID
    user_id: UUID
    plan_name: str
    plan_type: str
    start_date: date
    end_date: date
    is_active: bool
    location: str
    difficulty: str
    duration_minutes: int
    days_per_week: int
    workout_plan: Any
    yoga_plan: Any | None
    progression: Any | None
    goal_specific_notes: Any | None
    research_references: Any | None
    created_at: datetime

    model_config = {"from_attributes": True}


class TimetableResponse(BaseModel):
    id: UUID
    user_id: UUID
    plan_name: str
    is_active: bool
    schedule: dict
    weekly_goals: dict | None
    monthly_goals: dict | None
    created_at: datetime

    model_config = {"from_attributes": True}


class GeneratePlanRequest(BaseModel):
    plan_type: str = "weekly"  # "weekly" or "monthly"


class ProgressLogRequest(BaseModel):
    weight_kg: float | None = None
    body_fat_pct: float | None = None
    waist_cm: float | None = None
    chest_cm: float | None = None
    hip_cm: float | None = None
    arm_cm: float | None = None
    thigh_cm: float | None = None
    sleep_hours: float | None = None
    sleep_quality: int | None = None
    stress_level: int | None = None
    energy_level: int | None = None
    mood: int | None = None
    water_liters: float | None = None
    skin_rating: int | None = None
    hair_rating: int | None = None
    notes: str | None = None
