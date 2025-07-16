#!/bin/bash

# Simple update script for Solent Marks Calculator
# Just pulls latest code and restarts the service

set -e  # Exit on any error

echo "🔄 Updating Solent Marks Calculator..."

# Configuration
APP_DIR="/var/www/marks.lymxod.org.uk"

# Navigate to app directory
cd "$APP_DIR"

# Pull latest changes
echo "📥 Pulling latest changes..."
git fetch origin
git reset --hard origin/main

# Restart the service
echo "🔄 Restarting service..."
sudo systemctl restart solent-marks

# Check service status
echo "📊 Checking service status..."
sudo systemctl status solent-marks --no-pager -l

echo "✅ Update completed successfully!"
echo "🌐 Application should be available at: https://marks.lymxod.org.uk" 