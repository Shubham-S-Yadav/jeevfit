#!/bin/bash
# JeevFit - Setup Script
# Run this to set up the development environment

set -e
echo "=========================================="
echo "   JeevFit - Setup Script"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

command -v python3 >/dev/null 2>&1 || { echo -e "${RED}Python 3 is required but not installed.${NC}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker is required but not installed.${NC}"; exit 1; }
echo -e "${GREEN}Prerequisites OK${NC}"

# 2. Start PostgreSQL and Redis via Docker
echo -e "\n${YELLOW}Starting PostgreSQL and Redis...${NC}"
docker compose up -d db redis
echo -e "${GREEN}Database and Redis started${NC}"

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
sleep 3

# 3. Setup Python backend
echo -e "\n${YELLOW}Setting up Python backend...${NC}"
cd backend

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt --quiet

# Copy .env if needed
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo -e "${YELLOW}Created .env from .env.example - please add your GEMINI_API_KEY${NC}"
fi

# Create upload directory
mkdir -p uploads

cd ..

# 4. Check Flutter
echo -e "\n${YELLOW}Checking Flutter...${NC}"
if command -v flutter >/dev/null 2>&1; then
    echo -e "${GREEN}Flutter found${NC}"
    cd frontend/jeevfit
    flutter pub get
    cd ../..
else
    echo -e "${YELLOW}Flutter not found. Install it from: https://docs.flutter.dev/get-started/install${NC}"
    echo "After installing, run: cd frontend/jeevfit && flutter pub get"
fi

echo -e "\n${GREEN}=========================================="
echo "   Setup complete!"
echo "==========================================${NC}"
echo ""
echo "To start the backend:"
echo "  cd backend && source venv/bin/activate && uvicorn app.main:app --reload"
echo ""
echo "To start the frontend:"
echo "  cd frontend/jeevfit && flutter run"
echo ""
echo "API docs: http://localhost:8000/docs"
echo ""
echo -e "${YELLOW}IMPORTANT: Add your Gemini API key to backend/.env${NC}"
echo "Get a free key at: https://aistudio.google.com/apikey"
