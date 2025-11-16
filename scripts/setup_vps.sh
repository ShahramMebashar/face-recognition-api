#!/bin/bash
# Setup script for Linux VPS
# This script installs system dependencies and Python packages

echo "=================================================="
echo "Face Recognition System - VPS Setup Script"
echo "=================================================="
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Please install dependencies manually."
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# Install system dependencies
echo "Installing system dependencies..."
echo "--------------------------------------------------"

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y python3-pip python3-dev python3-venv build-essential cmake
    sudo apt-get install -y libopenblas-dev liblapack-dev libx11-dev libgtk-3-dev
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "fedora" ]; then
    sudo yum update -y
    sudo yum install -y python3-pip python3-devel gcc gcc-c++ cmake
    sudo yum install -y openblas-devel lapack-devel libX11-devel gtk3-devel
else
    echo "Unsupported OS: $OS"
    echo "Please install dependencies manually."
    exit 1
fi

echo ""
echo "System dependencies installed successfully!"
echo ""

# Create virtual environment
echo "Creating Python virtual environment..."
echo "--------------------------------------------------"

python3 -m venv venv

echo "Virtual environment created!"
echo ""

# Activate virtual environment and install Python packages
echo "Installing Python packages..."
echo "--------------------------------------------------"
echo "This may take 5-10 minutes..."
echo ""

source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo ""
echo "=================================================="
echo "Installation Complete!"
echo "=================================================="
echo ""
echo "To activate the virtual environment:"
echo "  source venv/bin/activate"
echo ""
echo "To test the installation:"
echo "  python test_installation.py"
echo ""
echo "Next steps:"
echo "1. Add face images to known_faces/ directory"
echo "2. Run: python recognize_image.py <image_path>"
echo ""
echo "=================================================="
