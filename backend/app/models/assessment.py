import uuid
from datetime import datetime

from sqlalchemy import String, Float, DateTime, ForeignKey, Text, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class HealthAssessment(Base):
    __tablename__ = "health_assessments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)

    # Image analysis results
    image_path: Mapped[str] = mapped_column(String(500), nullable=False)
    image_type: Mapped[str] = mapped_column(String(50), nullable=False)  # "front", "side", "back"

    # AI-estimated body metrics
    estimated_body_fat_pct: Mapped[float | None] = mapped_column(Float, nullable=True)
    estimated_bmi: Mapped[float | None] = mapped_column(Float, nullable=True)
    body_type: Mapped[str | None] = mapped_column(String(50), nullable=True)
    # "ectomorph", "mesomorph", "endomorph"
    posture_analysis: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # {"forward_head": true, "rounded_shoulders": true, "anterior_pelvic_tilt": false}
    muscle_assessment: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # {"upper_body": "underdeveloped", "core": "weak", "lower_body": "average"}
    fat_distribution: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # {"abdominal": "high", "arms": "moderate", "thighs": "moderate"}

    # Skin & hair (from face/selfie image)
    skin_assessment: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # {"tone": "uneven", "acne": true, "dark_circles": true, "dullness": true}
    hair_assessment: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # {"thinning": true, "receding_hairline": false, "dandruff_visible": false}

    # Overall health score
    overall_score: Mapped[float | None] = mapped_column(Float, nullable=True)  # 0-100
    ai_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_recommendations: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    # Raw AI response for reference
    raw_ai_response: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="assessments")
