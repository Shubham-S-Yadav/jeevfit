import uuid
from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import String, Float, Integer, DateTime, ForeignKey, Text, func, Enum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Gender(str, PyEnum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


class ActivityLevel(str, PyEnum):
    SEDENTARY = "sedentary"           # Desk job, no exercise
    LIGHTLY_ACTIVE = "lightly_active"  # Light exercise 1-3 days/week
    MODERATELY_ACTIVE = "moderately_active"  # Moderate exercise 3-5 days/week
    VERY_ACTIVE = "very_active"        # Hard exercise 6-7 days/week
    EXTREMELY_ACTIVE = "extremely_active"  # Physical job + exercise


class FitnessGoal(str, PyEnum):
    FAT_LOSS = "fat_loss"
    MUSCLE_GAIN = "muscle_gain"
    MAINTENANCE = "maintenance"
    GENERAL_HEALTH = "general_health"
    STRESS_REDUCTION = "stress_reduction"
    BETTER_SLEEP = "better_sleep"
    SKIN_HAIR = "skin_hair"


class DietaryPreference(str, PyEnum):
    VEGETARIAN = "vegetarian"
    NON_VEGETARIAN = "non_vegetarian"
    VEGAN = "vegan"
    EGGETARIAN = "eggetarian"
    JAIN = "jain"


class ExerciseLocation(str, PyEnum):
    HOME = "home"
    GYM = "gym"
    BOTH = "both"
    OUTDOOR = "outdoor"


class Region(str, PyEnum):
    NORTH_INDIA = "north_india"
    SOUTH_INDIA = "south_india"
    EAST_INDIA = "east_india"
    WEST_INDIA = "west_india"
    NORTHEAST_INDIA = "northeast_india"
    PAN_INDIA = "pan_india"


class HealthProfile(Base):
    __tablename__ = "health_profiles"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), unique=True, nullable=False)

    # Demographics
    age: Mapped[int] = mapped_column(Integer, nullable=False)
    gender: Mapped[str] = mapped_column(Enum(Gender), nullable=False)
    height_cm: Mapped[float] = mapped_column(Float, nullable=False)
    weight_kg: Mapped[float] = mapped_column(Float, nullable=False)
    region: Mapped[str] = mapped_column(Enum(Region), default=Region.PAN_INDIA)

    # Profession & Lifestyle
    profession: Mapped[str] = mapped_column(String(255), nullable=False)
    work_hours: Mapped[str] = mapped_column(String(100), nullable=True)  # e.g., "9:00-18:00"
    activity_level: Mapped[str] = mapped_column(Enum(ActivityLevel), nullable=False)

    # Sleep schedule
    preferred_sleep_time: Mapped[str | None] = mapped_column(String(10), nullable=True)  # e.g., "23:00"
    preferred_wake_time: Mapped[str | None] = mapped_column(String(10), nullable=True)  # e.g., "06:30"
    current_sleep_hours: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Diet preferences
    dietary_preference: Mapped[str] = mapped_column(Enum(DietaryPreference), nullable=False)
    food_allergies: Mapped[dict | None] = mapped_column(JSONB, nullable=True)  # ["peanuts", "lactose"]
    foods_cant_eat: Mapped[dict | None] = mapped_column(JSONB, nullable=True)  # Foods user cannot/will not eat
    foods_prefer: Mapped[dict | None] = mapped_column(JSONB, nullable=True)  # Preferred foods
    meals_per_day: Mapped[int] = mapped_column(Integer, default=3)
    can_meal_prep: Mapped[bool] = mapped_column(default=False)
    monthly_food_budget: Mapped[float | None] = mapped_column(Float, nullable=True)  # INR

    # Current daily diet
    current_diet: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # Example: {"breakfast": "2 paratha + chai", "lunch": "rice + dal + sabzi", ...}

    # Exercise preferences
    exercise_location: Mapped[str] = mapped_column(Enum(ExerciseLocation), default=ExerciseLocation.HOME)
    available_equipment: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # ["dumbbells", "resistance_bands", "pull_up_bar", "yoga_mat"]
    exercise_time_minutes: Mapped[int] = mapped_column(Integer, default=30)
    exercise_days_per_week: Mapped[int] = mapped_column(Integer, default=3)
    exercise_experience: Mapped[str] = mapped_column(String(50), default="beginner")
    # "beginner", "intermediate", "advanced"

    # Health goals (multiple allowed)
    fitness_goals: Mapped[dict | None] = mapped_column(JSONB, nullable=True)  # List of FitnessGoal values
    specific_concerns: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # ["hair_fall", "acne", "low_energy", "poor_sleep", "stress", "low_libido"]

    # Medical history
    medical_conditions: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # ["diabetes", "thyroid", "pcos", "hypertension"]
    current_medications: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    injuries: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    # Stress & lifestyle
    stress_level: Mapped[int | None] = mapped_column(Integer, nullable=True)  # 1-10
    water_intake_liters: Mapped[float | None] = mapped_column(Float, nullable=True)
    smoking: Mapped[bool] = mapped_column(default=False)
    alcohol: Mapped[str | None] = mapped_column(String(50), nullable=True)  # "none", "occasional", "regular"
    screen_time_hours: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Adherence capacity
    diet_adherence_level: Mapped[int] = mapped_column(Integer, default=5)  # 1-10: how strictly can they follow diet
    exercise_adherence_level: Mapped[int] = mapped_column(Integer, default=5)  # 1-10

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="health_profile")
