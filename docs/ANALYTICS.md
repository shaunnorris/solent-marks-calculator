# Analytics Setup Guide

The Solent Racing Mark Bearing Calculator includes integrated **Umami Analytics** - a lightweight, privacy-friendly, open-source analytics solution.

## Features

- ✅ **Privacy-first**: No cookies, GDPR compliant
- ✅ **Lightweight**: < 2KB tracking script
- ✅ **Self-hosted**: Your data stays on your server
- ✅ **Real-time**: Live visitor tracking
- ✅ **Integrated**: Deployed with your app automatically

## Access Analytics Dashboard

**URL**: https://bearings.lymxod.org.uk/analytics

**Default Login:**
- Username: `admin`
- Password: `umami`

⚠️ **IMPORTANT**: Change the default password immediately after first login!

## First-Time Setup

After deploying the app, analytics will be available but tracking will use a "placeholder" ID. Follow these steps to activate tracking:

### 1. Login to Analytics Dashboard

Visit https://your-domain.com/analytics and login:
- **Username**: `admin`
- **Password**: `umami`

### 2. Change Password

1. Click on your profile (top right)
2. Go to "Profile"  
3. Click "Change password"
4. Set a strong password

### 3. Add Your Website

1. Go to "Settings" → "Websites"
2. Click "Add website"
3. Enter:
   - **Name**: Solent Bearings Calculator
   - **Domain**: your-domain.com
   - **Enable share URL**: (optional)
4. Click "Save"
5. **Copy the Website ID** (looks like: `f0e5b8c5-a009-4b4d-8632-dd6167d4f3df`)

### 4. Update Environment Variable

Set the website ID on your server:

```bash
cd /opt/bearings-app

# Create .env file with your website ID
echo "UMAMI_WEBSITE_ID=f0e5b8c5-a009-4b4d-8632-dd6167d4f3df" > .env

# Restart services to apply
sudo docker compose up -d
```

That's it! Analytics tracking is now active. Visit your site and check the dashboard to see real-time stats.

## Configuration

### Environment Variables

Set in `/opt/bearings-app/.env`:

```bash
# Generate a random secret (required for production)
UMAMI_SECRET=$(openssl rand -base64 32)
```

Then restart:
```bash
cd /opt/bearings-app
sudo docker compose up -d
```

### Database

Analytics data is stored in PostgreSQL:
- **Container**: `bearings-analytics-db`
- **Volume**: `umami-data`
- **Backup**: Included in Docker volume backups

## Usage

### View Analytics

Visit https://bearings.lymxod.org.uk/analytics to see:
- Real-time visitors
- Page views
- Traffic sources
- Geographic data
- Browser/device stats

### Custom Events (Optional)

Track custom events in your app:

```javascript
// Track button clicks
umami.track('calculate-bearing', { zone: '2' });

// Track mark selections
umami.track('mark-selected', { mark: '2A' });
```

## Backup & Restore

### Backup Analytics Data

```bash
cd /opt/bearings-app
docker compose exec umami-db pg_dump -U umami umami > umami-backup.sql
```

### Restore Analytics Data

```bash
cd /opt/bearings-app
cat umami-backup.sql | docker compose exec -T umami-db psql -U umami umami
```

## Troubleshooting

### Analytics not loading

1. Check containers are running:
```bash
cd /opt/bearings-app
sudo docker compose ps
```

2. Check logs:
```bash
sudo docker compose logs umami
sudo docker compose logs umami-db
```

### Can't login

Reset admin password:
```bash
cd /opt/bearings-app
docker compose exec umami-db psql -U umami umami -c \
  "UPDATE account SET password = '\$2b\$10\$BUli0c.muyCW1ErNJc3jL.vFRFtFJWrT8/GcR4A.sUdSDRXrvCmP6' WHERE username = 'admin';"
```
This resets password to: `umami`

### Database issues

Recreate database:
```bash
cd /opt/bearings-app
sudo docker compose down
sudo docker volume rm bearings-app_umami-data
sudo docker compose up -d
```

## Privacy & GDPR

Umami is **fully GDPR compliant**:
- ✅ No cookies
- ✅ No personal data collection
- ✅ All data anonymized
- ✅ Self-hosted (you control the data)
- ✅ No third-party services

**You don't need a cookie banner or GDPR notice** when using Umami.

## Upgrading

To upgrade Umami to the latest version:

```bash
cd /opt/bearings-app
sudo docker compose pull umami
sudo docker compose up -d
```

## Uninstalling

To remove analytics completely:

```bash
cd /opt/bearings-app
sudo docker compose down
sudo docker volume rm bearings-app_umami-data
```

Then remove the analytics sections from `docker-compose.yml` and `nginx.conf`.

## Support

- **Umami Docs**: https://umami.is/docs
- **GitHub**: https://github.com/umami-software/umami
- **Issues**: Report via GitHub issues

## Security Notes

1. **Change default password** immediately
2. **Use strong passwords** for admin account
3. **Set UMAMI_SECRET** environment variable
4. **Regular backups** of analytics data
5. **Keep Umami updated** for security patches

