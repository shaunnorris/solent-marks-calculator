#!/bin/bash

# Comprehensive redeployment script for Solent Marks Calculator
# This script will completely clean and redeploy to ensure fresh data

set -e  # Exit on any error

echo "🚀 Starting comprehensive redeployment of Solent Marks Calculator..."

# Configuration
APP_DIR="/var/www/marks.lymxod.org.uk"
REPO_URL="https://github.com/shaunnorris/solent-marks-calculator.git"
BRANCH="main"
SERVICE_NAME="solent-marks"

# Step 1: Stop and clean everything
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

# Step 2: Fresh clone and setup
echo "📥 Step 2: Fresh clone from repository..."

# Create app directory
sudo mkdir -p "$APP_DIR"
sudo chown $USER:$USER "$APP_DIR"

# Navigate to app directory
cd "$APP_DIR"

# Clone fresh from repository
echo "📥 Cloning repository..."
git clone "$REPO_URL" .

# Step 3: Verify GPX file
echo "🔍 Step 3: Verifying GPX file..."
if [ -f "2025scra.gpx" ]; then
    waypoint_count=$(grep -c "<wpt" 2025scra.gpx)
    echo "✅ GPX file found with $waypoint_count waypoints"
    
    # Show first few waypoints to verify content
    echo "📋 First 5 waypoints:"
    grep -A 3 "<wpt" 2025scra.gpx | head -20
else
    echo "❌ GPX file not found!"
    exit 1
fi

# Step 4: Install dependencies
echo "📦 Step 4: Installing dependencies..."

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment and install dependencies
echo "📦 Installing dependencies in virtual environment..."
source venv/bin/activate
pip install -r requirements.txt

# Check if we need to install gunicorn
if ! python3 -c "import gunicorn" 2>/dev/null; then
    echo "📦 Installing gunicorn..."
    pip install gunicorn
fi

# Step 5: Test the application locally
echo "🧪 Step 5: Testing application locally..."
source venv/bin/activate
python3 -c "
import xml.etree.ElementTree as ET
try:
    tree = ET.parse('2025scra.gpx')
    root = tree.getroot()
    ns = {'gpx': 'http://www.topografix.com/GPX/1/1'}
    waypoints = root.findall('.//gpx:wpt', ns)
    print(f'✅ Successfully parsed {len(waypoints)} waypoints')
    
    # Show some mark names
    names = []
    for wpt in waypoints[:10]:
        name_elem = wpt.find('gpx:name', ns)
        if name_elem is not None and name_elem.text:
            names.append(name_elem.text.strip())
    print(f'📋 Sample mark names: {names}')
    
except Exception as e:
    print(f'❌ Error parsing GPX file: {e}')
    exit(1)
"

# Step 6: Create systemd service
echo "🔧 Step 6: Creating systemd service..."

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
ExecStart=$APP_DIR/venv/bin/gunicorn --bind 0.0.0.0:8000 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Step 7: Set permissions and start service
echo "🔐 Step 7: Setting permissions and starting service..."
sudo chown -R www-data:www-data "$APP_DIR"

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME

# Start the service
echo "🔄 Starting service..."
sudo systemctl start $SERVICE_NAME

# Wait a moment for service to start
sleep 3

# Step 8: Verify service status
echo "📊 Step 8: Checking service status..."
sudo systemctl status $SERVICE_NAME --no-pager -l

# Step 9: Test the API endpoints
echo "🌐 Step 9: Testing API endpoints..."
sleep 2

# Test the marks endpoint
echo "📡 Testing /marks endpoint..."
curl -s "http://localhost:8000/marks" | python3 -m json.tool | head -20

echo ""
echo "📡 Testing /marks?zones=2 endpoint..."
curl -s "http://localhost:8000/marks?zones=2" | python3 -m json.tool | head -20

echo ""
echo "✅ Redeployment completed successfully!"
echo "🌐 Application should be available at: https://marks.lymxod.org.uk"
echo ""
echo "🔍 To check logs: sudo journalctl -u $SERVICE_NAME -f"
echo "🔄 To restart: sudo systemctl restart $SERVICE_NAME" 