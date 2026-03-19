from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.health_profile import HealthProfile
from app.models.assessment import HealthAssessment
from app.models.plan import DietPlan, ExercisePlan, Timetable
from app.schemas.plan import (
    DietPlanResponse, ExercisePlanResponse, TimetableResponse, GeneratePlanRequest
)
from app.services.auth import get_current_user
from pydantic import BaseModel as PydanticBaseModel
from app.ai.plan_generator import generate_diet_plan, generate_exercise_plan, generate_timetable, generate_meal_alternative

router = APIRouter(prefix="/plans", tags=["Health Plans"])


async def _get_user_data(user: User, db: AsyncSession) -> tuple[dict, dict | None]:
    """Get user profile and latest assessment data."""
    result = await db.execute(
        select(HealthProfile).where(HealthProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=400, detail="Complete your health profile first")

    # Convert profile to dict
    profile_dict = {
        "full_name": user.full_name,
        "age": profile.age,
        "gender": profile.gender,
        "height_cm": profile.height_cm,
        "weight_kg": profile.weight_kg,
        "region": profile.region,
        "profession": profile.profession,
        "work_hours": profile.work_hours,
        "activity_level": profile.activity_level,
        "preferred_sleep_time": profile.preferred_sleep_time,
        "preferred_wake_time": profile.preferred_wake_time,
        "current_sleep_hours": profile.current_sleep_hours,
        "dietary_preference": profile.dietary_preference,
        "food_allergies": profile.food_allergies,
        "foods_cant_eat": profile.foods_cant_eat,
        "foods_prefer": profile.foods_prefer,
        "meals_per_day": profile.meals_per_day,
        "can_meal_prep": profile.can_meal_prep,
        "monthly_food_budget": profile.monthly_food_budget,
        "current_diet": profile.current_diet,
        "exercise_location": profile.exercise_location,
        "available_equipment": profile.available_equipment,
        "exercise_time_minutes": profile.exercise_time_minutes,
        "exercise_days_per_week": profile.exercise_days_per_week,
        "exercise_experience": profile.exercise_experience,
        "fitness_goals": profile.fitness_goals,
        "specific_concerns": profile.specific_concerns,
        "medical_conditions": profile.medical_conditions,
        "current_medications": profile.current_medications,
        "injuries": profile.injuries,
        "stress_level": profile.stress_level,
        "water_intake_liters": profile.water_intake_liters,
        "smoking": profile.smoking,
        "alcohol": profile.alcohol,
        "screen_time_hours": profile.screen_time_hours,
        "diet_adherence_level": profile.diet_adherence_level,
        "exercise_adherence_level": profile.exercise_adherence_level,
    }

    # Get latest assessment
    result = await db.execute(
        select(HealthAssessment)
        .where(HealthAssessment.user_id == user.id)
        .order_by(HealthAssessment.created_at.desc())
        .limit(1)
    )
    assessment_obj = result.scalar_one_or_none()
    assessment_dict = None
    if assessment_obj:
        assessment_dict = {
            "estimated_body_fat_pct": assessment_obj.estimated_body_fat_pct,
            "body_type": assessment_obj.body_type,
            "posture_analysis": assessment_obj.posture_analysis,
            "muscle_assessment": assessment_obj.muscle_assessment,
            "fat_distribution": assessment_obj.fat_distribution,
            "skin_assessment": assessment_obj.skin_assessment,
            "hair_assessment": assessment_obj.hair_assessment,
            "overall_health_score": assessment_obj.overall_score,
            "summary": assessment_obj.ai_summary,
        }

    return profile_dict, assessment_dict


# ======================== DIET PLANS ========================

@router.post("/diet/generate", response_model=DietPlanResponse, status_code=201)
async def create_diet_plan(
    request: GeneratePlanRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile_dict, assessment_dict = await _get_user_data(user, db)

    # Deactivate previous plans
    result = await db.execute(
        select(DietPlan).where(DietPlan.user_id == user.id, DietPlan.is_active == True)
    )
    for old_plan in result.scalars().all():
        old_plan.is_active = False

    plan_data = await generate_diet_plan(profile_dict, assessment_dict, request.plan_type)

    days = 7 if request.plan_type == "weekly" else 30
    plan = DietPlan(
        user_id=user.id,
        plan_name=plan_data.get("plan_name", f"{request.plan_type.title()} Diet Plan"),
        plan_type=request.plan_type,
        start_date=date.today(),
        end_date=date.today() + timedelta(days=days),
        daily_calories=plan_data.get("daily_calories", 2000),
        protein_g=plan_data.get("protein_g", 80),
        carbs_g=plan_data.get("carbs_g", 250),
        fat_g=plan_data.get("fat_g", 60),
        fiber_g=plan_data.get("fiber_g", 30),
        meal_plan=plan_data.get("meal_plan", {}),
        supplements=plan_data.get("supplements"),
        foods_to_emphasize=plan_data.get("foods_to_emphasize"),
        foods_to_avoid=plan_data.get("foods_to_avoid"),
        research_references=plan_data.get("research_references"),
        goal_specific_notes=plan_data.get("goal_specific_notes"),
        ai_model_used="gemini-2.0-flash",
    )
    db.add(plan)
    await db.flush()
    await db.refresh(plan)

    return DietPlanResponse.model_validate(plan)


@router.get("/diet/active", response_model=DietPlanResponse)
async def get_active_diet_plan(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(DietPlan)
        .where(DietPlan.user_id == user.id, DietPlan.is_active == True)
        .order_by(DietPlan.created_at.desc())
        .limit(1)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="No active diet plan. Generate one first.")
    return DietPlanResponse.model_validate(plan)


@router.get("/diet/history", response_model=list[DietPlanResponse])
async def get_diet_plan_history(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(DietPlan)
        .where(DietPlan.user_id == user.id)
        .order_by(DietPlan.created_at.desc())
        .limit(10)
    )
    return [DietPlanResponse.model_validate(p) for p in result.scalars().all()]


# ======================== EXERCISE PLANS ========================

@router.post("/exercise/generate", response_model=ExercisePlanResponse, status_code=201)
async def create_exercise_plan(
    request: GeneratePlanRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile_dict, assessment_dict = await _get_user_data(user, db)

    result = await db.execute(
        select(ExercisePlan).where(ExercisePlan.user_id == user.id, ExercisePlan.is_active == True)
    )
    for old_plan in result.scalars().all():
        old_plan.is_active = False

    plan_data = await generate_exercise_plan(profile_dict, assessment_dict, request.plan_type)

    days = 7 if request.plan_type == "weekly" else 30
    plan = ExercisePlan(
        user_id=user.id,
        plan_name=plan_data.get("plan_name", f"{request.plan_type.title()} Exercise Plan"),
        plan_type=request.plan_type,
        start_date=date.today(),
        end_date=date.today() + timedelta(days=days),
        location=plan_data.get("location", "home"),
        difficulty=plan_data.get("difficulty", "beginner"),
        duration_minutes=plan_data.get("duration_minutes", 30),
        days_per_week=plan_data.get("days_per_week", 3),
        workout_plan=plan_data.get("workout_plan", {}),
        yoga_plan=plan_data.get("yoga_plan"),
        progression=plan_data.get("progression"),
        goal_specific_notes=plan_data.get("goal_specific_notes"),
        research_references=plan_data.get("research_references"),
    )
    db.add(plan)
    await db.flush()
    await db.refresh(plan)

    return ExercisePlanResponse.model_validate(plan)


@router.get("/exercise/active", response_model=ExercisePlanResponse)
async def get_active_exercise_plan(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(ExercisePlan)
        .where(ExercisePlan.user_id == user.id, ExercisePlan.is_active == True)
        .order_by(ExercisePlan.created_at.desc())
        .limit(1)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="No active exercise plan. Generate one first.")
    return ExercisePlanResponse.model_validate(plan)


# ======================== TIMETABLE ========================

@router.post("/timetable/generate", response_model=TimetableResponse, status_code=201)
async def create_timetable(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile_dict, assessment_dict = await _get_user_data(user, db)

    result = await db.execute(
        select(Timetable).where(Timetable.user_id == user.id, Timetable.is_active == True)
    )
    for old in result.scalars().all():
        old.is_active = False

    timetable_data = await generate_timetable(profile_dict, assessment_dict)

    timetable = Timetable(
        user_id=user.id,
        plan_name=timetable_data.get("plan_name", "Daily Routine"),
        schedule=timetable_data.get("schedule", {}),
        weekly_goals=timetable_data.get("weekly_goals"),
        monthly_goals=timetable_data.get("monthly_goals"),
    )
    db.add(timetable)
    await db.flush()
    await db.refresh(timetable)

    return TimetableResponse.model_validate(timetable)


@router.get("/timetable/active", response_model=TimetableResponse)
async def get_active_timetable(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Timetable)
        .where(Timetable.user_id == user.id, Timetable.is_active == True)
        .order_by(Timetable.created_at.desc())
        .limit(1)
    )
    timetable = result.scalar_one_or_none()
    if not timetable:
        raise HTTPException(status_code=404, detail="No active timetable. Generate one first.")
    return TimetableResponse.model_validate(timetable)


# ======================== MEAL ALTERNATIVES ========================

class MealAlternativeRequest(PydanticBaseModel):
    meal_context: dict  # {day, meal_type, items, total_calories, ...}
    conversation: list[dict]  # [{role: "user"|"assistant", text: "..."}]


@router.post("/diet/alternative")
async def get_meal_alternative(
    request: MealAlternativeRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get AI-powered meal alternatives based on user's situation."""
    profile_dict, _ = await _get_user_data(user, db)
    result = await generate_meal_alternative(
        profile=profile_dict,
        meal_context=request.meal_context,
        conversation=request.conversation,
    )
    return result
