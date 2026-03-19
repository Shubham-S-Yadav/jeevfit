"""
AI module - shared Gemini client factory.
Supports both API key and Vertex AI authentication.
"""
import logging

from google import genai

from app.config import get_settings

logger = logging.getLogger(__name__)

_client: genai.Client | None = None


def get_gemini_client() -> genai.Client:
    """
    Create and cache a Gemini client based on configuration.

    Supports two providers:
      - "api_key": Uses GEMINI_API_KEY (free tier / AI Studio)
      - "vertex":  Uses Vertex AI with GCP project + Application Default Credentials

    Set GEMINI_PROVIDER in .env to switch between them.
    """
    global _client
    if _client is not None:
        return _client

    settings = get_settings()
    provider = settings.GEMINI_PROVIDER.lower().strip()

    if provider == "vertex":
        if not settings.GEMINI_VERTEX_PROJECT:
            raise ValueError(
                "GEMINI_VERTEX_PROJECT is required when GEMINI_PROVIDER=vertex. "
                "Set it in your .env file."
            )
        _client = genai.Client(
            vertexai=True,
            project=settings.GEMINI_VERTEX_PROJECT,
            location=settings.GEMINI_VERTEX_LOCATION,
        )
        logger.info(
            f"Gemini client initialized via Vertex AI "
            f"(project={settings.GEMINI_VERTEX_PROJECT}, location={settings.GEMINI_VERTEX_LOCATION})"
        )
    elif provider == "api_key":
        if not settings.GEMINI_API_KEY:
            raise ValueError(
                "GEMINI_API_KEY is required when GEMINI_PROVIDER=api_key. "
                "Get a free key at https://aistudio.google.com/apikey"
            )
        _client = genai.Client(api_key=settings.GEMINI_API_KEY)
        logger.info("Gemini client initialized via API key")
    else:
        raise ValueError(
            f"Invalid GEMINI_PROVIDER='{provider}'. Must be 'api_key' or 'vertex'."
        )

    return _client


def reset_client():
    """Reset cached client (useful for testing or config changes)."""
    global _client
    _client = None
