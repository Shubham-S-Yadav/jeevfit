from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    APP_NAME: str = "JeevFit"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://jeevfit:jeevfit@localhost:5432/jeevfit"
    DATABASE_URL_SYNC: str = "postgresql://jeevfit:jeevfit@localhost:5432/jeevfit"

    # Auth
    SECRET_KEY: str = "change-this-in-production-use-openssl-rand-hex-32"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours

    # AI - Set GEMINI_PROVIDER to "api_key" or "vertex"
    GEMINI_PROVIDER: str = "api_key"  # "api_key" or "vertex"
    GEMINI_API_KEY: str = ""  # Required when GEMINI_PROVIDER=api_key
    GEMINI_VERTEX_PROJECT: str = ""  # Required when GEMINI_PROVIDER=vertex
    GEMINI_VERTEX_LOCATION: str = "us-central1"  # Vertex AI region
    GEMINI_MODEL: str = "gemini-2.0-flash"  # Model name (works for both providers)

    # Storage
    UPLOAD_DIR: str = "./uploads"
    MAX_IMAGE_SIZE_MB: int = 10

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # CORS
    CORS_ORIGINS: list[str] = ["*"]

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
