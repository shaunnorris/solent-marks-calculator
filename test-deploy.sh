#!/bin/bash
set -e

echo "=================================================="
echo "  TEST DEPLOYMENT - Local Simulation"
echo "  Solent Racing Mark Bearing Calculator"
echo "=================================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Test domain
TEST_DOMAIN="bearings.local.test"
TEST_EMAIL="test@example.com"
DEPLOY_DIR="/tmp/bearings-test-deploy"

echo "🧪 Test Configuration:"
echo "   Domain: $TEST_DOMAIN"
echo "   Email: $TEST_EMAIL"
echo "   Deploy Dir: $DEPLOY_DIR"
echo ""

# Clean up any previous test
if [ -d "$DEPLOY_DIR" ]; then
    echo "🧹 Cleaning up previous test deployment..."
    cd "$DEPLOY_DIR"
    docker compose down 2>/dev/null || true
    cd /
    rm -rf "$DEPLOY_DIR"
fi

# Create test deployment directory
echo "📁 Creating test deployment directory..."
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

# Create docker-compose.yml
echo "📝 Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    image: ghcr.io/shaunnorris/solent-marks-calculator:latest
    container_name: bearings-test-app
    restart: unless-stopped
    networks:
      - app-network
    environment:
      - PYTHONUNBUFFERED=1

  nginx:
    image: nginx:alpine
    container_name: bearings-test-nginx
    restart: unless-stopped
    ports:
      - "8080:80"
      - "8443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    networks:
      - app-network
    depends_on:
      - web

networks:
  app-network:
    driver: bridge
EOF

# Create initial nginx config (HTTP only)
echo "📝 Creating initial nginx.conf (HTTP)..."
cat > nginx.conf << EOF
server {
    listen 80;
    server_name $TEST_DOMAIN;

    location / {
        proxy_pass http://web:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Pull image
echo ""
echo "🐳 Pulling Docker image..."
docker pull ghcr.io/shaunnorris/solent-marks-calculator:latest

# Start services (HTTP only)
echo ""
echo "🚀 Starting services (HTTP only)..."
docker compose up -d

# Wait for services
echo "⏳ Waiting for services to start..."
sleep 5

# Test HTTP
echo ""
echo "✅ Testing HTTP access..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|301\|302"; then
    echo "✅ HTTP is working on port 8080"
else
    echo "❌ HTTP test failed"
    docker compose logs
    exit 1
fi

# Create SSL directory for self-signed certificates
echo ""
echo "🔐 Creating self-signed SSL certificates..."
mkdir -p ssl

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/privkey.pem \
    -out ssl/fullchain.pem \
    -subj "/C=GB/ST=Test/L=Test/O=Test/CN=$TEST_DOMAIN" \
    2>/dev/null

# Create chain.pem (same as fullchain for self-signed)
cp ssl/fullchain.pem ssl/chain.pem

echo "✅ Self-signed certificates created"

# Update nginx config to enable HTTPS
echo ""
echo "🔧 Updating nginx.conf to enable HTTPS..."
cat > nginx.conf << EOF
# HTTP - redirect to HTTPS
server {
    listen 80;
    server_name $TEST_DOMAIN;
    
    # Redirect all traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name $TEST_DOMAIN;

    # SSL Configuration (self-signed for testing)
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
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

# Restart nginx to apply HTTPS config
echo ""
echo "🔄 Restarting nginx with HTTPS configuration..."
docker compose restart nginx

# Wait for restart
sleep 3

# Test HTTPS (with self-signed cert)
echo ""
echo "✅ Testing HTTPS access (ignoring certificate validation)..."
if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443 | grep -q "200"; then
    echo "✅ HTTPS is working on port 8443"
else
    echo "❌ HTTPS test failed"
    docker compose logs nginx
    exit 1
fi

# Test HTTP redirect
echo ""
echo "✅ Testing HTTP to HTTPS redirect..."
redirect_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if echo "$redirect_response" | grep -q "301\|302"; then
    echo "✅ HTTP redirects to HTTPS (status: $redirect_response)"
else
    echo "⚠️  HTTP redirect may not be working as expected (status: $redirect_response)"
fi

# Create test update script
echo ""
echo "📝 Creating update script..."
cat > update.sh << 'UPDATE_EOF'
#!/bin/bash
cd $(dirname "$0")
echo "🔄 Pulling latest image..."
docker pull ghcr.io/shaunnorris/solent-marks-calculator:latest
echo "🔄 Recreating containers..."
docker compose up -d
echo "🧹 Cleaning up old images..."
docker image prune -f
echo "✅ Update complete!"
UPDATE_EOF

chmod +x update.sh

# Show container status
echo ""
echo "📊 Container Status:"
docker compose ps

# Show logs preview
echo ""
echo "📋 Recent Logs:"
docker compose logs --tail=20

echo ""
echo "=================================================="
echo "  ✅ TEST DEPLOYMENT COMPLETE!"
echo "=================================================="
echo ""
echo "🌐 Test URLs:"
echo "   HTTP:  http://localhost:8080"
echo "   HTTPS: https://localhost:8443 (self-signed cert)"
echo ""
echo "📝 Note: Your browser will show a security warning for HTTPS"
echo "   because we're using a self-signed certificate. This is expected."
echo ""
echo "📋 Test Commands:"
echo "   View logs:     cd $DEPLOY_DIR && docker compose logs -f"
echo "   Restart:       cd $DEPLOY_DIR && docker compose restart"
echo "   Update:        cd $DEPLOY_DIR && ./update.sh"
echo "   Stop:          cd $DEPLOY_DIR && docker compose down"
echo "   Clean up:      sudo rm -rf $DEPLOY_DIR"
echo ""
echo "🧪 Testing:"
echo "   HTTP test:     curl http://localhost:8080"
echo "   HTTPS test:    curl -k https://localhost:8443"
echo "   Redirect test: curl -I http://localhost:8080"
echo ""
echo "=================================================="

