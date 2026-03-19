from pydantic import BaseModel
from uuid import UUID
from datetime import datetime


class AssessmentResponse(BaseModel):
    id: UUID
    user_id: UUID
    image_type: str
    estimated_body_fat_pct: float | None
    estimated_bmi: float | None
    body_type: str | None
    posture_analysis: dict | None
    muscle_assessment: dict | None
    fat_distribution: dict | None
    skin_assessment: dict | None
    hair_assessment: dict | None
    overall_score: float | None
    ai_summary: str | None
    ai_recommendations: dict | None
    created_at: datetime

    model_config = {"from_attributes": True}
