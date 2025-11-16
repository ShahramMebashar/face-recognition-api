FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    libopenblas-dev \
    liblapack-dev \
    libx11-dev \
    libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dlib first with specific version that works
RUN pip install --no-cache-dir cmake numpy && \
    pip install --no-cache-dir dlib==19.24.6

# Install remaining Python dependencies (skip dlib in requirements.txt)
RUN pip install --no-cache-dir \
    face-recognition==1.3.0 \
    opencv-python==4.10.0.84 \
    Pillow==10.4.0 \
    flask==3.1.0 \
    werkzeug==3.1.3 \
    requests==2.32.5 \
    click==8.1.7 \
    gunicorn==23.0.0

# Copy application files
COPY src/ ./src/
COPY run_server.py .

# Create known_faces directory
RUN mkdir -p known_faces

# Expose port
EXPOSE 5001

# Run with Gunicorn
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5001", "--timeout", "120", "src.api_server:app"]
