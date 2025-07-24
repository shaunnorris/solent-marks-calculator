#!/bin/bash
set -e

# Production deployment script for Solent Marks Calculator
# This script should be run on the production server

APP_DIR="/var/www/marks.lymxod.org.uk"
REPO_URL="https://github.com/shaunnorris/solent-marks-calculator.git"
BRANCH="main"
SERVICE_NAME="solent-marks"
TMP_CLONE="/tmp/solent-marks-tmp"

# Step 1: Clone or update repo in temp dir
if [ -d "$TMP_CLONE/.git" ]; then
    echo "==> Updating existing temp clone..."
    cd "$TMP_CLONE"
    git fetch origin
    git reset --hard origin/$BRANCH
else
    echo "==> Cloning fresh repo to temp dir..."
    rm -rf "$TMP_CLONE"
    git clone --branch $BRANCH "$REPO_URL" "$TMP_CLONE"
fi

# Step 2: Rsync only production files to app dir
rsync -av --delete \
    --exclude 'test_app.py' \
    --exclude 'dev/' \
    --exclude '__pycache__/' \
    --exclude '.pytest_cache/' \
    --exclude 'add_marks.py' \
    --exclude 'add_marks_fixed.py' \
    --exclude 'organize_dev_files.sh' \
    --exclude 'README.md' \
    --exclude '.git/' \
    --exclude '*.sh' \
    --exclude 'deploy_production.sh' \
    "$TMP_CLONE/" "$APP_DIR/"

# Step 3: Set correct ownership
sudo chown -R www-data:www-data "$APP_DIR"

# Step 4: Install dependencies in venv
cd "$APP_DIR"
if [ ! -d venv ]; then
    sudo -u www-data python3 -m venv venv
fi
sudo -u www-data bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

# Step 5: Restart service
sudo systemctl restart $SERVICE_NAME

echo "==> Production deployment complete!" 