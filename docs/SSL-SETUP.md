# SSL/HTTPS Setup Guide

This guide will help you set up HTTPS for your Solent Marks Calculator deployment using Let's Encrypt with automatic renewal.

## Quick Start (Ubuntu 24.04)

The easiest way to set up SSL with Let's Encrypt:

```bash
# Run the automated setup script
./utils/setup-ssl.sh
```

The script will:
- ✅ Install certbot
- ✅ Obtain SSL certificates from Let's Encrypt
- ✅ Configure nginx for HTTPS
- ✅ Set up automatic renewal (both cron and systemd timer)
- ✅ Test the HTTPS connection

## Prerequisites

1. **Domain name** pointing to your server
   - Your domain's A record must point to your server's public IP
   - Verify with: `dig yourdomain.com` or `nslookup yourdomain.com`

2. **Port 80 open** (required for Let's Encrypt validation)
   - Temporarily stops Docker containers during certificate issuance
   - Firewall: `sudo ufw allow 80/tcp`

3. **Port 443 open** (for HTTPS traffic)
   - Firewall: `sudo ufw allow 443/tcp`

4. **Ubuntu 24.04** (or compatible Debian-based system)

## Manual Setup

If you prefer to set up SSL manually:

### Step 1: Install Certbot

```bash
sudo apt update
sudo apt install certbot
```

### Step 2: Stop Docker Services

```bash
docker compose down
```

### Step 3: Obtain Certificate

```bash
sudo certbot certonly --standalone \
    --preferred-challenges http \
    --agree-tos \
    --email your-email@example.com \
    -d yourdomain.com
```

### Step 4: Copy Certificates

```bash
mkdir -p ssl/certs
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/certs/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/certs/
sudo chown $USER:$USER ssl/certs/*.pem
chmod 644 ssl/certs/fullchain.pem
chmod 600 ssl/certs/privkey.pem
```

### Step 5: Configure Nginx

Edit `nginx-docker.conf`:

1. Replace `your-domain.com` with your actual domain
2. Uncomment the HTTPS server block (lines starting with `#`)
3. Uncomment SSL certificate paths
4. Uncomment HTTP to HTTPS redirect

### Step 6: Update Docker Compose

Edit `docker-compose.yml` and add SSL volume mount to nginx service:

```yaml
nginx:
  volumes:
    - ./nginx-docker.conf:/etc/nginx/conf.d/default.conf:ro
    - ./ssl/certs:/etc/nginx/ssl:ro  # Add this line
```

### Step 7: Start Services

```bash
docker compose up -d
```

### Step 8: Test HTTPS

```bash
curl -I https://yourdomain.com
```

## Automatic Renewal

The `setup-ssl.sh` script configures **two** renewal methods for redundancy:

### Method 1: Systemd Timer (Recommended)

Runs daily, with automatic retries and better logging.

**Check status:**
```bash
sudo systemctl status solent-marks-ssl-renewal.timer
```

**View next run time:**
```bash
sudo systemctl list-timers solent-marks-ssl-renewal.timer
```

**Test renewal manually:**
```bash
sudo systemctl start solent-marks-ssl-renewal.service
```

**View logs:**
```bash
sudo journalctl -u solent-marks-ssl-renewal.service
```

### Method 2: Cron Job (Fallback)

Runs daily at 3 AM as a backup.

**View cron job:**
```bash
sudo crontab -l | grep renew-ssl
```

**Test renewal script:**
```bash
sudo /usr/local/bin/renew-ssl-solent-marks.sh
```

**View renewal logs:**
```bash
sudo tail -f /var/log/solent-marks-ssl-renewal.log
```

## Certificate Information

**Certificate location:** `/etc/letsencrypt/live/yourdomain.com/`
- `fullchain.pem` - Certificate + intermediate certs
- `privkey.pem` - Private key

**Project copies:** `ssl/certs/`
- Copies used by Docker nginx container
- Updated automatically on renewal

**Expiration:** 90 days
**Auto-renewal:** Attempts renewal when < 30 days remain
**Renewal check:** Daily at 3 AM (both methods)

## Troubleshooting

### Certificate Issuance Failed

**Error:** "Unable to obtain certificate"

**Solutions:**
1. Verify DNS: `dig yourdomain.com` should show your server's IP
2. Check port 80 is open: `sudo netstat -tlnp | grep :80`
3. Ensure Docker is stopped: `docker compose down`
4. Check firewall: `sudo ufw status`
5. Try again with verbose output: `sudo certbot certonly --standalone -d yourdomain.com -v`

### Nginx Won't Start with SSL

**Error:** "Cannot load certificate"

**Solutions:**
1. Verify certificates exist:
   ```bash
   ls -l ssl/certs/
   ```

2. Check certificate permissions:
   ```bash
   chmod 644 ssl/certs/fullchain.pem
   chmod 600 ssl/certs/privkey.pem
   ```

3. Test nginx configuration:
   ```bash
   docker compose exec nginx nginx -t
   ```

4. View nginx logs:
   ```bash
   docker compose logs nginx
   ```

### Renewal Failed

**Check renewal logs:**
```bash
# Systemd logs
sudo journalctl -u solent-marks-ssl-renewal.service -n 50

# Cron logs
sudo tail -50 /var/log/solent-marks-ssl-renewal.log
```

**Manual renewal test:**
```bash
# Dry run (test only)
sudo certbot renew --dry-run

# Force renewal (for testing)
sudo certbot renew --force-renewal
```

**Common issues:**
- Port 80 blocked
- Docker containers not running
- File permission issues
- Nginx not reloading

### HTTPS Not Working

**Check SSL certificate validity:**
```bash
echo | openssl s_client -connect yourdomain.com:443 -servername yourdomain.com 2>/dev/null | openssl x509 -noout -dates
```

**Test with curl:**
```bash
curl -I https://yourdomain.com
```

**Check nginx is listening on 443:**
```bash
docker compose exec nginx netstat -tlnp | grep 443
```

**Verify certificate files match:**
```bash
# These should output the same hash
openssl x509 -noout -modulus -in ssl/certs/fullchain.pem | openssl md5
openssl rsa -noout -modulus -in ssl/certs/privkey.pem | openssl md5
```

## Testing SSL Configuration

### SSL Labs Test
Visit: https://www.ssllabs.com/ssltest/analyze.html?d=yourdomain.com

### Local Tests

**Certificate info:**
```bash
openssl x509 -in ssl/certs/fullchain.pem -text -noout
```

**Certificate expiry:**
```bash
openssl x509 -in ssl/certs/fullchain.pem -noout -dates
```

**Test HTTPS connection:**
```bash
curl -vI https://yourdomain.com
```

**Test HTTP to HTTPS redirect:**
```bash
curl -I http://yourdomain.com
```

## Security Best Practices

1. ✅ **Keep certificates private** - Never commit to git (already in `.gitignore`)
2. ✅ **Use strong protocols** - TLSv1.2 and TLSv1.3 only (already configured)
3. ✅ **Enable HSTS** - Configured automatically in nginx
4. ✅ **Monitor expiration** - Automatic renewal checks daily
5. ✅ **Use OCSP stapling** - Configured in nginx for better performance
6. ✅ **Regular updates** - Keep certbot and nginx updated

## Monitoring Certificate Expiration

### Check when certificate expires:

```bash
# Method 1: OpenSSL
openssl x509 -in ssl/certs/fullchain.pem -noout -enddate

# Method 2: Certbot
sudo certbot certificates

# Method 3: Online
echo | openssl s_client -connect yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates
```

### Set up expiration alerts:

Add to your monitoring system or create a simple check:

```bash
# Check days until expiry
DAYS=$(( ($(date -d "$(openssl x509 -in ssl/certs/fullchain.pem -noout -enddate | cut -d= -f2)" +%s) - $(date +%s)) / 86400 ))
if [ $DAYS -lt 30 ]; then
    echo "WARNING: Certificate expires in $DAYS days!"
fi
```

## Revoking a Certificate

If you need to revoke a certificate (compromised key, etc.):

```bash
sudo certbot revoke --cert-path /etc/letsencrypt/live/yourdomain.com/cert.pem
```

Then obtain a new one:

```bash
./utils/setup-ssl.sh
```

## Multiple Domains

To add multiple domains to the same certificate:

```bash
sudo certbot certonly --standalone \
    -d yourdomain.com \
    -d www.yourdomain.com \
    -d marks.yourdomain.com
```

Update `nginx-docker.conf` to list all domains in `server_name`.

## Wildcard Certificates

For wildcard certificates (*.yourdomain.com), you need DNS validation:

```bash
sudo certbot certonly --manual \
    --preferred-challenges dns \
    -d "*.yourdomain.com" \
    -d yourdomain.com
```

Follow the prompts to add DNS TXT records.

## Rate Limits

Let's Encrypt has rate limits:
- **50** certificates per registered domain per week
- **5** duplicate certificates per week
- **300** account registrations per IP per 3 hours

If you hit rate limits, wait or use the staging environment for testing:
```bash
sudo certbot certonly --staging --standalone -d yourdomain.com
```

## Getting Help

- **Let's Encrypt docs:** https://letsencrypt.org/docs/
- **Certbot docs:** https://eff-certbot.readthedocs.io/
- **SSL Labs:** https://www.ssllabs.com/
- **Project issues:** https://github.com/shaunnorris/solent-marks-calculator/issues

## Files Modified by SSL Setup

- `ssl/certs/fullchain.pem` - SSL certificate (created)
- `ssl/certs/privkey.pem` - Private key (created)
- `nginx-docker.conf` - Nginx configuration (modified)
- `nginx-docker.conf.backup` - Backup of original (created)
- `docker-compose.yml` - Docker configuration (modified)
- `/usr/local/bin/renew-ssl-solent-marks.sh` - Renewal script (created)
- `/etc/systemd/system/solent-marks-ssl-renewal.*` - Systemd files (created)
- `/var/log/solent-marks-ssl-renewal.log` - Renewal logs (created)

All certificate files are excluded from git via `.gitignore`.

