#!/bin/bash
# Quick start script for Face Recognition API

echo "=========================================="
echo "Face Recognition API - Quick Start"
echo "=========================================="
echo ""

# Check if venv exists
if [ ! -d "venv" ]; then
    echo "Virtual environment not found. Please run setup first:"
    echo "  python3 -m venv venv"
    echo "  source venv/bin/activate"
    echo "  pip install -r requirements.txt"
    exit 1
fi

# Activate venv and start server
echo "Starting API server..."
echo ""
source venv/bin/activate
cd "$(dirname "$0")/.."
python -m src.api_server
