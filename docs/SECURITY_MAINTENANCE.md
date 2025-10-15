# Security Maintenance Guide

## Regular Security Tasks

### Weekly

**Scan Docker images for vulnerabilities:**
```bash
sudo trivy image solent-marks-calculator-web:latest
```

Focus on HIGH and CRITICAL severity issues.

### Monthly

**1. Update base image and dependencies:**
```bash
# Pull latest Python base image
docker pull python:3.12-slim

# Rebuild
sudo docker compose build --no-cache

# Test
sudo docker compose up -d

# Scan
sudo trivy image solent-marks-calculator-web:latest
```

**2. Review Python package updates:**
```bash
# Check for outdated packages (in a temp container)
docker run --rm solent-marks-calculator-web:latest \
  pip list --outdated
```

Update `requirements.txt` if security updates available.

### Quarterly

**1. Review and update SSL certificates:**
```bash
# Check expiry
sudo certbot certificates

# Renew if needed (production)
sudo certbot renew
sudo docker compose restart nginx
```

**2. Security audit:**
```bash
# Full vulnerability scan with all severities
sudo trivy image --severity LOW,MEDIUM,HIGH,CRITICAL \
  solent-marks-calculator-web:latest > security-audit.txt

# Check for secrets in image
sudo trivy image --scanners secret \
  solent-marks-calculator-web:latest
```

## Automated Security Scanning

### GitHub Actions (Already configured)

The workflow in `.github/workflows/docker-build.yml` runs:
- On every push to main
- Trivy security scanning
- Uploads results to GitHub Security tab

**To enable:**
1. Push to GitHub
2. Check Actions tab for scan results
3. Review Security tab for vulnerabilities

### Production Scanning

Add to crontab for regular scans:
```bash
# Edit crontab
crontab -e

# Add weekly scan (Sundays at 2 AM)
0 2 * * 0 /usr/bin/trivy image solent-marks-calculator-web:latest --severity HIGH,CRITICAL --quiet | mail -s "Security Scan" your@email.com
```

## Current Vulnerability Status

**Last Scan:** October 15, 2025
- **CRITICAL:** 0 ✅
- **HIGH:** 0 ✅
- **MEDIUM:** 1 (pip CVE-2025-8869 - no fix available)
- **LOW:** 51 (base OS packages - acceptable)

**Known Issues:**
- pip 25.0.1: Symbolic link extraction (MEDIUM) - No fix available. Low risk in containerized production environment.

## Security Best Practices

### Container Security

**✅ Already Implemented:**
- Non-root user (runs as `appuser`)
- Multi-stage builds
- Minimal base image (Python slim)
- No secrets in image
- Health checks
- Security headers in Nginx

**Additional Recommendations:**

1. **Read-only root filesystem:**
```yaml
# docker-compose.prod.yml
services:
  web:
    read_only: true
    tmpfs:
      - /tmp
```

2. **Limit capabilities:**
```yaml
services:
  web:
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

3. **Resource limits (already in docker-compose.prod.yml):**
```yaml
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
```

### Network Security

**Firewall rules (production server):**
```bash
# Allow only HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

**Nginx security headers (already configured):**
- X-Frame-Options: SAMEORIGIN
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Strict-Transport-Security (HTTPS only)

### Monitoring

**Watch container logs for suspicious activity:**
```bash
# Check for unusual patterns
sudo docker compose logs --tail=1000 | grep -E "(error|failed|unauthorized|403|404|500)"

# Monitor access patterns
sudo docker compose logs nginx | grep -E "GET|POST" | tail -100
```

**Set up fail2ban (production):**
```bash
sudo apt-get install fail2ban
```

Configure to ban IPs with excessive 404s or failed requests.

### Backup & Recovery

**Backup critical data:**
```bash
# GPX data file
cp 2025scra.gpx backup/2025scra-$(date +%Y%m%d).gpx

# Docker image
docker save solent-marks-calculator-web:latest | gzip > backup/image-$(date +%Y%m%d).tar.gz
```

**Test recovery:**
```bash
# Load image from backup
docker load < backup/image-20251015.tar.gz
```

## Dependency Updates

### When to Update

**Immediate (within 24 hours):**
- CRITICAL vulnerabilities
- HIGH vulnerabilities with exploits in the wild
- Security advisories from Flask, Gunicorn, Werkzeug

**Planned (within 1 week):**
- HIGH vulnerabilities (no active exploits)
- MEDIUM vulnerabilities with fixes available

**Regular cycle (monthly):**
- LOW severity issues
- General dependency updates
- Base image updates

### How to Update

1. **Update requirements.txt:**
```txt
Flask==3.0.0
gunicorn==22.0.0
Werkzeug==3.0.6
```

2. **Test locally (if possible):**
```bash
python3 -m pytest dev/tests/test_app.py -v
```

3. **Rebuild and scan:**
```bash
sudo docker compose build
sudo trivy image solent-marks-calculator-web:latest
```

4. **Deploy to test environment first:**
```bash
docker compose -f docker-compose.yml -f docker-compose.test.yml up -d
# Test functionality
```

5. **Deploy to production:**
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Incident Response

### Suspected Security Breach

1. **Isolate:**
```bash
sudo docker compose down
```

2. **Investigate logs:**
```bash
sudo docker compose logs > incident-logs-$(date +%Y%m%d-%H%M).txt
```

3. **Check for unauthorized changes:**
```bash
docker diff solent-marks-calculator
```

4. **Rebuild from clean state:**
```bash
git pull origin main
sudo docker compose build --no-cache
```

### CVE Alert Response

1. **Check if affected:**
```bash
sudo trivy image solent-marks-calculator-web:latest | grep CVE-XXXX-XXXXX
```

2. **Review severity and impact**

3. **Follow update procedure above**

4. **Document in git commit:**
```bash
git commit -m "security: fix CVE-XXXX-XXXXX by updating package X"
```

## Security Tools

### Installed

- **Trivy** - Vulnerability scanner
```bash
trivy --version
```

### Recommended Additional Tools

**Hadolint** - Dockerfile linter:
```bash
sudo apt-get install hadolint
hadolint Dockerfile
```

**Docker Bench Security** - Container security audit:
```bash
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -v /etc:/etc -v /var/lib:/var/lib -v /var/run/docker.sock:/var/run/docker.sock \
  docker/docker-bench-security
```

## Security Contacts & Resources

### Subscribe to Security Advisories

- Flask: https://palletsprojects.com/blog/
- Gunicorn: https://github.com/benoitc/gunicorn/security/advisories
- Debian Security: https://www.debian.org/security/
- Python Security: https://www.python.org/news/security/

### Vulnerability Databases

- NVD: https://nvd.nist.gov/
- Trivy DB: Updated automatically
- GitHub Security Advisories: https://github.com/advisories

## Quick Reference

### Scan Commands
```bash
# Quick scan (HIGH/CRITICAL only)
sudo trivy image --severity HIGH,CRITICAL solent-marks-calculator-web:latest

# Full scan
sudo trivy image solent-marks-calculator-web:latest

# Save report
sudo trivy image solent-marks-calculator-web:latest -f json -o security-report.json

# Scan specific package
sudo trivy image solent-marks-calculator-web:latest | grep gunicorn
```

### Update Commands
```bash
# Pull latest base image
docker pull python:3.12-slim

# Rebuild without cache
sudo docker compose build --no-cache

# Update specific service
sudo docker compose up -d --build web

# Rollback
docker tag solent-marks-calculator-web:backup solent-marks-calculator-web:latest
sudo docker compose up -d
```

### Check Commands
```bash
# Check running containers
sudo docker compose ps

# Check container health
docker inspect solent-marks-calculator | grep -A 10 Health

# Check resource usage
docker stats solent-marks-calculator

# Check for outdated images
docker images --filter "dangling=true"
```

## Compliance Checklist

Before production deployment:

- [ ] All HIGH and CRITICAL vulnerabilities resolved
- [ ] SSL/TLS certificates configured and valid
- [ ] Security headers enabled in Nginx
- [ ] Firewall rules configured
- [ ] Regular scanning scheduled
- [ ] Backup procedure in place
- [ ] Monitoring configured
- [ ] Incident response plan documented
- [ ] Security advisories subscribed
- [ ] Non-root user verified
- [ ] Read-only filesystem (optional but recommended)
- [ ] Resource limits configured

## Change Log

**2025-10-15:** Initial security audit
- Fixed Werkzeug 3.0.1 → 3.0.6 (CVE-2024-34069, CVE-2024-49766, CVE-2024-49767)
- Fixed Gunicorn 21.2.0 → 22.0.0 (CVE-2024-1135, CVE-2024-6827)
- Passed Trivy scan: 0 HIGH, 0 CRITICAL
- Image ready for production deployment

---

**Next Review Date:** November 15, 2025


