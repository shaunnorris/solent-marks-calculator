#!/bin/bash

# Deployment script for Solent Marks Calculator
# Run this on the production server to deploy updates

set -e  # Exit on any error

echo "🚀 Starting deployment of Solent Marks Calculator..."

# Configuration
APP_DIR="/var/www/marks.lymxod.org.uk"
REPO_URL="https://github.com/shaunnorris/solent-marks-calculator.git"
BRANCH="main"

# Create app directory if it doesn't exist
if [ ! -d "$APP_DIR" ]; then
    echo "📁 Creating application directory..."
    sudo mkdir -p "$APP_DIR"
    sudo chown $USER:$USER "$APP_DIR"
fi

# Navigate to app directory
cd "$APP_DIR"

# Clone or pull the repository
if [ ! -d ".git" ]; then
    echo "📥 Cloning repository..."
    git clone "$REPO_URL" .
else
    echo "📥 Pulling latest changes..."
    git fetch origin
    git reset --hard origin/$BRANCH
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "🐍 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment and install dependencies
echo "📦 Installing dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Create Gunicorn config if it doesn't exist
if [ ! -f "gunicorn.conf.py" ]; then
    echo "🔧 Creating Gunicorn configuration..."
    cat > gunicorn.conf.py <<EOF
bind = "127.0.0.1:8000"
workers = 3
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2
max_requests = 1000
max_requests_jitter = 100
preload_app = True
EOF
fi

# Create systemd service file if it doesn't exist
SERVICE_FILE="/etc/systemd/system/solent-marks.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "🔧 Creating systemd service..."
    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Solent Marks Calculator
After=network.target

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/venv/bin
ExecStart=$APP_DIR/venv/bin/gunicorn --config gunicorn.conf.py app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable solent-marks
fi

# Set proper permissions
echo "🔐 Setting permissions..."
sudo chown -R www-data:www-data "$APP_DIR"

# Restart the service
echo "🔄 Restarting service..."
sudo systemctl restart solent-marks

# Check service status
echo "📊 Checking service status..."
sudo systemctl status solent-marks --no-pager -l

echo "✅ Deployment completed successfully!"
echo "🌐 Application should be available at: https://marks.lymxod.org.uk" 