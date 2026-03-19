from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.health_profile import HealthProfile
from app.schemas.health_profile import HealthProfileCreate, HealthProfileUpdate, HealthProfileResponse
from app.services.auth import get_current_user

router = APIRouter(prefix="/profile", tags=["Health Profile"])


@router.post("/", response_model=HealthProfileResponse, status_code=201)
async def create_profile(
    data: HealthProfileCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(HealthProfile).where(HealthProfile.user_id == user.id)
    )
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Profile already exists. Use PUT to update.")

    profile = HealthProfile(user_id=user.id, **data.model_dump())
    db.add(profile)

    user.is_onboarded = True
    await db.flush()
    await db.refresh(profile)

    return HealthProfileResponse.model_validate(profile)


@router.get("/", response_model=HealthProfileResponse)
async def get_profile(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(HealthProfile).where(HealthProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found. Complete onboarding first.")
    return HealthProfileResponse.model_validate(profile)


@router.put("/", response_model=HealthProfileResponse)
async def update_profile(
    data: HealthProfileUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(HealthProfile).where(HealthProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(profile, field, value)

    await db.flush()
    await db.refresh(profile)
    return HealthProfileResponse.model_validate(profile)
