# 2025 Solent Racing Marks Calculator

A mobile-optimized web application for calculating bearings and distances between racing marks in the Solent area. Built with Flask and designed for iPhone/Android use.

## Features

- **Zone Filtering**: Filter marks by their prefix (1, 2, 3, etc.)
- **Course Builder**: Add marks in sequence to build race courses
- **Bearing & Distance Calculation**: Calculate compass bearings and distances between marks
- **Mobile Optimized**: Touch-friendly interface for mobile devices
- **Real-time Updates**: Dynamic dropdown population based on selected zones

## Local Development

### Prerequisites

- Python 3.8+
- pip

### Setup

1. Clone the repository:
```bash
git clone https://github.com/shaunnorris/solent-marks-calculator.git
cd solent-marks-calculator
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the development server:
```bash
python3 app.py
```

4. Open http://localhost:5000 in your browser

### Running Tests

```bash
python3 -m pytest test_app.py -v
```

## Production Deployment

### Server Setup

1. **Create the virtual host directory**:
```bash
sudo mkdir -p /var/www/marks.lymcod.org.uk
sudo chown $USER:$USER /var/www/marks.lymcod.org.uk
```

2. **Set up SSL certificate** (using Let's Encrypt):
```bash
sudo certbot certonly --apache -d marks.lymcod.org.uk
```

3. **Enable required Apache modules**:
```bash
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod ssl
sudo a2enmod headers
sudo a2enmod rewrite
```

4. **Configure Apache**:
```bash
sudo cp apache2.conf /etc/apache2/sites-available/marks.lymcod.org.uk.conf
sudo a2ensite marks.lymcod.org.uk
sudo apache2ctl configtest
sudo systemctl reload apache2
```

### Automated Deployment

1. **On your local machine**, push to GitHub:
```bash
git add .
git commit -m "Your commit message"
git push origin main
```

2. **On the production server**, run the deployment script:
```bash
./deploy.sh
```

The deployment script will:
- Pull the latest code from GitHub
- Install/update dependencies
- Create a systemd service (if not exists)
- Restart the application
- Show service status

### Manual Deployment

If you prefer manual deployment:

1. SSH to your server
2. Navigate to the app directory:
```bash
cd /var/www/marks.lymcod.org.uk
```

3. Pull latest changes:
```bash
git pull origin main
```

4. Install dependencies:
```bash
python3 -m pip install --user -r requirements.txt
```

5. Restart the service:
```bash
sudo systemctl restart solent-marks
```

### Service Management

- **Check status**: `sudo systemctl status solent-marks`
- **View logs**: `sudo journalctl -u solent-marks -f`
- **Restart**: `sudo systemctl restart solent-marks`
- **Stop**: `sudo systemctl stop solent-marks`
- **Start**: `sudo systemctl start solent-marks`

### Apache Management

- **Check Apache status**: `sudo systemctl status apache2`
- **Restart Apache**: `sudo systemctl restart apache2`
- **View Apache logs**: `sudo tail -f /var/log/apache2/marks.lymcod.org.uk-error.log`

## API Endpoints

- `GET /` - Main application interface
- `GET /marks?zones=1,2` - Get marks filtered by zones
- `POST /course` - Calculate course legs (JSON: `{"marks": ["1A", "1B", "2C"]}`)

## File Structure

```
├── app.py                 # Main Flask application
├── test_app.py           # Test suite
├── requirements.txt      # Python dependencies
├── gunicorn.conf.py     # Gunicorn configuration
├── apache2.conf         # Apache2 configuration
├── deploy.sh            # Deployment script
├── 2025scra.gpx         # GPX data file
└── templates/
    └── index.html       # Main application template
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## License

This project is licensed under the MIT License. 