#!/bin/bash
# Setup SSL certificates with Let's Encrypt and auto-renewal
# For Ubuntu 24.04 / Debian-based systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if script is run with sudo
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Please run this script WITHOUT sudo${NC}"
    echo "The script will ask for sudo when needed"
    exit 1
fi

echo -e "${GREEN}=== Let's Encrypt SSL Setup ===${NC}\n"

# Get domain name
read -p "Enter your domain name (e.g., marks.example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Domain name is required${NC}"
    exit 1
fi

# Get email for Let's Encrypt notifications
read -p "Enter your email address for Let's Encrypt notifications: " EMAIL
if [ -z "$EMAIL" ]; then
    echo -e "${RED}Email address is required${NC}"
    exit 1
fi

# Confirm settings
echo -e "\n${YELLOW}Configuration:${NC}"
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo ""
read -p "Is this correct? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Setup cancelled"
    exit 0
fi

# Install certbot if not already installed
echo -e "\n${GREEN}Installing certbot...${NC}"
if ! command -v certbot &> /dev/null; then
    sudo apt update
    sudo apt install -y certbot
else
    echo "certbot is already installed"
fi

# Check if port 80 is available
echo -e "\n${GREEN}Checking port 80...${NC}"
if sudo lsof -Pi :80 -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}Port 80 is in use. Stopping Docker containers...${NC}"
    docker compose down
    sleep 2
fi

# Obtain certificate
echo -e "\n${GREEN}Obtaining SSL certificate from Let's Encrypt...${NC}"
sudo certbot certonly --standalone \
    --preferred-challenges http \
    --agree-tos \
    --no-eff-email \
    --email "$EMAIL" \
    -d "$DOMAIN"

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to obtain certificate${NC}"
    exit 1
fi

# Create ssl/certs directory if it doesn't exist
mkdir -p ssl/certs

# Copy certificates to project directory
echo -e "\n${GREEN}Copying certificates to project directory...${NC}"
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ssl/certs/
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ssl/certs/
sudo chown $USER:$USER ssl/certs/*.pem
chmod 644 ssl/certs/fullchain.pem
chmod 600 ssl/certs/privkey.pem

# Update nginx configuration
echo -e "\n${GREEN}Updating nginx configuration...${NC}"
cp nginx-docker.conf nginx-docker.conf.backup
sed -i "s/your-domain.com/$DOMAIN/g" nginx-docker.conf
sed -i 's|# ssl_certificate /etc/nginx/ssl/fullchain.pem;|ssl_certificate /etc/nginx/ssl/fullchain.pem;|g' nginx-docker.conf
sed -i 's|# ssl_certificate_key /etc/nginx/ssl/privkey.pem;|ssl_certificate_key /etc/nginx/ssl/privkey.pem;|g' nginx-docker.conf

# Enable HTTPS server block
sed -i 's/^# server {/server {/' nginx-docker.conf
sed -i 's/^#     /    /' nginx-docker.conf
sed -i 's/^# }/}/' nginx-docker.conf

# Enable HTTP to HTTPS redirect
sed -i 's|#     return 301 https://\$server_name\$request_uri;|    return 301 https://\$server_name\$request_uri;|' nginx-docker.conf

# Update docker-compose.yml to mount SSL certificates
echo -e "\n${GREEN}Updating docker-compose.yml...${NC}"
if ! grep -q "./ssl/certs:/etc/nginx/ssl:ro" docker-compose.yml; then
    # Add SSL volume mount after nginx-docker.conf line
    sed -i '/nginx-docker.conf:\/etc\/nginx\/conf.d\/default.conf:ro/a\      - ./ssl/certs:/etc/nginx/ssl:ro' docker-compose.yml
fi

# Setup auto-renewal
echo -e "\n${GREEN}Setting up auto-renewal...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENEWAL_SCRIPT="/usr/local/bin/renew-ssl-solent-marks.sh"

# Create renewal script
sudo tee $RENEWAL_SCRIPT > /dev/null <<EOF
#!/bin/bash
# Auto-renewal script for Solent Marks Calculator SSL certificates

set -e

DOMAIN="$DOMAIN"
PROJECT_DIR="$SCRIPT_DIR"
LOG_FILE="/var/log/solent-marks-ssl-renewal.log"

echo "\$(date): Starting SSL renewal for \$DOMAIN" >> \$LOG_FILE

# Renew certificate
certbot renew --quiet --deploy-hook "\\
    cp /etc/letsencrypt/live/\$DOMAIN/fullchain.pem \$PROJECT_DIR/ssl/certs/ && \\
    cp /etc/letsencrypt/live/\$DOMAIN/privkey.pem \$PROJECT_DIR/ssl/certs/ && \\
    chown $USER:$USER \$PROJECT_DIR/ssl/certs/*.pem && \\
    chmod 644 \$PROJECT_DIR/ssl/certs/fullchain.pem && \\
    chmod 600 \$PROJECT_DIR/ssl/certs/privkey.pem && \\
    cd \$PROJECT_DIR && docker compose exec nginx nginx -s reload" >> \$LOG_FILE 2>&1

if [ \$? -eq 0 ]; then
    echo "\$(date): SSL renewal completed successfully" >> \$LOG_FILE
else
    echo "\$(date): SSL renewal failed" >> \$LOG_FILE
    exit 1
fi
EOF

sudo chmod +x $RENEWAL_SCRIPT

# Setup cron job for auto-renewal (runs daily at 3am)
echo -e "\n${GREEN}Setting up cron job for auto-renewal...${NC}"
CRON_JOB="0 3 * * * $RENEWAL_SCRIPT"
(sudo crontab -l 2>/dev/null | grep -v "renew-ssl-solent-marks.sh"; echo "$CRON_JOB") | sudo crontab -

# Setup systemd timer as a more modern alternative (optional)
echo -e "\n${GREEN}Setting up systemd timer for auto-renewal...${NC}"
sudo tee /etc/systemd/system/solent-marks-ssl-renewal.service > /dev/null <<EOF
[Unit]
Description=Renew SSL certificates for Solent Marks Calculator
After=network.target

[Service]
Type=oneshot
ExecStart=$RENEWAL_SCRIPT
User=root
StandardOutput=journal
StandardError=journal
EOF

sudo tee /etc/systemd/system/solent-marks-ssl-renewal.timer > /dev/null <<EOF
[Unit]
Description=Daily SSL certificate renewal for Solent Marks Calculator
Requires=solent-marks-ssl-renewal.service

[Timer]
OnCalendar=daily
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer
sudo systemctl daemon-reload
sudo systemctl enable solent-marks-ssl-renewal.timer
sudo systemctl start solent-marks-ssl-renewal.timer

# Start Docker services
echo -e "\n${GREEN}Starting Docker services...${NC}"
docker compose up -d

# Wait for services to be ready
echo -e "\n${GREEN}Waiting for services to start...${NC}"
sleep 5

# Test HTTPS
echo -e "\n${GREEN}Testing HTTPS connection...${NC}"
if curl -f -s -o /dev/null -w "%{http_code}" https://$DOMAIN/health | grep -q "200"; then
    echo -e "${GREEN}✓ HTTPS is working correctly!${NC}"
else
    echo -e "${YELLOW}⚠ HTTPS test failed. Check nginx logs: docker compose logs nginx${NC}"
fi

# Summary
echo -e "\n${GREEN}=== Setup Complete ===${NC}\n"
echo -e "Domain: ${GREEN}$DOMAIN${NC}"
echo -e "Certificates: ${GREEN}ssl/certs/${NC}"
echo -e "Auto-renewal: ${GREEN}Enabled (daily check at 3 AM)${NC}"
echo -e "Renewal method: ${GREEN}Both cron and systemd timer${NC}"
echo -e "Renewal logs: ${GREEN}/var/log/solent-marks-ssl-renewal.log${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Visit https://$DOMAIN to verify HTTPS is working"
echo "2. Check renewal timer status: sudo systemctl status solent-marks-ssl-renewal.timer"
echo "3. View renewal logs: sudo tail -f /var/log/solent-marks-ssl-renewal.log"
echo "4. Test renewal manually: sudo $RENEWAL_SCRIPT"
echo ""
echo -e "${GREEN}Certificate will auto-renew when it has 30 days or less remaining.${NC}"
echo -e "${GREEN}Backups of old certificates are kept in /etc/letsencrypt/archive/$DOMAIN/${NC}"

