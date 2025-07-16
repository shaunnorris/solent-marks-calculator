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

### Initial Setup (First Time)

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

### Updates (After Initial Setup)

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

### Manual Deployment

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

## File Structure

```
├── app.py                 # Main Flask application
├── templates/
│   └── index.html        # Web interface template
├── 2025scra.gpx          # GPX file with racing marks
├── first-deploy.sh       # Initial deployment script
├── update.sh             # Quick update script
├── gunicorn.conf.py      # Gunicorn configuration
├── requirements.txt      # Python dependencies
└── test_app.py          # Test suite
```

## Configuration

The application uses:
- **Gunicorn** as the WSGI server
- **systemd** for process management
- **Nginx** as reverse proxy (configured separately)

## License

This project is licensed under the MIT License. 