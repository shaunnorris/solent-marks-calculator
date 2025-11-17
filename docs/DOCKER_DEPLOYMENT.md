# Docker Deployment Guide

This guide covers deploying the Solent Marks Calculator using Docker for production environments.

## Overview

The Docker setup includes:
- **Multi-stage Dockerfile** - Optimized Python image with security best practices
- **Docker Compose** - Orchestrates the Flask app and Nginx reverse proxy
- **Nginx** - Handles SSL/TLS termination and proxying to Gunicorn
- **Health checks** - Built-in health monitoring for both services

## Prerequisites

- Docker Engine 20.10+ 
- Docker Compose 2.0+
- (Optional) SSL certificates for HTTPS

## Quick Start

### 1. Development/Testing

```bash
# Build and start services
docker-compose up --build

# Access the application
# HTTP: http://localhost
# Direct to app: http://localhost:8000
```

### 2. Production Deployment

#### Option A: Using Docker Compose (Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/shaunnorris/solent-marks-calculator.git
cd solent-marks-calculator

# 2. Build the images
docker-compose build

# 3. Start services in detached mode
docker-compose up -d

# 4. Check status
docker-compose ps
docker-compose logs -f
```

**Using an external reverse proxy (Caddy, Traefik, etc.)**

- Leave the bundled Nginx container disabled (it now sits behind an optional `nginx` profile).
- Bind the Flask app to any host/port by setting `WEB_HOST_PORT` in your `.env` (defaults to `8000:8000`). For production, pin it to loopback and use the prod override:
  ```bash
  export WEB_HOST_PORT=127.0.0.1:8000
  docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
  ```
- Point your reverse proxy at `http://127.0.0.1:8000` and handle TLS there (example Caddy block):
  ```caddyfile
  marks.example.com {
      reverse_proxy 127.0.0.1:8000
      encode gzip
  }
  ```
- If you still want the internal Nginx container (with its own TLS termination), enable the profile explicitly and skip the prod override:
  ```bash
  docker-compose --profile nginx up -d
  ```

#### Option B: Using Docker Only (No Nginx)

```bash
# Build the image
docker build -t solent-marks-calculator:latest .

# Run the container
docker run -d \
  --name solent-marks \
  -p 8000:8000 \
  --restart unless-stopped \
  solent-marks-calculator:latest

# Check logs
docker logs -f solent-marks
```

## Production Configuration

### SSL/TLS Setup

> **Note:** The instructions below apply to the optional bundled Nginx container. Start it with `docker-compose --profile nginx up -d` (without the production override) if you want Caddy-less deployments, and leave `WEB_HOST_PORT` unset so the container publishes 8000/80 as before.

1. **Update nginx-docker.conf** with your domain:
   ```nginx
   server_name your-domain.com;
   ```

2. **Uncomment HTTPS configuration** in `nginx-docker.conf`

3. **Add SSL certificates** to docker-compose.yml:
   ```yaml
   nginx:
     volumes:
       - ./nginx-docker.conf:/etc/nginx/conf.d/default.conf:ro
       - /etc/letsencrypt:/etc/letsencrypt:ro
   ```

4. **Restart services**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Environment Variables

Create a `.env` file for production settings:

```env
# Application
FLASK_ENV=production
WORKERS=4

# Gunicorn
GUNICORN_TIMEOUT=60
GUNICORN_KEEPALIVE=5
```

Update `docker-compose.yml` to use it:
```yaml
web:
  env_file:
    - .env
```

### Resource Limits

Add resource constraints for production:

```yaml
web:
  deploy:
    resources:
      limits:
        cpus: '1.0'
        memory: 512M
      reservations:
        cpus: '0.5'
        memory: 256M
```

## Common Operations

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f nginx
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart web
```

### Update Application

```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose up -d --build
```

### Scale Workers

```bash
# Run multiple instances
docker-compose up -d --scale web=3
```

Note: For scaling, you'll need to update nginx-docker.conf to use load balancing.

### Stop Services

```bash
# Stop without removing
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop and remove including volumes
docker-compose down -v
```

## Health Checks

The application includes built-in health checks:

- **Application**: `http://localhost:8000/` (checks Flask is responding)
- **Nginx**: `http://localhost/health` (returns "healthy")

Check health status:
```bash
docker inspect --format='{{json .State.Health}}' solent-marks-calculator
```

## Monitoring

### Container Stats

```bash
# Real-time stats
docker stats solent-marks-calculator solent-marks-nginx

# One-time stats
docker stats --no-stream
```

### Application Metrics

Gunicorn logs include:
- Request duration
- Response status codes
- Worker process info

Access via:
```bash
docker-compose logs web | grep gunicorn
```

## Backup and Recovery

### Backup GPX Data

```bash
# Export GPX file
docker cp solent-marks-calculator:/app/2025scra.gpx ./backup/

# Or use volumes in docker-compose.yml
web:
  volumes:
    - ./2025scra.gpx:/app/2025scra.gpx:ro
```

### Disaster Recovery

1. Store images in registry:
   ```bash
   docker tag solent-marks-calculator:latest your-registry/solent-marks:latest
   docker push your-registry/solent-marks:latest
   ```

2. Restore on new server:
   ```bash
   docker pull your-registry/solent-marks:latest
   docker-compose up -d
   ```

## Security Best Practices

✅ **Implemented:**
- Non-root user in container
- Multi-stage builds (smaller attack surface)
- Security headers in Nginx
- Health checks for early failure detection
- No secrets in image layers
- Read-only root filesystem compatible

🔒 **Recommended Additional Steps:**

1. **Use secrets management**:
   ```yaml
   secrets:
     ssl_cert:
       file: ./ssl/cert.pem
   ```

2. **Enable read-only filesystem**:
   ```yaml
   web:
     read_only: true
     tmpfs:
       - /tmp
   ```

3. **Run vulnerability scans**:
   ```bash
   docker scan solent-marks-calculator:latest
   ```

4. **Keep base images updated**:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs web

# Common issues:
# - Port already in use: Change ports in docker-compose.yml
# - Permission denied: Check file ownership
# - Missing files: Verify .dockerignore isn't excluding required files
```

### Application not accessible

```bash
# Check if containers are running
docker-compose ps

# Check if ports are exposed
docker port solent-marks-nginx

# Test health endpoint
curl http://localhost/health

# Check network
docker network inspect solent-marks-calculator_app-network
```

### Performance issues

```bash
# Check resource usage
docker stats

# Increase workers (update gunicorn-docker.conf.py)
workers = 4  # Adjust based on CPU cores

# Rebuild
docker-compose up -d --build
```

### SSL Certificate Issues

```bash
# Verify certificate paths
docker-compose exec nginx ls -la /etc/letsencrypt/live/your-domain/

# Test SSL configuration
docker-compose exec nginx nginx -t

# Check certificate expiry
openssl x509 -in /etc/letsencrypt/live/your-domain/fullchain.pem -noout -dates
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker image
        run: docker build -t solent-marks:${{ github.sha }} .
      
      - name: Run tests
        run: |
          docker run --rm solent-marks:${{ github.sha }} \
            pytest dev/tests/ -v
      
      - name: Push to registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push solent-marks:${{ github.sha }}
```

## Performance Tuning

### Gunicorn Workers

Rule of thumb: `(2 × CPU_cores) + 1`

```python
# gunicorn-docker.conf.py
import multiprocessing
workers = multiprocessing.cpu_count() * 2 + 1
```

### Nginx Caching

Add to nginx-docker.conf:
```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=app_cache:10m max_size=100m;

location / {
    proxy_cache app_cache;
    proxy_cache_valid 200 5m;
    # ... rest of proxy config
}
```

## Migration from Systemd

If migrating from the current systemd deployment:

1. **Stop existing service**:
   ```bash
   sudo systemctl stop solent-marks
   sudo systemctl disable solent-marks
   ```

2. **Backup data**:
   ```bash
   cp /var/www/marks.lymxod.org.uk/2025scra.gpx ~/backup/
   ```

3. **Deploy with Docker**:
   ```bash
   docker-compose up -d
   ```

4. **Update DNS/Nginx** to point to new deployment

5. **Verify** everything works, then clean up old deployment

## Support and Maintenance

### Regular Maintenance Tasks

- **Weekly**: Check logs for errors
- **Monthly**: Update base images and rebuild
- **Quarterly**: Review and rotate SSL certificates
- **Yearly**: Security audit and dependency updates

### Useful Commands Cheat Sheet

```bash
# Quick restart
docker-compose restart web

# View live logs
docker-compose logs -f --tail=100

# Execute commands in container
docker-compose exec web python -c "from app import load_gpx_marks; print(len(load_gpx_marks()))"

# Cleanup
docker system prune -a --volumes

# Export/Import images
docker save solent-marks-calculator:latest | gzip > solent-marks.tar.gz
docker load < solent-marks.tar.gz
```

## References

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Gunicorn Documentation](https://docs.gunicorn.org/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Flask Deployment](https://flask.palletsprojects.com/en/3.0.x/deploying/)
