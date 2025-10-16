# SSL Certificate Configuration

This directory is for storing your SSL/TLS certificates for HTTPS support.

## Directory Structure

```
ssl/
├── certs/           # Place your SSL certificates here
│   ├── fullchain.pem  # Your certificate + intermediate certs
│   └── privkey.pem    # Your private key
├── example/         # Example self-signed certificates for testing
└── README.md        # This file
```

## Quick Start

### Option 1: Use Let's Encrypt (Recommended for Production)

1. **Install certbot:**
   ```bash
   sudo apt install certbot
   ```

2. **Generate certificates:**
   ```bash
   sudo certbot certonly --standalone -d yourdomain.com
   ```

3. **Copy certificates to this directory:**
   ```bash
   sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/certs/
   sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/certs/
   sudo chown $USER:$USER ssl/certs/*.pem
   chmod 600 ssl/certs/privkey.pem
   chmod 644 ssl/certs/fullchain.pem
   ```

4. **Update nginx configuration:**
   - Edit `nginx-docker.conf`
   - Uncomment the HTTPS server block (lines 48-87)
   - Update `server_name` to your domain
   - Uncomment the HTTP to HTTPS redirect (line 10)

5. **Update docker-compose.yml:**
   - Uncomment the SSL volume mount in the nginx service:
     ```yaml
     volumes:
       - ./nginx-docker.conf:/etc/nginx/conf.d/default.conf:ro
       - ./ssl/certs:/etc/nginx/ssl:ro
     ```

6. **Restart services:**
   ```bash
   docker compose down
   docker compose up -d
   ```

### Option 2: Use Your Own Certificates

If you have certificates from another CA:

1. **Copy your certificates:**
   ```bash
   cp /path/to/your/fullchain.pem ssl/certs/
   cp /path/to/your/privkey.pem ssl/certs/
   chmod 600 ssl/certs/privkey.pem
   chmod 644 ssl/certs/fullchain.pem
   ```

2. Follow steps 4-6 from Option 1 above.

### Option 3: Self-Signed Certificates (Testing Only)

For local development or testing (not recommended for production):

1. **Generate self-signed certificate:**
   ```bash
   cd ssl/example
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout privkey.pem \
     -out fullchain.pem \
     -subj "/C=GB/ST=Hampshire/L=Southampton/O=Test/CN=localhost"
   cd ../..
   ```

2. **Copy to certs directory:**
   ```bash
   cp ssl/example/*.pem ssl/certs/
   chmod 600 ssl/certs/privkey.pem
   chmod 644 ssl/certs/fullchain.pem
   ```

3. Follow steps 4-6 from Option 1 above.

## Nginx Configuration

The nginx configuration supports two modes:

### HTTP Only (Default)
- Port 80 enabled
- No SSL required
- Good for: local development, testing

### HTTPS Enabled
- Port 443 with SSL/TLS
- HTTP redirects to HTTPS
- Requires: valid certificates in `ssl/certs/`
- Good for: production deployments

## Certificate Renewal (Let's Encrypt)

Let's Encrypt certificates expire after 90 days. To renew:

```bash
# Renew certificate
sudo certbot renew

# Copy renewed certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/certs/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/certs/
sudo chown $USER:$USER ssl/certs/*.pem

# Reload nginx
docker compose exec nginx nginx -s reload
```

Consider setting up a cron job for automatic renewal:

```bash
# Add to crontab (sudo crontab -e)
0 3 * * 0 certbot renew --quiet && cp /etc/letsencrypt/live/yourdomain.com/*.pem /path/to/ssl/certs/ && docker compose -f /path/to/docker-compose.yml exec nginx nginx -s reload
```

## Security Best Practices

1. **Never commit certificates to git** - They're already in `.gitignore`
2. **Use restrictive permissions:**
   - Private key: `chmod 600 privkey.pem`
   - Certificate: `chmod 644 fullchain.pem`
3. **Use Let's Encrypt for production** - Free, automated, trusted
4. **Monitor certificate expiration** - Set up alerts 30 days before expiry
5. **Test your SSL configuration:** https://www.ssllabs.com/ssltest/

## Troubleshooting

### "Permission denied" errors
```bash
# Fix file permissions
chmod 600 ssl/certs/privkey.pem
chmod 644 ssl/certs/fullchain.pem
```

### "Certificate file not found"
```bash
# Verify files exist
ls -la ssl/certs/
# Should show: fullchain.pem and privkey.pem
```

### "Certificate and key don't match"
```bash
# Verify certificate matches key
openssl x509 -noout -modulus -in ssl/certs/fullchain.pem | openssl md5
openssl rsa -noout -modulus -in ssl/certs/privkey.pem | openssl md5
# Output should be identical
```

### Nginx won't start
```bash
# Check nginx configuration syntax
docker compose exec nginx nginx -t

# View nginx logs
docker compose logs nginx
```

## Files Ignored by Git

The following are automatically ignored by `.gitignore`:
- `ssl/certs/*.pem` - Your actual certificates
- `ssl/certs/*.key` - Private keys
- `ssl/example/*.pem` - Test certificates

Only this README is tracked in git.

