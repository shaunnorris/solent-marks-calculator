# Multi-Environment Deployment Guide

## Overview

This project supports different configurations for dev, test, and production environments using Docker Compose overrides.

## Directory Structure

```
.
├── docker-compose.yml          # Base configuration
├── docker-compose.dev.yml      # Development overrides
├── docker-compose.test.yml     # Test/staging overrides
├── docker-compose.prod.yml     # Production overrides
├── nginx-docker.conf           # Dev nginx (no SSL)
├── nginx-test.conf             # Test nginx (test SSL)
├── nginx-prod.conf             # Production nginx (Let's Encrypt SSL)
└── certs/
    ├── dev/                    # Not needed
    ├── test/                   # Self-signed or staging certs
    └── prod/                   # Symlink to /etc/letsencrypt
```

## Usage

### Development (Local)

No SSL, HTTP only:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

Access: `http://localhost`

### Test/Staging

With test SSL certificates:

```bash
# Generate self-signed cert for testing (one-time)
mkdir -p certs/test
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/test/key.pem \
  -out certs/test/cert.pem \
  -subj "/CN=test.marks.yourdomain.com"

# Deploy
docker compose -f docker-compose.yml -f docker-compose.test.yml up -d
```

Access: `https://test.marks.yourdomain.com`

### Production

With Let's Encrypt SSL:

```bash
# On production server
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

Access: `https://marks.yourdomain.com`

## SSL Certificate Management

### Development
- No SSL needed
- HTTP only on port 80

### Test/Staging

**Option 1: Self-signed certificates**
```bash
mkdir -p certs/test
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/test/key.pem \
  -out certs/test/cert.pem \
  -subj "/CN=test.yourdomain.com"
```

**Option 2: Let's Encrypt staging**
```bash
certbot certonly --staging \
  --standalone \
  -d test.marks.yourdomain.com
```

### Production

**Let's Encrypt (recommended):**

```bash
# Install certbot
sudo apt-get install certbot

# Stop nginx temporarily
docker compose down

# Get certificate
sudo certbot certonly --standalone \
  -d marks.yourdomain.com \
  --email your@email.com \
  --agree-tos

# Certificates will be in /etc/letsencrypt/live/marks.yourdomain.com/

# Start services
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

**Auto-renewal:**
```bash
# Add to crontab
0 3 * * * certbot renew --post-hook "docker compose restart nginx"
```

## Makefile Updates

Add to your Makefile:

```makefile
dev: ## Start development environment
	docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

test: ## Start test environment
	docker compose -f docker-compose.yml -f docker-compose.test.yml up -d

prod: ## Start production environment
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

down-dev: ## Stop development
	docker compose -f docker-compose.yml -f docker-compose.dev.yml down

down-test: ## Stop test
	docker compose -f docker-compose.yml -f docker-compose.test.yml down

down-prod: ## Stop production
	docker compose -f docker-compose.yml -f docker-compose.prod.yml down
```

## Environment Variables

Create `.env` files for each environment:

**.env.dev**
```env
ENVIRONMENT=development
FLASK_DEBUG=1
```

**.env.test**
```env
ENVIRONMENT=test
FLASK_DEBUG=0
```

**.env.prod**
```env
ENVIRONMENT=production
FLASK_DEBUG=0
```

Use in compose:
```bash
docker compose --env-file .env.dev -f docker-compose.yml -f docker-compose.dev.yml up -d
```

## Best Practices

1. **Never commit certificates** - Add to .gitignore:
   ```
   certs/
   *.pem
   *.key
   *.crt
   .env.prod
   ```

2. **Use secrets in production** - Consider Docker secrets for sensitive data

3. **Separate domains**:
   - Dev: `localhost` or `dev.marks.local`
   - Test: `test.marks.yourdomain.com`
   - Prod: `marks.yourdomain.com`

4. **Different ports locally**:
   ```yaml
   # docker-compose.test.yml
   services:
     nginx:
       ports:
         - "8080:80"
         - "8443:443"
   ```

5. **Test SSL renewal**:
   ```bash
   certbot renew --dry-run
   ```

## Workflow Example

### Local Development
```bash
# Start
make dev
# or
docker compose up -d

# Test
curl http://localhost/health

# Stop
make down
```

### Deploy to Test
```bash
# On test server
git pull
docker compose -f docker-compose.yml -f docker-compose.test.yml pull
docker compose -f docker-compose.yml -f docker-compose.test.yml up -d --build

# Verify
curl https://test.marks.yourdomain.com/health
```

### Deploy to Production
```bash
# On production server
git pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

# Verify
curl https://marks.yourdomain.com/health
```

## Troubleshooting

### Certificate not found
```bash
# Check certificate exists
ls -la /etc/letsencrypt/live/yourdomain.com/

# Check nginx config
docker compose exec nginx nginx -t

# Check nginx logs
docker compose logs nginx
```

### Permission denied on certificates
```bash
# Ensure nginx container can read certs
sudo chmod 755 /etc/letsencrypt/live
sudo chmod 755 /etc/letsencrypt/archive
```

### Mixed environment
```bash
# Always specify both files explicitly
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

