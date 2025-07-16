#!/bin/bash

# Fix script to consolidate the two application directories
# This will ensure the service runs from the correct directory with all files

set -e  # Exit on any error

echo "🔧 Fixing directory confusion..."

# Configuration
CORRECT_DIR="/var/www/solent-marks-calculator"
WRONG_DIR="/var/www/marks.lymxod.org.uk"
SERVICE_NAME="solent-marks"

echo "📁 Checking directories..."

# Check which directory has the actual files
if [ -f "$CORRECT_DIR/2025scra.gpx" ]; then
    echo "✅ Found GPX file in $CORRECT_DIR"
    SOURCE_DIR="$CORRECT_DIR"
    TARGET_DIR="$WRONG_DIR"
elif [ -f "$WRONG_DIR/2025scra.gpx" ]; then
    echo "✅ Found GPX file in $WRONG_DIR"
    SOURCE_DIR="$WRONG_DIR"
    TARGET_DIR="$CORRECT_DIR"
else
    echo "❌ No GPX file found in either directory!"
    exit 1
fi

# Stop the service
echo "🛑 Stopping service..."
sudo systemctl stop $SERVICE_NAME || true

# Kill any remaining gunicorn processes
sudo pkill -f gunicorn || true

# Backup the wrong directory if it exists
if [ -d "$TARGET_DIR" ]; then
    echo "💾 Backing up $TARGET_DIR..."
    sudo mv "$TARGET_DIR" "${TARGET_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Move the correct directory to the expected location
echo "📦 Moving files to correct location..."
sudo mv "$SOURCE_DIR" "$TARGET_DIR"

# Set proper permissions
echo "🔐 Setting permissions..."
sudo chown -R www-data:www-data "$TARGET_DIR"

# Update the systemd service to use the correct directory
echo "🔧 Updating systemd service..."
sudo tee "/etc/systemd/system/$SERVICE_NAME.service" > /dev/null <<EOF
[Unit]
Description=Solent Marks Calculator
After=network.target

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=$TARGET_DIR
ExecStart=python3 -m gunicorn --config gunicorn.conf.py app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and restart service
echo "🔄 Reloading systemd and starting service..."
sudo systemctl daemon-reload
sudo systemctl restart $SERVICE_NAME

# Wait a moment for service to start
sleep 3

# Check service status
echo "📊 Checking service status..."
sudo systemctl status $SERVICE_NAME --no-pager -l

# Verify the GPX file is accessible
echo "🔍 Verifying GPX file..."
if [ -f "$TARGET_DIR/2025scra.gpx" ]; then
    waypoint_count=$(grep -c "<wpt" "$TARGET_DIR/2025scra.gpx")
    echo "✅ GPX file found with $waypoint_count waypoints"
else
    echo "❌ GPX file not found in target directory!"
fi

echo "✅ Directory fix completed!"
echo "🌐 Application should now be available at: https://marks.lymxod.org.uk" 