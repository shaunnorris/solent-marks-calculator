# Production Deployment Guide

This guide covers deploying the Solent Racing Mark Bearing Calculator to a production server using Docker.

## Prerequisites

- Ubuntu 24.04 (or similar Linux distribution)
- Docker and Docker Compose installed
- Domain name pointing to your server
- Root/sudo access
- Ports 80 and 443 open

## One-Command Deployment

For a fresh deployment, simply run:

```bash
curl -sSL https://raw.githubusercontent.com/shaunnorris/solent-marks-calculator/main/deploy.sh | sudo bash
```

The script will:
1. Prompt for your domain name
2. Prompt for your email (for SSL certificate notifications)
3. Download configuration files
4. Pull the latest Docker image
5. Start the application
6. Obtain SSL certificate from Let's Encrypt
7. Configure HTTPS
8. Set up automatic SSL renewal
9. Create management scripts

## Manual Deployment

If you prefer manual setup:

### Step 1: Create Deployment Directory

```bash
sudo mkdir -p /opt/bearings-app
cd /opt/bearings-app
```

### Step 2: Download Configuration Files

```bash
sudo curl -sSL https://raw.githubusercontent.com/shaunnorris/solent-marks-calculator/main/docker-compose.production.yml -o docker-compose.yml
sudo curl -sSL https://raw.githubusercontent.com/shaunnorris/solent-marks-calculator/main/nginx-production.conf -o nginx.conf
```

### Step 3: Update Configuration

Replace `DOMAIN_NAME` in `nginx.conf` with your actual domain:

```bash
sudo sed -i 's/DOMAIN_NAME/your-domain.com/g' nginx.conf
```

### Step 4: Start Services (HTTP only)

```bash
sudo docker pull ghcr.io/shaunnorris/solent-marks-calculator:latest
sudo docker compose up -d
```

### Step 5: Get SSL Certificate

```bash
# Install certbot
sudo apt install -y certbot

# Stop nginx temporarily
sudo docker compose stop nginx

# Get certificate
sudo certbot certonly --standalone -d your-domain.com

# Restart nginx
sudo docker compose start nginx
```

### Step 6: Enable HTTPS

Edit `nginx.conf` to uncomment the HTTPS section and update the HTTP section to redirect to HTTPS.

```bash
sudo docker compose restart nginx
```

## Management

### View Logs

```bash
cd /opt/bearings-app
sudo docker compose logs -f
```

### Restart Services

```bash
cd /opt/bearings-app
sudo docker compose restart
```

### Update to Latest Version

```bash
cd /opt/bearings-app
sudo docker pull ghcr.io/shaunnorris/solent-marks-calculator:latest
sudo docker compose up -d
sudo docker image prune -f
```

Or use the update script created during deployment:

```bash
sudo /opt/bearings-app/update.sh
```

### Check Status

```bash
cd /opt/bearings-app
sudo docker compose ps
```

### Stop Services

```bash
cd /opt/bearings-app
sudo docker compose down
```

### Reconfigure

To reconfigure the domain or SSL:

```bash
curl -sSL https://raw.githubusercontent.com/shaunnorris/solent-marks-calculator/main/deploy.sh | sudo bash
```

The script will detect existing configuration and offer options.

## SSL Certificate Renewal

SSL certificates from Let's Encrypt are automatically renewed. The deployment script sets up:

- Systemd timer for automatic renewal
- Post-renewal hook to reload Nginx

To manually test renewal:

```bash
sudo certbot renew --dry-run
```

To force renewal:

```bash
sudo certbot renew
```

## Firewall Configuration

If using UFW:

```bash
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

## Troubleshooting

### Services not starting

Check logs:
```bash
cd /opt/bearings-app
sudo docker compose logs
```

### SSL certificate issues

Verify DNS is pointing to your server:
```bash
nslookup your-domain.com
```

Check certificate status:
```bash
sudo certbot certificates
```

### Port conflicts

Check what's using ports 80/443:
```bash
sudo netstat -tulpn | grep -E ':(80|443)'
```

### Nginx configuration errors

Test configuration:
```bash
cd /opt/bearings-app
sudo docker compose exec nginx nginx -t
```

## Directory Structure

```
/opt/bearings-app/
├── docker-compose.yml      # Docker Compose configuration
├── nginx.conf              # Nginx configuration
├── update.sh               # Update script
├── .configured             # Configuration marker
└── .domain                 # Stored domain name
```

## Security Considerations

- Keep Docker and system packages updated
- Regularly update to the latest app version
- Monitor logs for suspicious activity
- Use strong passwords for any admin interfaces
- Keep SSL certificates up to date (automatic)

## Support

For issues or questions:
- GitHub: https://github.com/shaunnorris/solent-marks-calculator
- Check logs first: `sudo docker compose -f /opt/bearings-app/docker-compose.yml logs`

