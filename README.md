# JeevFit — AI-Powered Health & Fitness for India

An AI-powered health and fitness app built specifically for Indian users. Uses Google Gemini to analyze body photos, generate personalized diet plans, exercise routines, supplement recommendations, and daily schedules — all backed by ICMR guidelines and peer-reviewed research.

![Python](https://img.shields.io/badge/Python-3.13-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-green)
![Flutter](https://img.shields.io/badge/Flutter-3.41+-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)
![Gemini](https://img.shields.io/badge/Gemini-2.5-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### AI-Powered Health Assessment
- Upload body photos (front/side/back/face) for AI analysis
- Body fat %, body type, posture analysis, muscle assessment
- Skin & hair health evaluation with overall health score

### Personalized Indian Diet Plans
- 139+ Indian foods with ICMR nutritional data
- Region-specific cuisine (North/South/East/West India)
- Respects dietary preferences (Vegetarian, Vegan, Eggetarian, Jain, Non-Veg)
- Allergy-safe & preference-aware meal planning
- **Meal swap chat** — AI suggests alternatives when traveling, fasting, or missing ingredients
- Food synergies backed by research (dal+rice, turmeric+pepper)

### Evidence-Based Supplements
- 14 supplements with clinical evidence, Indian brand names & INR pricing
- Smart filtering: Ashwagandha excluded for thyroid conditions, Iron only with confirmed deficiency
- Pre-built stacks for different goals (muscle, stress/sleep, skin/hair)

### Exercise Plans
- Home (47 bodyweight exercises) & Gym (3 programs: Beginner/PPL/Upper-Lower)
- 33 yoga asanas by health goal + 6 pranayama techniques
- Time-based routines (15/30/45/60 min) + HIIT protocols
- Progressive overload plans

### Knowledge Library
- Browse 139+ foods with macros, GI values, key nutrients
- 14 supplements with dosage, timing, brands, contraindications
- Exercise library with instructions and alternatives
- Pranayama step-by-step guides
- Sleep protocols for IT/Night Shift/Startup professionals

### Daily Tracking
- Log meals, workouts, and daily check-ins (sleep, stress, energy, mood, water)
- Dashboard with weekly aggregated stats and streaks
- Progress history with trends

### Research-Backed
57 PubMed citations including:
- ICMR-NIN Dietary Guidelines 2024
- Ritu & Gupta (2014) — Vitamin D deficiency in India
- Chandrasekhar et al. (2012) — Ashwagandha cortisol reduction
- Shoba et al. (1998) — Piperine enhances curcumin absorption 2000%
- Morton et al. (2018) — Protein requirements for muscle
- Langade et al. (2019) — Ashwagandha improves sleep

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.41+ (iOS, Android, Web) |
| **State** | Riverpod + GoRouter |
| **Backend** | FastAPI (Python 3.13, async) |
| **Database** | PostgreSQL 16 + SQLAlchemy 2.0 |
| **AI** | Google Gemini 2.5 (Vision + Text) |
| **Cache** | Redis 7 |
| **Auth** | JWT + bcrypt |
| **Infra** | Docker Compose |

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Python 3.13+
- Flutter 3.41+ (for mobile/web)
- Gemini API key ([free](https://aistudio.google.com/apikey)) or GCP Vertex AI access

### One-Command Setup

```bash
git clone https://github.com/YOUR_USERNAME/jeevfit.git
cd jeevfit
chmod +x setup.sh run.sh
./setup.sh
```

Then add your Gemini API key:
```bash
cp backend/.env.example backend/.env
# Edit backend/.env and set GEMINI_API_KEY
```

### Run Everything

```bash
./run.sh          # Start DB + Backend + Flutter
./run.sh stop     # Stop all services
./run.sh status   # Check what's running
```

### Manual Start

```bash
# 1. Start databases
docker compose up -d db redis

# 2. Start backend
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# 3. Start frontend (new terminal)
cd frontend/jeevfit
flutter pub get
flutter run
```

- **API**: http://localhost:8000
- **Docs**: http://localhost:8000/docs

## API Endpoints (32)

| Group | Endpoints | Auth |
|-------|-----------|------|
| **Auth** | `POST /register`, `POST /login`, `GET /me` | No/Yes |
| **Profile** | `POST/GET/PUT /profile/` | Yes |
| **Assessment** | `POST /analyze`, `GET /latest`, `GET /history` | Yes |
| **Diet Plans** | `POST /generate`, `GET /active`, `GET /history`, `POST /alternative` | Yes |
| **Exercise Plans** | `POST /generate`, `GET /active` | Yes |
| **Timetable** | `POST /generate`, `GET /active` | Yes |
| **Tracking** | `POST /meals`, `GET /meals/today`, `POST /exercises`, `POST /progress`, `GET /progress/history`, `GET /dashboard` | Yes |
| **Knowledge** | `GET /foods`, `/supplements`, `/exercises`, `/yoga`, `/pranayama`, `/sleep-protocols`, `/food-synergies`, `/daily-tip`, `/citations` | **No** |

All endpoints prefixed with `/api/v1/`. Full Swagger docs at `/docs`.

## Project Structure

```
jeevfit/
├── backend/
│   ├── app/
│   │   ├── ai/                  # Gemini integration
│   │   │   ├── analyzer.py      # Image analysis (Vision API)
│   │   │   └── plan_generator.py # Diet/exercise/timetable + meal alternatives
│   │   ├── data/
│   │   │   ├── indian_nutrition_knowledge_base.json  (123KB, 128 foods)
│   │   │   ├── health_app_knowledge_base.md          (90KB, source research)
│   │   │   └── parsed/          # 10 structured JSON files (160KB)
│   │   ├── models/              # 7 SQLAlchemy models
│   │   ├── routers/             # 6 routers, 32 endpoints
│   │   ├── schemas/             # Pydantic validation
│   │   └── services/
│   │       ├── auth.py          # JWT + bcrypt
│   │       └── knowledge_service.py  # Singleton data loader + filtering
│   ├── scripts/parse_health_kb.py    # Data validator
│   ├── tests/test_api.py             # 21 tests
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/jeevfit/
│   └── lib/
│       ├── screens/             # 22 screens
│       │   ├── auth/            # Login, Register
│       │   ├── onboarding/      # 8-step health profile
│       │   ├── home/            # Dashboard, Plans, Tracking, Profile
│       │   └── library/         # Foods, Supplements, Exercises, Breathing, Sleep
│       ├── services/api_service.dart  # Dio HTTP client
│       ├── providers/           # Riverpod state
│       └── theme/               # Material Design 3
├── docker-compose.yml
├── run.sh                       # One-command launcher
├── setup.sh                     # First-time setup
├── SETUP.md                     # Detailed setup guide
├── ARCHITECTURE.md              # System architecture & diagrams
└── CLAUDE.md                    # AI assistant context
```

## Knowledge Base

| File | Content |
|------|---------|
| `supplements.json` | 14 supplements, dosages, brands, INR pricing, research |
| `exercises_home.json` | 47 bodyweight exercises by muscle group |
| `exercises_gym.json` | 3 gym programs + equipment database |
| `yoga_asanas.json` | 33 asanas across 5 health goals |
| `pranayama.json` | 6 breathing techniques with instructions |
| `sleep_protocols.json` | Hygiene rules + 3 profession schedules |
| `stress_management.json` | Meditation, PMR, Indian-context solutions |
| `research_citations.json` | 57 PubMed references |

## Testing

```bash
cd backend
pytest tests/ -v
```

21 tests covering: BMI/BMR/TDEE calculations, macros, food database validation, KnowledgeService loading, vegetarian filtering, supplement contraindications, regional diet data.

## Environment Variables

See [`backend/.env.example`](backend/.env.example) for all configuration options.

| Variable | Required | Description |
|----------|----------|-------------|
| `GEMINI_API_KEY` | Yes* | Gemini API key |
| `GEMINI_PROVIDER` | No | `api_key` (default) or `vertex` |
| `GEMINI_MODEL` | No | Model name (default: `gemini-2.5-flash`) |
| `DATABASE_URL` | No | PostgreSQL connection string |
| `SECRET_KEY` | Yes | JWT signing key |
| `REDIS_URL` | No | Redis connection string |

*Required when `GEMINI_PROVIDER=api_key`. For Vertex AI, set `GEMINI_VERTEX_PROJECT` instead.

## Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License — see [LICENSE](LICENSE) for details.
