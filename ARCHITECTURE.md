# JeevFit - Architecture Document

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER (iPhone/Web)                        │
└─────────────────────────────┬───────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                    FLUTTER FRONTEND                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────────┐  │
│  │  Screens  │  │ Providers│  │  Router   │  │  API Service   │  │
│  │  (16)     │  │ (Riverpod│  │ (GoRouter)│  │  (Dio HTTP)    │  │
│  └──────────┘  └──────────┘  └──────────┘  └───────┬────────┘  │
└─────────────────────────────────────────────────────┼───────────┘
                                                      │ HTTP/JSON
┌─────────────────────────────────────────────────────▼───────────┐
│                    FASTAPI BACKEND (:8000)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────────┐  │
│  │  Routers  │  │ Services │  │    AI     │  │   Schemas      │  │
│  │  (6)      │  │  (2)     │  │  (2)     │  │   (Pydantic)   │  │
│  │  31 APIs  │  │ Auth     │  │ Analyzer │  │                │  │
│  │           │  │ Knowledge│  │ PlanGen  │  │                │  │
│  └─────┬────┘  └──────────┘  └────┬─────┘  └────────────────┘  │
│        │                          │                              │
│  ┌─────▼──────────────────────────▼─────────────────────────┐   │
│  │              SQLAlchemy ORM (7 Models)                    │   │
│  └─────────────────────────┬────────────────────────────────┘   │
└────────────────────────────┼────────────────────────────────────┘
                             │                          │
              ┌──────────────▼──────┐    ┌──────────────▼──────┐
              │  PostgreSQL 16      │    │   Google Gemini      │
              │  (:5433)            │    │   2.0 Flash API      │
              │  7 tables           │    │   Vision + Text      │
              └─────────────────────┘    └──────────────────────┘
                             │
              ┌──────────────▼──────┐
              │  Redis 7 (:6380)    │
              │  (Cache/Sessions)   │
              └─────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Frontend** | Flutter (Dart) | 3.41+ |
| **State Management** | Riverpod | 2.6.1 |
| **Navigation** | GoRouter | 14.6+ |
| **HTTP Client** | Dio | 5.7+ |
| **Backend** | FastAPI (Python) | 0.115+ |
| **ORM** | SQLAlchemy (async) | 2.0+ |
| **Database** | PostgreSQL | 16 |
| **Cache** | Redis | 7 |
| **AI** | Google Gemini | 2.0 Flash |
| **Auth** | JWT + bcrypt | HS256 |
| **Containers** | Docker Compose | v2 |

---

## Backend Architecture

### Layer Diagram

```
┌──────────────────────────────────────────────────┐
│                   Routers (API Layer)             │
│  auth.py │ profile.py │ assessment.py │ plans.py  │
│  tracking.py │ knowledge.py                       │
├──────────────────────────────────────────────────┤
│                 Services (Business Logic)          │
│  auth.py (JWT + password hashing)                 │
│  knowledge_service.py (data loading + filtering)  │
├──────────────────────────────────────────────────┤
│                   AI Module                        │
│  analyzer.py (Gemini Vision - body analysis)      │
│  plan_generator.py (Gemini Text - plan creation)  │
├──────────────────────────────────────────────────┤
│                 Models (ORM Layer)                 │
│  User │ HealthProfile │ HealthAssessment           │
│  DietPlan │ ExercisePlan │ Timetable              │
│  MealLog │ ExerciseLog │ ProgressEntry            │
├──────────────────────────────────────────────────┤
│                Schemas (Validation)                │
│  Pydantic models for request/response validation  │
├──────────────────────────────────────────────────┤
│              Data (Knowledge Base)                 │
│  indian_nutrition_knowledge_base.json (123KB)     │
│  parsed/*.json (10 files, 160KB)                  │
│  indian_foods.json (legacy, 10KB)                 │
└──────────────────────────────────────────────────┘
```

### API Endpoints (31 total)

| Group | Endpoints | Auth Required |
|-------|-----------|---------------|
| Auth | 3 (register, login, me) | No (register/login), Yes (me) |
| Profile | 3 (create, get, update) | Yes |
| Assessment | 3 (analyze, latest, history) | Yes |
| Diet Plans | 3 (generate, active, history) | Yes |
| Exercise Plans | 2 (generate, active) | Yes |
| Timetable | 2 (generate, active) | Yes |
| Tracking | 5 (meals, exercises, progress, dashboard) | Yes |
| Knowledge Base | 9 (foods, supplements, exercises, yoga, pranayama, sleep, synergies, tips, citations) | **No** |

### Database Schema

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────────┐
│    users     │────>│  health_profiles │     │health_assessments│
│              │     │                  │     │                  │
│  id (UUID)   │     │  age, gender     │     │  image_path      │
│  email       │     │  height, weight  │     │  body_fat_pct    │
│  password    │     │  region          │     │  body_type       │
│  full_name   │     │  diet_preference │     │  posture_analysis│
│  is_onboarded│     │  fitness_goals   │     │  overall_score   │
│  created_at  │     │  medical_conds   │     │  ai_summary      │
└──────┬───────┘     └──────────────────┘     └──────────────────┘
       │
       ├────────────>┌──────────────────┐
       │             │   diet_plans     │
       │             │                  │
       │             │  daily_calories  │
       │             │  protein/carbs/  │
       │             │  fat/fiber_g     │
       │             │  meal_plan (JSON)│  ← 7 days x 7 meals
       │             │  supplements     │
       │             │  is_active       │
       │             └──────────────────┘
       │
       ├────────────>┌──────────────────┐
       │             │  exercise_plans  │
       │             │                  │
       │             │  location        │
       │             │  difficulty      │
       │             │  workout_plan    │  ← 7 days with exercises
       │             │  yoga_plan       │
       │             │  progression     │
       │             └──────────────────┘
       │
       ├────────────>┌──────────────────┐
       │             │   timetables     │
       │             │                  │
       │             │  schedule (JSON) │  ← weekday + weekend
       │             │  weekly_goals    │
       │             │  monthly_goals   │
       │             └──────────────────┘
       │
       ├────────────>┌──────────────────┐
       │             │   meal_logs      │
       │             │  exercise_logs   │
       │             │  progress_entries│
       │             │                  │
       │             │  Tracking data   │
       │             │  with dates      │
       │             └──────────────────┘
```

All plan/tracking tables use **JSONB columns** for flexible nested data (meal items, exercise sets, body measurements).

---

## Frontend Architecture

### Screen Flow

```
App Launch
    │
    ▼
SplashScreen ──> Check Auth Token
    │                    │
    │              ┌─────▼─────┐
    │              │ Token      │
    │              │ exists?    │
    │              └─────┬─────┘
    │                No  │  Yes
    │                │   │
    ▼                ▼   ▼
LoginScreen    GET /auth/me
    │                │
    │          ┌─────▼──────┐
    │          │ is_onboarded│
    │          └─────┬──────┘
    │           No   │  Yes
    │           │    │
    │           ▼    ▼
    │     Onboarding  Dashboard
    │     (8 steps)      │
    │         │     ┌────┼────┬──────┬────────┐
    │         │     │    │    │      │        │
    │         ▼     ▼    ▼    ▼      ▼        ▼
    │      Dashboard Diet Exercise Timetable Profile
    │                │
    │         ┌──────┼───────┬──────────┬───────────┐
    │         ▼      ▼       ▼          ▼           ▼
    │      Exercises Supplements Foods Breathing  Sleep
    │      Library   Guide     DB    Screen     Guide
    │
    └──> RegisterScreen ──> LoginScreen
```

### State Management (Riverpod)

```
┌─────────────────────────────────────┐
│         AuthProvider                 │
│  StateNotifier<AuthData>             │
│                                      │
│  States:                             │
│    initial → loading → check token   │
│    unauthenticated → show login      │
│    onboarding → show onboarding      │
│    authenticated → show dashboard    │
│                                      │
│  Methods:                            │
│    login(email, password)            │
│    register(email, password, name)   │
│    logout()                          │
│    checkAuth()                       │
│    completeOnboarding()              │
└──────────────┬──────────────────────┘
               │ watches
┌──────────────▼──────────────────────┐
│         RouterProvider               │
│  GoRouter with redirect logic        │
│                                      │
│  Redirects based on AuthState:       │
│    initial/loading → /               │
│    unauthenticated → /login          │
│    onboarding → /onboarding          │
│    authenticated → /dashboard        │
└─────────────────────────────────────┘
```

### API Service (Singleton)

```dart
ApiService._internal() {
  _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8000/api/v1',
    connectTimeout: 30s,
    receiveTimeout: 60s,
  ));

  // Auto-attach JWT token to every request
  _dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await secureStorage.read('access_token');
      options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        secureStorage.delete('access_token');  // Force re-login
      }
      handler.next(error);
    },
  ));
}
```

---

## AI Architecture

### Knowledge Service (Singleton Pattern)

```
┌─────────────────────────────────────────────────┐
│              KnowledgeService                    │
│                                                  │
│  Loaded at startup (main.py lifespan):           │
│                                                  │
│  ┌─────────────────────────────────────────┐     │
│  │  indian_nutrition_knowledge_base.json   │     │
│  │  128 foods, ICMR RDA, regional diets   │     │
│  └─────────────────────────────────────────┘     │
│  ┌─────────────────────────────────────────┐     │
│  │  parsed/*.json (10 files)               │     │
│  │  supplements, exercises, yoga,          │     │
│  │  pranayama, sleep, stress, citations    │     │
│  └─────────────────────────────────────────┘     │
│                                                  │
│  Markdown Methods (for AI prompts):              │
│  ┌──────────────────────────────────────┐        │
│  │ get_foods_for_user(diet, region)     │→ ~800  │
│  │ get_rda_for_user(age, gender, act)   │→ ~400  │
│  │ get_supplements_for_user(goals,...)  │→ ~600  │
│  │ get_exercises_for_user(loc, exp,...) │→ ~500  │
│  │ get_food_synergies()                 │→ ~300  │
│  │ get_gi_data()  [conditional]         │→ ~400  │
│  │ get_deficiency_risks(diet, gender)   │→ ~200  │
│  │ get_regional_diet(region)            │→ ~300  │
│  └──────────────────────────────────────┘ tokens │
│                                                  │
│  Total per prompt: ~3000-5000 tokens             │
│  (vs 54K if dumping all raw data)                │
└─────────────────────────────────────────────────┘
```

### AI Plan Generation Flow

```
User Profile ──┐
               │
Assessment ────┤
               │
               ▼
   ┌───────────────────────┐
   │  KnowledgeService     │
   │                       │
   │  Filter by:           │
   │  - diet_type          │  "vegetarian user from South India
   │  - region             │   with fat_loss goal, no thyroid"
   │  - goals              │
   │  - conditions         │
   │  - experience         │
   └───────────┬───────────┘
               │ ~3000-5000 tokens
               │ of relevant context
               ▼
   ┌───────────────────────┐
   │  Gemini 2.0 Flash     │
   │                       │
   │  System: "You are     │
   │  India's top          │
   │  nutritionist..."     │
   │                       │
   │  Context:             │
   │  - Filtered foods     │
   │  - User-specific RDA  │
   │  - Safe supplements   │
   │  - Food synergies     │
   │  - Regional diet      │
   │                       │
   │  Output: Structured   │
   │  JSON (7-day plan)    │
   └───────────┬───────────┘
               │
               ▼
   ┌───────────────────────┐
   │  JSON Parse + Store   │
   │                       │
   │  - Validate response  │
   │  - Store in DietPlan  │
   │  - Deactivate old     │
   │  - Return to client   │
   └───────────────────────┘
```

### Token Budget Strategy

| Without KnowledgeService | With KnowledgeService |
|--------------------------|----------------------|
| Dump all 216KB raw data | Filter by user profile |
| ~54,000 tokens per prompt | ~3,000-5,000 tokens per prompt |
| Same context for every user | Vegetarian user = no non-veg foods |
| No regional awareness | South Indian user = idli/dosa context |
| All supplements always | Ashwagandha excluded for thyroid |
| GI data always included | GI data only for fat_loss/diabetes |

---

## Authentication Flow

```
┌──────────┐          ┌──────────┐          ┌──────────┐
│  Flutter  │          │  FastAPI  │          │  PostgreSQL│
└────┬─────┘          └────┬─────┘          └────┬─────┘
     │                     │                     │
     │ POST /auth/register │                     │
     │ {email, password,   │                     │
     │  full_name}         │                     │
     ├────────────────────>│                     │
     │                     │ hash(password)       │
     │                     │ INSERT user          │
     │                     ├────────────────────>│
     │                     │         OK           │
     │                     │<────────────────────┤
     │                     │ create_jwt(user_id)  │
     │   {access_token,    │                     │
     │    user}            │                     │
     │<────────────────────┤                     │
     │                     │                     │
     │ Store token in      │                     │
     │ SecureStorage       │                     │
     │                     │                     │
     │ GET /auth/me        │                     │
     │ Bearer: <token>     │                     │
     ├────────────────────>│                     │
     │                     │ decode_jwt(token)    │
     │                     │ SELECT user          │
     │                     ├────────────────────>│
     │                     │       user           │
     │                     │<────────────────────┤
     │   {user}            │                     │
     │<────────────────────┤                     │
     │                     │                     │
     │ if !is_onboarded:   │                     │
     │   → OnboardingScreen│                     │
     │ else:               │                     │
     │   → DashboardScreen │                     │
```

---

## Data Flow: Full User Journey

```
1. REGISTER
   User → POST /auth/register → Create User → JWT Token → SecureStorage

2. ONBOARDING (8 steps)
   User fills 40+ fields → POST /profile/ → Create HealthProfile
   → Set is_onboarded=true → Redirect to Dashboard

3. BODY ASSESSMENT (optional)
   User takes photo → POST /assessment/analyze → Upload image
   → Gemini Vision analyzes → Store HealthAssessment

4. PLAN GENERATION
   User taps "Generate AI Plans" → 3 parallel API calls:
   ├─ POST /plans/diet/generate
   │  → Load profile + assessment + KnowledgeService context
   │  → Gemini generates 7-day meal plan → Store DietPlan
   ├─ POST /plans/exercise/generate
   │  → Gemini generates workout plan → Store ExercisePlan
   └─ POST /plans/timetable/generate
      → Gemini generates daily schedule → Store Timetable

5. DAILY TRACKING
   ├─ POST /tracking/meals → Log what user ate
   ├─ POST /tracking/exercises → Log workouts done
   └─ POST /tracking/progress → Log weight, sleep, mood, etc.

6. DASHBOARD
   GET /tracking/dashboard → Aggregated stats:
   streak, averages, plan adherence %, weight change

7. KNOWLEDGE LIBRARY (no AI needed)
   GET /knowledge/foods → Browse 139+ Indian foods
   GET /knowledge/supplements → 14 supplements with brands
   GET /knowledge/exercises → Exercise database
   GET /knowledge/pranayama → Breathing techniques
   GET /knowledge/sleep-protocols → Sleep schedules
```

---

## Deployment Architecture (Production)

```
┌─────────────────────────────────────────────┐
│              CDN / App Store                 │
│  Flutter Web (Vercel/Cloudflare)             │
│  iOS App (App Store)                         │
│  Android App (Play Store)                    │
└──────────────────┬──────────────────────────┘
                   │ HTTPS
┌──────────────────▼──────────────────────────┐
│          Load Balancer (Nginx/ALB)           │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│        FastAPI Backend (Docker)               │
│        2+ replicas, auto-scaling             │
│        Gunicorn + Uvicorn workers            │
└────────┬──────────────────┬─────────────────┘
         │                  │
┌────────▼────────┐  ┌──────▼────────────────┐
│  PostgreSQL RDS  │  │  Redis ElastiCache    │
│  (managed)       │  │  (session cache)      │
└─────────────────┘  └──────────────────────┘
                           │
                    ┌──────▼────────────────┐
                    │  Google Gemini API     │
                    │  (external service)    │
                    └───────────────────────┘
                           │
                    ┌──────▼────────────────┐
                    │  S3 / Cloud Storage    │
                    │  (uploaded images)     │
                    └───────────────────────┘
```

---

## Directory Structure

```
jeevfit/
├── backend/
│   ├── app/
│   │   ├── ai/
│   │   │   ├── __init__.py          # Gemini client factory
│   │   │   ├── analyzer.py          # Image analysis (Vision API)
│   │   │   └── plan_generator.py    # Diet/exercise/timetable generation
│   │   ├── data/
│   │   │   ├── indian_nutrition_knowledge_base.json  (123KB, 128 foods)
│   │   │   ├── indian_foods.json                     (10KB, legacy)
│   │   │   ├── health_app_knowledge_base.md          (90KB, source)
│   │   │   └── parsed/                               (160KB total)
│   │   │       ├── supplements.json        (14 supplements)
│   │   │       ├── exercises_home.json     (47 exercises)
│   │   │       ├── exercises_gym.json      (3 programs)
│   │   │       ├── workout_programs.json   (HIIT + time-based)
│   │   │       ├── yoga_asanas.json        (33 asanas)
│   │   │       ├── pranayama.json          (6 techniques)
│   │   │       ├── sleep_protocols.json    (3 profession schedules)
│   │   │       ├── stress_management.json  (meditation + PMR)
│   │   │       ├── supplement_stacks.json  (6 pre-built stacks)
│   │   │       └── research_citations.json (57 PubMed refs)
│   │   ├── models/
│   │   │   ├── user.py, health_profile.py, assessment.py
│   │   │   ├── plan.py (DietPlan, ExercisePlan, Timetable)
│   │   │   └── tracking.py (MealLog, ExerciseLog, ProgressEntry)
│   │   ├── routers/
│   │   │   ├── auth.py, profile.py, assessment.py
│   │   │   ├── plans.py, tracking.py, knowledge.py
│   │   ├── schemas/
│   │   │   ├── user.py, health_profile.py, assessment.py
│   │   │   ├── plan.py, knowledge.py
│   │   ├── services/
│   │   │   ├── auth.py              (JWT + bcrypt)
│   │   │   └── knowledge_service.py (data loading + filtering)
│   │   ├── config.py, database.py, main.py
│   │   └── __init__.py
│   ├── scripts/
│   │   └── parse_health_kb.py       (validator/stats)
│   ├── tests/
│   │   └── test_api.py              (21 tests)
│   ├── alembic/                     (DB migrations)
│   ├── requirements.txt, Dockerfile, .env
│
├── frontend/
│   └── jeevfit/
│       ├── lib/
│       │   ├── main.dart
│       │   ├── router.dart
│       │   ├── providers/auth_provider.dart
│       │   ├── services/api_service.dart
│       │   ├── theme/app_theme.dart
│       │   ├── utils/constants.dart
│       │   ├── widgets/onboarding_steps.dart
│       │   └── screens/
│       │       ├── splash_screen.dart
│       │       ├── auth/ (login, register)
│       │       ├── onboarding/ (onboarding_screen)
│       │       ├── assessment/ (assessment_screen)
│       │       ├── home/ (dashboard, diet, exercise, timetable, profile, home_shell)
│       │       └── library/ (exercises, supplements, foods, breathing, sleep)
│       ├── ios/, assets/, test/
│       └── pubspec.yaml
│
├── docker-compose.yml
├── setup.sh
├── SETUP.md
├── ARCHITECTURE.md
└── CLAUDE.md
```
