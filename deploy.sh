#!/bin/bash
set -e

echo "=================================================="
echo "  Solent Racing Mark Bearing Calculator"
echo "  Production Deployment Script"
echo "=================================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create deployment directory
DEPLOY_DIR="/opt/bearings-app"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

# Check if already configured
if [ -f "$DEPLOY_DIR/.configured" ]; then
    echo "ℹ️  App is already configured."
    echo ""
    echo "What would you like to do?"
    echo "1) Update to latest version"
    echo "2) Reconfigure SSL"
    echo "3) Restart services"
    echo "4) View logs"
    echo "5) Exit"
    echo ""
    read -p "Enter choice [1-5]: " choice
    
    case $choice in
        1)
            echo ""
            echo "🔄 Updating to latest version..."
            docker pull ghcr.io/shaunnorris/solent-marks-calculator:latest
            docker compose up -d
            docker image prune -f
            echo "✅ Update complete!"
            ;;
        2)
            rm "$DEPLOY_DIR/.configured"
            echo "🔄 Reconfiguring SSL..."
            exec "$0" "$@"
            ;;
        3)
            echo "🔄 Restarting services..."
            docker compose restart
            echo "✅ Services restarted!"
            ;;
        4)
            echo "📋 Viewing logs (Ctrl+C to exit)..."
            docker compose logs -f
            ;;
        5)
            exit 0
            ;;
        *)
            echo "❌ Invalid choice"
            exit 1
            ;;
    esac
    exit 0
fi

# Get domain name
echo ""
echo "📝 Configuration"
echo "----------------"
read -p "Enter your domain name (e.g., bearings.lymxod.org.uk): " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Domain name is required"
    exit 1
fi

echo ""
echo "ℹ️  Domain: $DOMAIN_NAME"
echo ""

# Get email for Let's Encrypt
read -p "Enter your email for SSL certificate notifications: " EMAIL

if [ -z "$EMAIL" ]; then
    echo "❌ Email is required"
    exit 1
fi

# Download configuration files
echo ""
echo "📥 Downloading configuration files..."
curl -sSL https://raw.githubusercontent.com/shaunnorris/solent-marks-calculator/main/docker-compose.production.yml -o docker-compose.yml
curl -sSL https://raw.githubusercontent.com/shaunnorris/solent-marks-calculator/main/nginx-production.conf -o nginx.conf

echo "✅ Configuration files downloaded"

# Update nginx config with domain name
sed -i "s/DOMAIN_NAME/$DOMAIN_NAME/g" nginx.conf

echo ""
echo "🐳 Pulling Docker image..."
docker pull ghcr.io/shaunnorris/solent-marks-calculator:latest

echo ""
echo "🚀 Starting services (HTTP only)..."
docker compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 5

# Check if services are running
if ! docker compose ps | grep -q "Up"; then
    echo "❌ Services failed to start. Check logs with: docker compose logs"
    exit 1
fi

echo "✅ Services started successfully"

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo ""
    echo "📦 Installing Certbot..."
    apt update
    apt install -y certbot
    echo "✅ Certbot installed"
fi

# Configure firewall if UFW is available
if command -v ufw &> /dev/null; then
    echo ""
    echo "🔥 Configuring firewall..."
    
    # Check if UFW is enabled
    if ufw status | grep -q "Status: active"; then
        echo "ℹ️  UFW is already enabled"
    else
        echo "⚠️  UFW is not enabled. Would you like to enable it? (y/n)"
        echo "   WARNING: Make sure SSH port 22 is allowed first!"
        read -p "Enable UFW? [y/N]: " enable_ufw
        
        if [ "$enable_ufw" = "y" ] || [ "$enable_ufw" = "Y" ]; then
            ufw allow 22/tcp
            ufw allow 80/tcp
            ufw allow 443/tcp
            ufw --force enable
            echo "✅ Firewall configured and enabled"
        fi
    fi
    
    # Ensure ports are open
    ufw allow 80/tcp 2>/dev/null || true
    ufw allow 443/tcp 2>/dev/null || true
    
    echo "✅ Firewall ports configured"
fi

# Get SSL certificate
echo ""
echo "🔐 Obtaining SSL certificate..."
echo "⏳ This may take a minute..."

# Stop nginx temporarily
docker compose stop nginx

# Get certificate
if certbot certonly --standalone -d "$DOMAIN_NAME" --email "$EMAIL" --agree-tos --non-interactive; then
    echo "✅ SSL certificate obtained successfully"
else
    echo "❌ Failed to obtain SSL certificate"
    echo "   Make sure DNS is pointing to this server and ports 80/443 are open"
    docker compose start nginx
    exit 1
fi

# Update nginx config to enable HTTPS
echo ""
echo "🔧 Enabling HTTPS in Nginx configuration..."

# Uncomment HTTPS section and update HTTP redirect
cat > nginx.conf << EOF
# HTTP - redirect to HTTPS
server {
    listen 80;
    server_name $DOMAIN_NAME;
    
    # Allow Let's Encrypt verification
    location /.well-known/acme-challenge/ {
        root /var/lib/letsencrypt;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/$DOMAIN_NAME/chain.pem;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to Flask app
    location / {
        proxy_pass http://web:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$server_name;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Restart nginx with HTTPS
docker compose start nginx

echo "✅ HTTPS enabled"

# Set up auto-renewal
echo ""
echo "🔄 Setting up SSL auto-renewal..."

# Create renewal hook directory
mkdir -p /etc/letsencrypt/renewal-hooks/deploy

# Create renewal hook script
cat > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh << 'HOOK_EOF'
#!/bin/bash
cd /opt/bearings-app
docker compose restart nginx
HOOK_EOF

chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh

# Enable certbot timer
systemctl enable certbot.timer 2>/dev/null || true
systemctl start certbot.timer 2>/dev/null || true

echo "✅ Auto-renewal configured"

# Create update script
echo ""
echo "📝 Creating update script..."

cat > /opt/bearings-app/update.sh << 'UPDATE_EOF'
#!/bin/bash
cd /opt/bearings-app
echo "🔄 Pulling latest image..."
docker pull ghcr.io/shaunnorris/solent-marks-calculator:latest
echo "🔄 Recreating containers..."
docker compose up -d
echo "🧹 Cleaning up old images..."
docker image prune -f
echo "✅ Update complete!"
UPDATE_EOF

chmod +x /opt/bearings-app/update.sh

echo "✅ Update script created"

# Mark as configured
touch "$DEPLOY_DIR/.configured"
echo "$DOMAIN_NAME" > "$DEPLOY_DIR/.domain"

# Final check
echo ""
echo "🔍 Checking deployment status..."
sleep 3

if docker compose ps | grep -q "Up"; then
    echo "✅ All services are running"
else
    echo "⚠️  Some services may not be running. Check logs with: docker compose logs"
fi

echo ""
echo "=================================================="
echo "  ✅ Deployment Complete!"
echo "=================================================="
echo ""
echo "🌐 Your app is now available at:"
echo "   https://$DOMAIN_NAME"
echo ""
echo "📋 Useful commands:"
echo "   View logs:        sudo docker compose -f $DEPLOY_DIR/docker-compose.yml logs -f"
echo "   Restart services: sudo docker compose -f $DEPLOY_DIR/docker-compose.yml restart"
echo "   Update app:       sudo $DEPLOY_DIR/update.sh"
echo "   Reconfigure:      sudo $0"
echo ""
echo "🔐 SSL certificate will auto-renew before expiration"
echo ""
echo "=================================================="

