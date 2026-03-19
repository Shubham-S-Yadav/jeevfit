# CLAUDE.md - JeevFit Project Context

## What is this project?

JeevFit is an AI-powered health & fitness app for Indian users. It uses Google Gemini to analyze body photos, generate personalized diet/exercise/lifestyle plans, and provides a research-backed knowledge base of Indian nutrition, supplements, yoga, pranayama, and sleep protocols.

## How to run

```bash
# Start databases
cd ~/hobby_projects/jeevfit && docker compose up -d db redis

# Start backend (in backend/ directory)
cd backend && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Start frontend (in frontend/jeevfit/ directory)
cd frontend/jeevfit && flutter run
```

**Backend:** http://localhost:8000 (Swagger docs at /docs)
**Database:** PostgreSQL on port 5433, Redis on port 6380
**Gemini API key** must be set in `backend/.env` as `GEMINI_API_KEY`

## Tech stack

- **Backend:** FastAPI (Python 3.13), SQLAlchemy async, PostgreSQL 16, Redis 7
- **Frontend:** Flutter 3.41+ (Dart), Riverpod, GoRouter, Dio
- **AI:** Google Gemini 2.0 Flash (Vision + Text generation)
- **Auth:** JWT (HS256) + bcrypt, tokens stored in Flutter SecureStorage

## Project structure

- `backend/app/ai/` - Gemini integration (analyzer.py for vision, plan_generator.py for plans)
- `backend/app/services/knowledge_service.py` - Singleton that loads 160KB of structured health data and provides filtered context to AI prompts
- `backend/app/routers/` - 6 routers, 31 endpoints total. Knowledge endpoints are public (no auth).
- `backend/app/data/parsed/` - 10 JSON files with supplements, exercises, yoga, pranayama, sleep, stress data
- `frontend/jeevfit/lib/screens/` - 16 screens across auth, onboarding, home (5 tabs), and library (5 screens)
- `frontend/jeevfit/lib/services/api_service.dart` - Singleton Dio client with auto JWT attachment

## Key architectural decisions

- **KnowledgeService** filters data by user profile (diet type, region, goals, conditions) and returns compact markdown strings (~3-5K tokens) for AI prompts instead of dumping all 54K tokens of raw data
- **Supplement safety**: Ashwagandha is excluded for users with thyroid/autoimmune conditions. Iron is only recommended with confirmed deficiency.
- **Knowledge API endpoints are public** (no auth) - they serve reference data, not user-specific data
- **bcrypt pinned to 4.0.1** due to passlib compatibility issues with newer versions
- **Docker ports are 5433/6380** (not default 5432/6379) to avoid conflicts with other projects on the machine

## Testing

```bash
cd backend && pytest tests/ -v
```

21 tests covering: BMI/BMR/TDEE calculations, macros, Indian foods database, food synergies, KnowledgeService loading, vegetarian filtering, supplement contraindications, regional diet data. Auth/config tests require FastAPI installed (they pass in Docker).

## Common patterns

- Backend routers use `Depends(get_current_user)` for authenticated endpoints
- Plans use `is_active` flag - generating a new plan deactivates the old one
- AI responses are parsed from JSON, with fallback error handling for malformed Gemini output
- Flutter screens are `ConsumerStatefulWidget` (Riverpod) with `ApiService()` singleton
- Onboarding collects 40+ fields across 8 steps, transforms display names to snake_case at submit time

## Things to watch out for

- The `_MultiChipField` widget in onboarding stores display names (e.g., "Fat Loss"), NOT snake_case. Transformation happens in `_submitProfile()`.
- Flutter 3.41 renamed `CardTheme` to `CardThemeData` - already updated in app_theme.dart
- `withOpacity` is deprecated in Flutter 3.41 in favor of `withValues()` - existing code has deprecation warnings but works fine
- The Gemini API key must be set in `.env` for plan generation to work. Without it, the app runs but plan generation fails.
