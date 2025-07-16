#!/bin/bash

# Fix script to consolidate the two application directories
# This will ensure the service runs from the correct directory with all files

set -e  # Exit on any error

echo "🔧 Fixing directory confusion..."

# Configuration
SERVICE_NAME="solent-marks"

# Check which directory Apache expects (from apache2.conf)
APACHE_DOCROOT="/var/www/marks.lymxod.org.uk"
ALTERNATIVE_DIR="/var/www/solent-marks-calculator"

echo "🔍 Checking Apache configuration..."
if [ -f "/etc/apache2/sites-available/marks.lymxod.org.uk.conf" ]; then
    APACHE_DOCROOT=$(grep -o "DocumentRoot [^ ]*" /etc/apache2/sites-available/marks.lymxod.org.uk.conf | cut -d' ' -f2)
    echo "📋 Apache DocumentRoot: $APACHE_DOCROOT"
else
    echo "⚠️  Apache config not found, using default: $APACHE_DOCROOT"
fi

echo "📁 Checking directories..."

# Check which directory has the actual files
if [ -f "$APACHE_DOCROOT/2025scra.gpx" ]; then
    echo "✅ Found GPX file in Apache DocumentRoot: $APACHE_DOCROOT"
    SOURCE_DIR="$APACHE_DOCROOT"
    TARGET_DIR="$APACHE_DOCROOT"
elif [ -f "$ALTERNATIVE_DIR/2025scra.gpx" ]; then
    echo "✅ Found GPX file in alternative directory: $ALTERNATIVE_DIR"
    SOURCE_DIR="$ALTERNATIVE_DIR"
    TARGET_DIR="$APACHE_DOCROOT"
else
    echo "❌ No GPX file found in either directory!"
    echo "   Checked: $APACHE_DOCROOT"
    echo "   Checked: $ALTERNATIVE_DIR"
    exit 1
fi

# Stop the service
echo "🛑 Stopping service..."
sudo systemctl stop $SERVICE_NAME || true

# Kill any remaining gunicorn processes
sudo pkill -f gunicorn || true

# Only move files if source and target are different
if [ "$SOURCE_DIR" != "$TARGET_DIR" ]; then
    # Backup the target directory if it exists
    if [ -d "$TARGET_DIR" ]; then
        echo "💾 Backing up $TARGET_DIR..."
        sudo mv "$TARGET_DIR" "${TARGET_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Move the correct directory to the expected location
    echo "📦 Moving files from $SOURCE_DIR to $TARGET_DIR..."
    sudo mv "$SOURCE_DIR" "$TARGET_DIR"
else
    echo "✅ Files are already in the correct location: $TARGET_DIR"
fi

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