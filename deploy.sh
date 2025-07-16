#!/bin/bash

# Deployment script for Solent Marks Calculator
# Run this on the production server to deploy updates

set -e  # Exit on any error

echo "🚀 Starting deployment of Solent Marks Calculator..."

# Configuration
APP_DIR="/var/www/marks.lymcod.org"
REPO_URL="https://github.com/yourusername/solent-marks-calculator.git"
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

# Install/update dependencies
echo "📦 Installing dependencies..."
python3 -m pip install --user -r requirements.txt

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
ExecStart=/usr/local/bin/gunicorn --config gunicorn.conf.py app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable solent-marks
fi

# Restart the service
echo "🔄 Restarting service..."
sudo systemctl restart solent-marks

# Check service status
echo "📊 Checking service status..."
sudo systemctl status solent-marks --no-pager -l

echo "✅ Deployment completed successfully!"
echo "🌐 Application should be available at: https://marks.lymcod.org" 