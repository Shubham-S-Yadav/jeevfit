import os
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.database import get_db
from app.models.user import User
from app.models.assessment import HealthAssessment
from app.schemas.assessment import AssessmentResponse
from app.services.auth import get_current_user
from app.ai.analyzer import analyze_health_image

settings = get_settings()
router = APIRouter(prefix="/assessment", tags=["Health Assessment"])


@router.post("/analyze", response_model=AssessmentResponse, status_code=201)
async def analyze_image(
    image: UploadFile = File(...),
    image_type: str = Form(default="front"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if image_type not in ("front", "side", "back", "face"):
        raise HTTPException(status_code=400, detail="image_type must be front, side, back, or face")

    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    content = await image.read()
    size_mb = len(content) / (1024 * 1024)
    if size_mb > settings.MAX_IMAGE_SIZE_MB:
        raise HTTPException(status_code=400, detail=f"Image too large. Max {settings.MAX_IMAGE_SIZE_MB}MB")

    upload_dir = Path(settings.UPLOAD_DIR) / str(user.id)
    upload_dir.mkdir(parents=True, exist_ok=True)

    ext = image.filename.rsplit(".", 1)[-1] if image.filename and "." in image.filename else "jpg"
    filename = f"{uuid.uuid4()}.{ext}"
    file_path = upload_dir / filename

    with open(file_path, "wb") as f:
        f.write(content)

    try:
        analysis = await analyze_health_image(str(file_path), image_type)
    except Exception as e:
        os.unlink(file_path)
        raise HTTPException(status_code=500, detail=f"Image analysis failed: {str(e)}")

    assessment = HealthAssessment(
        user_id=user.id,
        image_path=str(file_path),
        image_type=image_type,
        estimated_body_fat_pct=analysis.get("estimated_body_fat_pct"),
        estimated_bmi=analysis.get("estimated_bmi"),
        body_type=analysis.get("body_type"),
        posture_analysis=analysis.get("posture_analysis"),
        muscle_assessment=analysis.get("muscle_assessment"),
        fat_distribution=analysis.get("fat_distribution"),
        skin_assessment=analysis.get("skin_assessment"),
        hair_assessment=analysis.get("hair_assessment"),
        overall_score=analysis.get("overall_health_score"),
        ai_summary=analysis.get("summary"),
        ai_recommendations=analysis.get("top_recommendations"),
        raw_ai_response=analysis,
    )
    db.add(assessment)
    await db.flush()
    await db.refresh(assessment)

    return AssessmentResponse.model_validate(assessment)


@router.get("/latest", response_model=AssessmentResponse)
async def get_latest_assessment(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(HealthAssessment)
        .where(HealthAssessment.user_id == user.id)
        .order_by(HealthAssessment.created_at.desc())
        .limit(1)
    )
    assessment = result.scalar_one_or_none()
    if not assessment:
        raise HTTPException(status_code=404, detail="No assessment found. Upload a photo first.")
    return AssessmentResponse.model_validate(assessment)


@router.get("/history", response_model=list[AssessmentResponse])
async def get_assessment_history(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(HealthAssessment)
        .where(HealthAssessment.user_id == user.id)
        .order_by(HealthAssessment.created_at.desc())
        .limit(20)
    )
    return [AssessmentResponse.model_validate(a) for a in result.scalars().all()]
