# JeevFit - Setup & Run Guide

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Docker Desktop | Latest | [docker.com](https://www.docker.com/products/docker-desktop/) |
| Python | 3.13+ | `brew install python@3.13` |
| Flutter | 3.41+ | `brew install --cask flutter` |
| Xcode | 26+ | App Store (for iOS) |
| CocoaPods | 1.16+ | `brew install cocoapods` |

---

## Quick Start (All Services)

```bash
# 1. Clone and enter project
cd ~/hobby_projects/jeevfit

# 2. Start databases
docker compose up -d db redis

# 3. Start backend
cd backend
pip install -r requirements.txt
cp .env.example .env   # Edit .env and add your GEMINI_API_KEY
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# 4. In a new terminal - Start frontend
cd frontend/jeevfit
flutter pub get
flutter run
```

---

## Detailed Setup

### 1. Database (PostgreSQL + Redis)

```bash
cd ~/hobby_projects/jeevfit

# Start containers (PostgreSQL on port 5433, Redis on port 6380)
docker compose up -d db redis

# Verify they're running
docker compose ps

# Expected output:
# jeevfit-db-1      Up (healthy)  0.0.0.0:5433->5432/tcp
# jeevfit-redis-1   Up (healthy)  0.0.0.0:6380->6379/tcp
```

**Port conflicts?** If ports 5432/6379 are in use by another project, the docker-compose.yml maps to 5433/6380 instead. The `.env` file is already configured for these ports.

**Reset database:**
```bash
docker compose down -v   # Removes volumes (all data lost)
docker compose up -d db redis
```

### 2. Backend (FastAPI)

```bash
cd ~/hobby_projects/jeevfit/backend

# Create virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env and set:
#   GEMINI_API_KEY=your-key-from-https://aistudio.google.com/apikey
#   DATABASE_URL=postgresql+asyncpg://jeevfit:jeevfit@localhost:5433/jeevfit
#   REDIS_URL=redis://localhost:6380/0

# Run the server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

**Verify:** Open http://localhost:8000/docs to see Swagger UI with all 31 endpoints.

**Run tests:**
```bash
cd ~/hobby_projects/jeevfit/backend
pytest tests/ -v
```

### 3. Frontend (Flutter)

```bash
cd ~/hobby_projects/jeevfit/frontend/jeevfit

# Install dependencies
flutter pub get

# Generate iOS platform files (first time only)
flutter create --platforms=ios .
```

**Run on iOS Simulator:**
```bash
# Boot a simulator
open -a Simulator

# Run the app
flutter run
```

**Run on physical iPhone:**
1. Plug iPhone in via USB, tap "Trust This Computer"
2. Open `ios/Runner.xcworkspace` in Xcode
3. Select Runner target > Signing & Capabilities > set your Team (Apple ID)
4. Set a unique Bundle Identifier (e.g., `com.yourname.jeevfit`)
5. Run: `flutter run`

**Run on Chrome (fastest for development):**
```bash
flutter run -d chrome
```

**Run on macOS:**
```bash
flutter create --platforms=macos .
flutter run -d macos
```

---

## Environment Variables Reference

### Backend `.env`

```env
APP_NAME=JeevFit
DEBUG=true

# Database (match docker-compose port mapping)
DATABASE_URL=postgresql+asyncpg://jeevfit:jeevfit@localhost:5433/jeevfit
DATABASE_URL_SYNC=postgresql://jeevfit:jeevfit@localhost:5433/jeevfit

# Auth
SECRET_KEY=dev-secret-key-change-in-production-openssl-rand-hex-32

# AI - Get a free key at https://aistudio.google.com/apikey
GEMINI_PROVIDER=api_key
GEMINI_API_KEY=your-api-key-here
GEMINI_MODEL=gemini-2.0-flash

# Storage
UPLOAD_DIR=./uploads

# Redis
REDIS_URL=redis://localhost:6380/0
```

### Frontend API URL

Edit `lib/services/api_service.dart` line 6:
```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
```

For Android emulator use `10.0.2.2` instead of `localhost`.

---

## Common Issues

| Issue | Fix |
|-------|-----|
| `port already allocated` | Another project using the port. Check `docker ps -a` and stop conflicting containers |
| `bcrypt: no backends available` | `pip install bcrypt==4.0.1` |
| `No module named 'greenlet'` | `pip install greenlet` |
| `No module named 'email_validator'` | `pip install email-validator` |
| `CardTheme` build error in Flutter | Already fixed - uses `CardThemeData` for Flutter 3.41+ |
| Xcode license not accepted | `sudo xcodebuild -license accept` |
| iOS Simulator not found | `xcodebuild -downloadPlatform iOS` |
| App can't connect to backend | Ensure backend is running on port 8000 and `baseUrl` in `api_service.dart` is correct |

---

## Stopping Services

```bash
# Stop backend (Ctrl+C in terminal, or)
pkill -f "uvicorn app.main"

# Stop databases
cd ~/hobby_projects/jeevfit
docker compose down

# Stop everything including volumes (data loss)
docker compose down -v
```

---

## Python Dependencies (requirements.txt)

| Package | Purpose |
|---------|---------|
| fastapi | Web framework (async) |
| uvicorn | ASGI server |
| sqlalchemy + asyncpg | Async PostgreSQL ORM |
| alembic | Database migrations |
| pydantic + pydantic-settings | Data validation, settings |
| python-jose | JWT token creation/verification |
| passlib + bcrypt | Password hashing |
| google-genai | Gemini AI API client |
| pillow | Image processing |
| httpx | Async HTTP client |
| aiofiles | Async file I/O |
| email-validator | Email validation for Pydantic |
| greenlet | SQLAlchemy async support |
| pytest | Testing |

## Flutter Dependencies (pubspec.yaml)

| Package | Purpose |
|---------|---------|
| flutter_riverpod | State management |
| go_router | Declarative navigation |
| dio | HTTP client |
| flutter_secure_storage | Secure token storage |
| image_picker | Camera/gallery access |
| google_fonts | Poppins typography |
| fl_chart | Charts & graphs |
| flutter_animate | Animations |
| shimmer | Loading skeleton effects |
| cached_network_image | Image caching |
| flutter_svg | SVG rendering |
| percent_indicator | Progress indicators |
| shared_preferences | Simple key-value storage |
| sqflite | Local SQLite (offline cache) |
