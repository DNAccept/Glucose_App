#!/usr/bin/env bash
set -e

echo "============================================================"
echo "🚀 Deploying Glucose Monitor Online Database Backend Server"
echo "============================================================"

# Check Docker installation
if command -v docker &> /dev/null; then
    echo "[+] Docker detected. Building and launching container..."
    docker-compose up -d --build
    echo "============================================================"
    echo "✅ Backend container deployed and running on port 8080!"
    echo "============================================================"
    exit 0
fi

# Fallback to local Python execution
echo "[+] Docker not found. Setting up Python environment..."
python3 -m pip install gunicorn || true
export PORT=${PORT:-8080}
export DATABASE_PATH=${DATABASE_PATH:-"./online_database.sqlite"}

echo "[+] Starting WSGI server via Gunicorn..."
gunicorn --bind 0.0.0.0:${PORT} --workers 2 --timeout 60 wsgi:application
