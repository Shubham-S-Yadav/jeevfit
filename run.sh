#!/bin/bash
# JeevFit - Start All Services
# Usage: ./run.sh          (start everything)
#        ./run.sh stop      (stop everything)
#        ./run.sh status    (check what's running)
#        ./run.sh backend   (backend only)
#        ./run.sh frontend  (frontend only)

set -e
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
G='\033[0;32m'  # Green
Y='\033[1;33m'  # Yellow
R='\033[0;31m'  # Red
B='\033[1;34m'  # Blue
N='\033[0m'     # No color

LOG_DIR="/tmp/jeevfit"
mkdir -p "$LOG_DIR"

# ─── Helpers ───

check_prereqs() {
    local missing=0
    for cmd in docker python3 flutter; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${R}Missing: $cmd${N}"
            missing=1
        fi
    done
    if [ $missing -eq 1 ]; then
        echo -e "${Y}Install missing tools and try again. See SETUP.md${N}"
        exit 1
    fi
}

wait_for_port() {
    local port=$1 name=$2 max=$3
    local i=0
    while ! curl -s "http://localhost:$port" &>/dev/null; do
        i=$((i+1))
        if [ $i -ge $max ]; then
            echo -e "${R}$name failed to start on port $port${N}"
            echo "Check logs: cat $LOG_DIR/$name.log"
            return 1
        fi
        sleep 1
    done
    return 0
}

# ─── Start Database ───

start_db() {
    echo -e "${B}[1/3] Starting PostgreSQL & Redis...${N}"
    cd "$ROOT_DIR"
    docker compose up -d db redis 2>&1 | grep -v "^$"

    # Wait for healthy
    local i=0
    while ! docker compose ps --format '{{.Status}}' 2>/dev/null | grep -q "healthy"; do
        i=$((i+1))
        if [ $i -ge 15 ]; then
            echo -e "${R}Database not healthy after 15s${N}"
            docker compose ps
            exit 1
        fi
        sleep 1
    done
    echo -e "${G}  PostgreSQL (:5433) and Redis (:6380) running${N}"
}

# ─── Start Backend ───

start_backend() {
    echo -e "${B}[2/3] Starting FastAPI backend...${N}"

    # Kill existing
    pkill -f "uvicorn app.main" 2>/dev/null || true
    sleep 1

    cd "$ROOT_DIR/backend"

    # Setup venv if needed
    if [ ! -d "venv" ]; then
        echo "  Creating virtual environment..."
        python3 -m venv venv
    fi
    source venv/bin/activate
    pip install -r requirements.txt --quiet 2>&1 | tail -1

    # Start server
    nohup python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload \
        > "$LOG_DIR/backend.log" 2>&1 &
    echo $! > "$LOG_DIR/backend.pid"

    if wait_for_port 8000 "backend" 15; then
        echo -e "${G}  Backend running at http://localhost:8000${N}"
        echo -e "${G}  API docs at http://localhost:8000/docs${N}"
    fi
}

# ─── Start Frontend ───

start_frontend() {
    echo -e "${B}[3/3] Starting Flutter app...${N}"
    cd "$ROOT_DIR/frontend/jeevfit"

    flutter pub get --suppress-analytics 2>&1 | tail -1

    # Generate iOS files if missing
    if [ ! -d "ios/Runner" ]; then
        echo "  Generating iOS project files..."
        flutter create --platforms=ios . 2>&1 | tail -1
    fi

    # Find best device
    local device=""
    # Check for booted simulator
    if xcrun simctl list devices booted 2>/dev/null | grep -q "Booted"; then
        device=$(flutter devices 2>/dev/null | grep "mobile" | head -1 | awk -F'•' '{print $2}' | xargs)
    fi

    # Boot a simulator if none running
    if [ -z "$device" ]; then
        echo "  Booting iOS Simulator..."
        open -a Simulator 2>/dev/null || true
        local sim_id=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -o '[0-9A-F\-]\{36\}')
        if [ -n "$sim_id" ]; then
            xcrun simctl boot "$sim_id" 2>/dev/null || true
            sleep 5
            device="$sim_id"
        fi
    fi

    if [ -n "$device" ]; then
        echo "  Building & launching on device: $device"
        flutter run -d "$device" --no-resident > "$LOG_DIR/frontend.log" 2>&1 &
        echo $! > "$LOG_DIR/frontend.pid"
        echo -e "${G}  Flutter app launching (build takes ~30s first time)${N}"
    else
        echo -e "${Y}  No device found. Run manually: cd frontend/jeevfit && flutter run${N}"
    fi
}

# ─── Stop ───

stop_all() {
    echo -e "${Y}Stopping JeevFit services...${N}"

    # Stop backend
    pkill -f "uvicorn app.main" 2>/dev/null && echo "  Backend stopped" || echo "  Backend was not running"

    # Stop flutter
    pkill -f "flutter run" 2>/dev/null && echo "  Flutter stopped" || echo "  Flutter was not running"

    # Stop docker
    cd "$ROOT_DIR"
    docker compose down 2>&1 | grep -v "^$"
    echo "  Database stopped"

    echo -e "${G}All services stopped${N}"
}

# ─── Status ───

show_status() {
    echo -e "${B}JeevFit Service Status${N}"
    echo "─────────────────────────────────"

    # Database
    cd "$ROOT_DIR"
    if docker compose ps --format '{{.Names}} {{.Status}}' 2>/dev/null | grep -q "healthy"; then
        echo -e "  PostgreSQL  ${G}running${N} (:5433)"
        echo -e "  Redis       ${G}running${N} (:6380)"
    else
        echo -e "  PostgreSQL  ${R}stopped${N}"
        echo -e "  Redis       ${R}stopped${N}"
    fi

    # Backend
    if curl -s http://localhost:8000/health &>/dev/null; then
        echo -e "  Backend     ${G}running${N} (:8000)"
    else
        echo -e "  Backend     ${R}stopped${N}"
    fi

    # Frontend
    if pgrep -f "flutter run" &>/dev/null; then
        echo -e "  Flutter     ${G}running${N}"
    else
        echo -e "  Flutter     ${R}stopped${N}"
    fi

    echo "─────────────────────────────────"
    echo "Logs: $LOG_DIR/"
}

# ─── Main ───

case "${1:-start}" in
    start)
        echo -e "${G}========================================${N}"
        echo -e "${G}    JeevFit - Starting All Services     ${N}"
        echo -e "${G}========================================${N}"
        check_prereqs
        start_db
        start_backend
        start_frontend
        echo ""
        echo -e "${G}========================================${N}"
        echo -e "${G}    All services started!               ${N}"
        echo -e "${G}========================================${N}"
        echo ""
        echo "  Backend:  http://localhost:8000"
        echo "  API Docs: http://localhost:8000/docs"
        echo "  Logs:     $LOG_DIR/"
        echo ""
        echo "  Stop:     ./run.sh stop"
        echo "  Status:   ./run.sh status"
        ;;
    stop)
        stop_all
        ;;
    status)
        show_status
        ;;
    backend)
        check_prereqs
        start_db
        start_backend
        ;;
    frontend)
        start_frontend
        ;;
    *)
        echo "Usage: ./run.sh [start|stop|status|backend|frontend]"
        exit 1
        ;;
esac
