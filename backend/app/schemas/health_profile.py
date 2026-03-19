from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime


class HealthProfileCreate(BaseModel):
    # Demographics
    age: int = Field(ge=14, le=100)
    gender: str
    height_cm: float = Field(ge=100, le=250)
    weight_kg: float = Field(ge=30, le=300)
    region: str = "pan_india"

    # Profession & Lifestyle
    profession: str
    work_hours: str | None = None
    activity_level: str

    # Sleep
    preferred_sleep_time: str | None = None
    preferred_wake_time: str | None = None
    current_sleep_hours: float | None = None

    # Diet
    dietary_preference: str
    food_allergies: list[str] | None = None
    foods_cant_eat: list[str] | None = None
    foods_prefer: list[str] | None = None
    meals_per_day: int = Field(default=3, ge=2, le=7)
    can_meal_prep: bool = False
    monthly_food_budget: float | None = None

    # Current diet
    current_diet: dict | None = None

    # Exercise
    exercise_location: str = "home"
    available_equipment: list[str] | None = None
    exercise_time_minutes: int = Field(default=30, ge=10, le=180)
    exercise_days_per_week: int = Field(default=3, ge=1, le=7)
    exercise_experience: str = "beginner"

    # Goals
    fitness_goals: list[str] | None = None
    specific_concerns: list[str] | None = None

    # Medical
    medical_conditions: list[str] | None = None
    current_medications: list[str] | None = None
    injuries: list[str] | None = None

    # Lifestyle
    stress_level: int | None = Field(default=None, ge=1, le=10)
    water_intake_liters: float | None = None
    smoking: bool = False
    alcohol: str | None = "none"
    screen_time_hours: float | None = None

    # Adherence
    diet_adherence_level: int = Field(default=5, ge=1, le=10)
    exercise_adherence_level: int = Field(default=5, ge=1, le=10)


class HealthProfileUpdate(HealthProfileCreate):
    age: int | None = None
    gender: str | None = None
    height_cm: float | None = None
    weight_kg: float | None = None
    profession: str | None = None
    activity_level: str | None = None
    dietary_preference: str | None = None


class HealthProfileResponse(BaseModel):
    id: UUID
    user_id: UUID
    age: int
    gender: str
    height_cm: float
    weight_kg: float
    region: str
    profession: str
    work_hours: str | None = None
    activity_level: str
    preferred_sleep_time: str | None = None
    preferred_wake_time: str | None = None
    current_sleep_hours: float | None = None
    dietary_preference: str
    food_allergies: list[str] | None = None
    foods_cant_eat: list[str] | None = None
    foods_prefer: list[str] | None = None
    meals_per_day: int = 3
    can_meal_prep: bool = False
    monthly_food_budget: float | None = None
    current_diet: dict | None = None
    exercise_location: str = "home"
    available_equipment: list[str] | None = None
    exercise_time_minutes: int = 30
    exercise_days_per_week: int = 3
    exercise_experience: str = "beginner"
    fitness_goals: list[str] | None = None
    specific_concerns: list[str] | None = None
    medical_conditions: list[str] | None = None
    current_medications: list[str] | None = None
    injuries: list[str] | None = None
    stress_level: int | None = None
    water_intake_liters: float | None = None
    smoking: bool = False
    alcohol: str | None = "none"
    screen_time_hours: float | None = None
    diet_adherence_level: int = 5
    exercise_adherence_level: int = 5
    created_at: datetime

    model_config = {"from_attributes": True}
