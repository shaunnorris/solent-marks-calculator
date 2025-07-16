#!/bin/bash

# Clean Production Deployment Script for Solent Marks Calculator
# This script deploys only the essential files needed for production

set -e  # Exit on any error

echo "🚀 Starting clean production deployment of Solent Marks Calculator..."

# Configuration
APP_DIR="/var/www/marks.lymxod.org.uk"
REPO_URL="https://github.com/shaunnorris/solent-marks-calculator.git"
BRANCH="main"
SERVICE_NAME="solent-marks"

# Step 1: Stop and clean current deployment
echo "🧹 Step 1: Stopping and cleaning current deployment..."

# Stop the service
sudo systemctl stop $SERVICE_NAME || true

# Kill any remaining gunicorn processes
sudo pkill -f gunicorn || true

# Remove the application directory completely
sudo rm -rf "$APP_DIR"

# Remove service file
sudo rm -f /etc/systemd/system/$SERVICE_NAME.service

# Reload systemd
sudo systemctl daemon-reload

# Step 2: Create fresh directory and clone
echo "📥 Step 2: Creating fresh directory and cloning repository..."

# Create app directory
sudo mkdir -p "$APP_DIR"
sudo chown $USER:$USER "$APP_DIR"

# Navigate to app directory
cd "$APP_DIR"

# Clone fresh from repository
echo "📥 Cloning repository..."
git clone "$REPO_URL" .

# Step 3: Clean up development files
echo "🧹 Step 3: Removing development and working files..."

# Remove development scripts
rm -f add_marks_*.py
rm -f clean_marks_*.py
rm -f fix_marks_*.py
rm -f *_marks_*.py

# Remove working files
rm -f "Lym Inshore Marks"*.txt
rm -f "Lym Inshore Marks"*.backup*

# Remove test files
rm -f test_app.py

# Remove cache directories
rm -rf __pycache__
rm -rf .pytest_cache

# Remove deployment scripts (keep only this one)
rm -f deploy.sh
rm -f redeploy.sh
rm -f fix_directories.sh
rm -f cleanup_deploy.sh

# Remove nginx config (we're using Apache)
rm -f nginx.conf

# Step 4: Verify essential files
echo "🔍 Step 4: Verifying essential files..."

ESSENTIAL_FILES=(
    "app.py"
    "2025scra.gpx"
    "requirements.txt"
    "gunicorn.conf.py"
    "apache2.conf"
    "templates/"
)

for file in "${ESSENTIAL_FILES[@]}"; do
    if [ -e "$file" ]; then
        echo "✅ Found: $file"
    else
        echo "❌ Missing: $file"
        exit 1
    fi
done

# Verify GPX file
waypoint_count=$(grep -c "<wpt" 2025scra.gpx)
echo "✅ GPX file has $waypoint_count waypoints"

# Step 5: Install dependencies
echo "📦 Step 5: Installing dependencies..."

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Step 6: Test the application
echo "🧪 Step 6: Testing application locally..."
python3 -c "
import xml.etree.ElementTree as ET
try:
    tree = ET.parse('2025scra.gpx')
    root = tree.getroot()
    ns = {'gpx': 'http://www.topografix.com/GPX/1/1'}
    waypoints = root.findall('.//gpx:wpt', ns)
    print(f'✅ Successfully parsed {len(waypoints)} waypoints')
    
    # Test Flask app import
    from app import app
    print('✅ Flask app imports successfully')
    
except Exception as e:
    print(f'❌ Error: {e}')
    exit(1)
"

# Step 7: Create systemd service
echo "🔧 Step 7: Creating systemd service..."
sudo tee "/etc/systemd/system/$SERVICE_NAME.service" > /dev/null <<EOF
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

# Step 8: Set permissions and start service
echo "🔐 Step 8: Setting permissions and starting service..."
sudo chown -R www-data:www-data "$APP_DIR"

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME

# Start the service
echo "🔄 Starting service..."
sudo systemctl start $SERVICE_NAME

# Wait a moment for service to start
sleep 3

# Step 9: Verify service status
echo "📊 Step 9: Checking service status..."
sudo systemctl status $SERVICE_NAME --no-pager -l

# Step 10: Test API endpoints
echo "🌐 Step 10: Testing API endpoints..."
sleep 2

# Test the marks endpoint
echo "📡 Testing /marks endpoint..."
curl -s "http://localhost:8000/marks" | python3 -c "import sys, json; data=json.load(sys.stdin); print(f'✅ Found {len(data.get(\"marks\", []))} marks, {len(data.get(\"zones\", []))} zones')"

echo ""
echo "✅ Clean production deployment completed successfully!"
echo "🌐 Application should be available at: https://marks.lymxod.org.uk"
echo ""
echo "📁 Production directory contains only essential files:"
ls -la
echo ""
echo "🔍 To check logs: sudo journalctl -u $SERVICE_NAME -f"
echo "🔄 To restart: sudo systemctl restart $SERVICE_NAME" 