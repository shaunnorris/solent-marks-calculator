# Solent Marks Calculator

A Flask web application for calculating bearings and distances between racing marks using GPX data.

## Features

- Load racing marks from GPX files
- Filter marks by zones
- Build race courses by selecting marks
- Calculate bearings and distances between course legs
- Modern, responsive web interface

## Development

### Setup

1. Clone the repository:
```bash
git clone https://github.com/shaunnorris/solent-marks-calculator.git
cd solent-marks-calculator
```

2. Install dependencies:
```bash
python3 -m pip install -r requirements.txt
```

3. Run the development server:
```bash
python3 -m flask run --host=0.0.0.0 --port=5000
```

The application will be available at `http://localhost:5000`

### Testing

Run tests using pytest:
```bash
python3 -m pytest test_app.py -v
```

## Production Deployment

### Docker Deployment (Recommended)

**Quick Start:**
```bash
# Build and start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

The application will be available at `http://localhost`

**Using Make (convenience commands):**
```bash
make prod-up      # Build and start
make logs         # View logs
make health       # Check health
make update       # Pull latest and rebuild
```

📖 **See [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md) for comprehensive Docker deployment guide**
🔒 **See [SSL-SETUP.md](SSL-SETUP.md) for HTTPS/SSL configuration with auto-renewal**

### Traditional Deployment (Systemd)

<details>
<summary>Click to expand systemd deployment instructions</summary>

#### Initial Setup (First Time)

Use the `first-deploy.sh` script for initial server setup:

```bash
# On your production server
chmod +x first-deploy.sh
./first-deploy.sh
```

This script will:
- Create the application directory
- Clone the repository
- Set up Python virtual environment
- Install dependencies
- Configure Gunicorn
- Create and enable systemd service
- Set proper permissions

#### Updates (After Initial Setup)

Use the `update.sh` script for quick code updates:

```bash
# On your production server
chmod +x update.sh
./update.sh
```

This script will:
- Pull the latest code from GitHub
- Restart the service
- Show service status

#### Manual Deployment

If you prefer manual deployment:

```bash
# SSH into your production server
cd /var/www/marks.lymxod.org.uk

# Pull latest changes
git fetch origin
git reset --hard origin/main

# Restart the service
sudo systemctl restart solent-marks

# Check status
sudo systemctl status solent-marks
```
</details>

## File Structure

```
├── app.py                    # Main Flask application
├── templates/
│   └── index.html           # Web interface template
├── 2025scra.gpx             # GPX file with racing marks
├── requirements.txt         # Python dependencies
│
├── Docker files
├── Dockerfile               # Multi-stage Docker build
├── docker-compose.yml       # Docker Compose orchestration
├── .dockerignore            # Docker build exclusions
├── nginx-docker.conf        # Nginx configuration for Docker
├── gunicorn-docker.conf.py  # Gunicorn config for Docker
├── DOCKER_DEPLOYMENT.md     # Comprehensive Docker guide
├── Makefile                 # Convenience commands
│
├── Tests
├── dev/tests/test_app.py    # Test suite
│
├── CI/CD
├── .github/workflows/       # GitHub Actions
│
└── Legacy deployment (systemd)
    ├── first-deploy.sh      # Initial deployment script
    ├── update.sh            # Quick update script
    ├── gunicorn.conf.py     # Gunicorn configuration
    └── nginx.conf           # Nginx configuration
```

## Configuration

### Docker Deployment
- **Gunicorn** as the WSGI server (3 workers)
- **Nginx** as reverse proxy (included in docker-compose)
- **Docker Compose** for orchestration
- **Health checks** for monitoring

### Traditional Deployment
- **Gunicorn** as the WSGI server
- **systemd** for process management
- **Nginx** as reverse proxy (configured separately)

## License

This project is licensed under the MIT License. 