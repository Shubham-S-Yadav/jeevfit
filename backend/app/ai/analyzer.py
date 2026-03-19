"""
AI-powered health image analyzer using Google Gemini API.
Analyzes body composition, posture, skin, and hair from user photos.
"""
import json
import logging
from pathlib import Path

from google.genai import types

from app.config import get_settings
from app.ai import get_gemini_client

logger = logging.getLogger(__name__)
settings = get_settings()


BODY_ANALYSIS_PROMPT = """You are an expert fitness coach and health analyst. Analyze this photo of a person and provide a detailed health assessment.

IMPORTANT: Be honest but constructive. This analysis will be used to create a personalized health plan for an Indian user.

Analyze and return a JSON object with EXACTLY this structure (no markdown, just raw JSON):
{
    "estimated_body_fat_pct": <number 5-50, your best estimate>,
    "body_type": "<ectomorph|mesomorph|endomorph|ecto-mesomorph|endo-mesomorph>",
    "posture_analysis": {
        "forward_head": <true|false>,
        "rounded_shoulders": <true|false>,
        "anterior_pelvic_tilt": <true|false>,
        "kyphosis": <true|false>,
        "scoliosis_signs": <true|false>,
        "overall_posture": "<good|fair|poor>",
        "notes": "<brief posture notes>"
    },
    "muscle_assessment": {
        "upper_body": "<underdeveloped|average|well_developed>",
        "core": "<weak|average|strong>",
        "lower_body": "<underdeveloped|average|well_developed>",
        "muscle_symmetry": "<symmetric|slight_imbalance|notable_imbalance>",
        "notes": "<brief muscle notes>"
    },
    "fat_distribution": {
        "abdominal": "<low|moderate|high>",
        "chest": "<low|moderate|high>",
        "arms": "<low|moderate|high>",
        "thighs": "<low|moderate|high>",
        "face": "<low|moderate|high>",
        "pattern": "<android|gynoid|mixed>"
    },
    "skin_assessment": {
        "visible_concerns": ["<acne|dark_circles|pigmentation|dullness|dryness|none>"],
        "overall": "<healthy|needs_attention|concerning>"
    },
    "hair_assessment": {
        "visible_concerns": ["<thinning|receding|dandruff|dryness|premature_greying|none>"],
        "overall": "<healthy|needs_attention|concerning>"
    },
    "overall_health_score": <number 1-100>,
    "summary": "<2-3 sentence overall assessment>",
    "top_recommendations": [
        "<recommendation 1>",
        "<recommendation 2>",
        "<recommendation 3>",
        "<recommendation 4>",
        "<recommendation 5>"
    ]
}

Be realistic and evidence-based. If you cannot determine something from the image, make your best estimate and note the uncertainty.
"""


async def analyze_health_image(image_path: str, image_type: str = "front") -> dict:
    """Analyze a health/body image using Gemini Vision API."""
    client = get_gemini_client()

    image_data = Path(image_path).read_bytes()

    mime_type = "image/jpeg"
    if image_path.lower().endswith(".png"):
        mime_type = "image/png"

    context = f"This is a {image_type} view photo for health assessment."
    prompt = f"{context}\n\n{BODY_ANALYSIS_PROMPT}"

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL,
        contents=[
            types.Content(
                role="user",
                parts=[
                    types.Part.from_text(text=prompt),
                    types.Part.from_bytes(data=image_data, mime_type=mime_type),
                ],
            )
        ],
        config=types.GenerateContentConfig(
            temperature=0.3,
            max_output_tokens=2000,
        ),
    )

    response_text = response.text.strip()
    # Strip markdown code fences if present
    if response_text.startswith("```"):
        response_text = response_text.split("\n", 1)[1]
        if response_text.endswith("```"):
            response_text = response_text[:-3]
        response_text = response_text.strip()

    try:
        result = json.loads(response_text)
    except json.JSONDecodeError:
        logger.error(f"Failed to parse AI response: {response_text[:500]}")
        result = {
            "overall_health_score": 50,
            "summary": "Unable to fully analyze the image. Please upload a clearer photo.",
            "raw_response": response_text,
        }

    return result
