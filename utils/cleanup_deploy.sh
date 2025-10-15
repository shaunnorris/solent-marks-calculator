#!/bin/bash

# Cleanup script to completely remove the current deployment
# Run this before redeploying to ensure a clean slate

set -e  # Exit on any error

echo "🧹 Starting cleanup of current deployment..."

# Configuration
APP_DIR="/var/www/marks.lymxod.org.uk"
SERVICE_NAME="solent-marks"

# Stop the service
echo "🛑 Stopping service..."
sudo systemctl stop $SERVICE_NAME || true

# Disable the service
echo "🔧 Disabling service..."
sudo systemctl disable $SERVICE_NAME || true

# Remove the service file
echo "🗑️ Removing service file..."
sudo rm -f /etc/systemd/system/$SERVICE_NAME.service

# Reload systemd
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

# Kill any remaining gunicorn processes
echo "💀 Killing any remaining gunicorn processes..."
sudo pkill -f gunicorn || true

# Remove the application directory
echo "🗑️ Removing application directory..."
sudo rm -rf "$APP_DIR"

# Clean up any Python cache files
echo "🧹 Cleaning Python cache..."
find /tmp -name "*.pyc" -delete 2>/dev/null || true
find /tmp -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

echo "✅ Cleanup completed successfully!"
echo "🚀 Ready for fresh deployment" 