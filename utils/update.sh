#!/bin/bash

# Simple update script for Solent Marks Calculator
# Pulls latest code and restarts the service from the current directory

set -e  # Exit on any error

# Check for git repo
if [ ! -d ".git" ]; then
    echo "❌ Error: This directory is not a git repository. Please run this script from the project root." >&2
    exit 1
fi

echo "🔄 Updating Solent Marks Calculator in $(pwd)..."

# Pull latest changes
echo "📥 Pulling latest changes..."
git fetch origin
git pull origin/main

# Restart the service
echo "🔄 Restarting service..."
sudo systemctl restart solent-marks

# Check service status
echo "📊 Checking service status..."
sudo systemctl status solent-marks --no-pager -l

echo "✅ Update completed successfully!"
echo "🌐 Application should be available at: https://marks.lymxod.org.uk" 