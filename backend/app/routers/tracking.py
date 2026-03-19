from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.tracking import MealLog, ExerciseLog, ProgressEntry
from app.schemas.plan import ProgressLogRequest
from app.services.auth import get_current_user

router = APIRouter(prefix="/tracking", tags=["Progress Tracking"])


# ======================== MEAL LOGGING ========================

class MealLogRequest:
    pass


from pydantic import BaseModel


class MealLogCreate(BaseModel):
    meal_type: str
    items: list[dict]
    total_calories: int | None = None
    followed_plan: bool | None = None
    notes: str | None = None


class MealLogResponse(BaseModel):
    id: str
    log_date: date
    meal_type: str
    items: list[dict]
    total_calories: int | None
    followed_plan: bool | None
    notes: str | None

    model_config = {"from_attributes": True}


class ExerciseLogCreate(BaseModel):
    exercise_type: str
    exercises: list[dict]
    duration_minutes: int
    calories_burned: int | None = None
    followed_plan: bool | None = None
    notes: str | None = None


class ExerciseLogResponse(BaseModel):
    id: str
    log_date: date
    exercise_type: str
    exercises: list[dict]
    duration_minutes: int
    calories_burned: int | None
    followed_plan: bool | None

    model_config = {"from_attributes": True}


class ProgressResponse(BaseModel):
    id: str
    entry_date: date
    weight_kg: float | None
    body_fat_pct: float | None
    waist_cm: float | None
    sleep_hours: float | None
    sleep_quality: int | None
    stress_level: int | None
    energy_level: int | None
    mood: int | None
    water_liters: float | None
    skin_rating: int | None
    hair_rating: int | None

    model_config = {"from_attributes": True}


class DashboardResponse(BaseModel):
    total_days_tracked: int
    current_streak: int
    avg_calories: float | None
    avg_sleep: float | None
    avg_stress: float | None
    avg_energy: float | None
    weight_change: float | None
    meals_on_plan_pct: float | None
    exercises_on_plan_pct: float | None


@router.post("/meals", response_model=MealLogResponse, status_code=201)
async def log_meal(
    data: MealLogCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    log = MealLog(
        user_id=user.id,
        log_date=date.today(),
        meal_type=data.meal_type,
        items=data.items,
        total_calories=data.total_calories,
        followed_plan=data.followed_plan,
        notes=data.notes,
    )
    db.add(log)
    await db.flush()
    await db.refresh(log)
    return MealLogResponse(
        id=str(log.id),
        log_date=log.log_date,
        meal_type=log.meal_type,
        items=log.items,
        total_calories=log.total_calories,
        followed_plan=log.followed_plan,
        notes=log.notes,
    )


@router.get("/meals/today", response_model=list[MealLogResponse])
async def get_today_meals(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(MealLog)
        .where(MealLog.user_id == user.id, MealLog.log_date == date.today())
        .order_by(MealLog.created_at)
    )
    return [
        MealLogResponse(
            id=str(m.id), log_date=m.log_date, meal_type=m.meal_type,
            items=m.items, total_calories=m.total_calories,
            followed_plan=m.followed_plan, notes=m.notes,
        )
        for m in result.scalars().all()
    ]


# ======================== EXERCISE LOGGING ========================

@router.post("/exercises", response_model=ExerciseLogResponse, status_code=201)
async def log_exercise(
    data: ExerciseLogCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    log = ExerciseLog(
        user_id=user.id,
        log_date=date.today(),
        exercise_type=data.exercise_type,
        exercises=data.exercises,
        duration_minutes=data.duration_minutes,
        calories_burned=data.calories_burned,
        followed_plan=data.followed_plan,
        notes=data.notes,
    )
    db.add(log)
    await db.flush()
    await db.refresh(log)
    return ExerciseLogResponse(
        id=str(log.id), log_date=log.log_date, exercise_type=log.exercise_type,
        exercises=log.exercises, duration_minutes=log.duration_minutes,
        calories_burned=log.calories_burned, followed_plan=log.followed_plan,
    )


# ======================== PROGRESS TRACKING ========================

@router.post("/progress", response_model=ProgressResponse, status_code=201)
async def log_progress(
    data: ProgressLogRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Upsert for today
    result = await db.execute(
        select(ProgressEntry)
        .where(ProgressEntry.user_id == user.id, ProgressEntry.entry_date == date.today())
    )
    entry = result.scalar_one_or_none()

    if entry:
        for field, value in data.model_dump(exclude_unset=True).items():
            if value is not None:
                setattr(entry, field, value)
    else:
        entry = ProgressEntry(
            user_id=user.id,
            entry_date=date.today(),
            **data.model_dump(exclude_unset=True),
        )
        db.add(entry)

    await db.flush()
    await db.refresh(entry)

    return ProgressResponse(
        id=str(entry.id), entry_date=entry.entry_date,
        weight_kg=entry.weight_kg, body_fat_pct=entry.body_fat_pct,
        waist_cm=entry.waist_cm, sleep_hours=entry.sleep_hours,
        sleep_quality=entry.sleep_quality, stress_level=entry.stress_level,
        energy_level=entry.energy_level, mood=entry.mood,
        water_liters=entry.water_liters, skin_rating=entry.skin_rating,
        hair_rating=entry.hair_rating,
    )


@router.get("/progress/history", response_model=list[ProgressResponse])
async def get_progress_history(
    days: int = 30,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import timedelta
    start_date = date.today() - timedelta(days=days)
    result = await db.execute(
        select(ProgressEntry)
        .where(ProgressEntry.user_id == user.id, ProgressEntry.entry_date >= start_date)
        .order_by(ProgressEntry.entry_date.desc())
    )
    return [
        ProgressResponse(
            id=str(e.id), entry_date=e.entry_date,
            weight_kg=e.weight_kg, body_fat_pct=e.body_fat_pct,
            waist_cm=e.waist_cm, sleep_hours=e.sleep_hours,
            sleep_quality=e.sleep_quality, stress_level=e.stress_level,
            energy_level=e.energy_level, mood=e.mood,
            water_liters=e.water_liters, skin_rating=e.skin_rating,
            hair_rating=e.hair_rating,
        )
        for e in result.scalars().all()
    ]


# ======================== DASHBOARD ========================

@router.get("/dashboard", response_model=DashboardResponse)
async def get_dashboard(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import timedelta

    # Progress stats
    result = await db.execute(
        select(func.count(ProgressEntry.id))
        .where(ProgressEntry.user_id == user.id)
    )
    total_days = result.scalar() or 0

    # Average metrics from last 7 days
    week_ago = date.today() - timedelta(days=7)
    result = await db.execute(
        select(
            func.avg(ProgressEntry.sleep_hours),
            func.avg(ProgressEntry.stress_level),
            func.avg(ProgressEntry.energy_level),
        )
        .where(ProgressEntry.user_id == user.id, ProgressEntry.entry_date >= week_ago)
    )
    row = result.one_or_none()
    avg_sleep = float(row[0]) if row and row[0] else None
    avg_stress = float(row[1]) if row and row[1] else None
    avg_energy = float(row[2]) if row and row[2] else None

    # Weight change (last entry vs first entry)
    result = await db.execute(
        select(ProgressEntry.weight_kg)
        .where(ProgressEntry.user_id == user.id, ProgressEntry.weight_kg.isnot(None))
        .order_by(ProgressEntry.entry_date.asc())
        .limit(1)
    )
    first_weight = result.scalar_one_or_none()

    result = await db.execute(
        select(ProgressEntry.weight_kg)
        .where(ProgressEntry.user_id == user.id, ProgressEntry.weight_kg.isnot(None))
        .order_by(ProgressEntry.entry_date.desc())
        .limit(1)
    )
    last_weight = result.scalar_one_or_none()

    weight_change = (last_weight - first_weight) if first_weight and last_weight else None

    # Meal adherence
    result = await db.execute(
        select(func.count(MealLog.id))
        .where(MealLog.user_id == user.id, MealLog.followed_plan == True)
    )
    meals_on_plan = result.scalar() or 0

    result = await db.execute(
        select(func.count(MealLog.id))
        .where(MealLog.user_id == user.id, MealLog.followed_plan.isnot(None))
    )
    total_logged_meals = result.scalar() or 0

    meals_pct = (meals_on_plan / total_logged_meals * 100) if total_logged_meals > 0 else None

    # Avg calories
    result = await db.execute(
        select(func.avg(MealLog.total_calories))
        .where(MealLog.user_id == user.id, MealLog.log_date >= week_ago)
    )
    avg_calories = result.scalar()
    avg_calories = float(avg_calories) if avg_calories else None

    return DashboardResponse(
        total_days_tracked=total_days,
        current_streak=0,  # TODO: calculate streak
        avg_calories=avg_calories,
        avg_sleep=avg_sleep,
        avg_stress=avg_stress,
        avg_energy=avg_energy,
        weight_change=weight_change,
        meals_on_plan_pct=meals_pct,
        exercises_on_plan_pct=None,
    )
