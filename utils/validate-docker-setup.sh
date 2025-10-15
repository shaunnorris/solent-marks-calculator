#!/bin/bash
# Validate Docker setup without requiring Docker to be installed
# This checks syntax, file existence, and configuration validity

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Docker Setup Validation (Pre-Install)              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0
WARNINGS=0

# Function to check if file exists
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo "✅ $description: $file"
        return 0
    else
        echo "❌ $description missing: $file"
        ((ERRORS++))
        return 1
    fi
}

# Function to check file is executable
check_executable() {
    local file=$1
    local description=$2
    
    if [ -x "$file" ]; then
        echo "✅ $description is executable: $file"
        return 0
    else
        echo "⚠️  $description not executable: $file"
        echo "   Fix with: chmod +x $file"
        ((WARNINGS++))
        return 1
    fi
}

echo "📋 Checking Required Files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check Docker configuration files
check_file "Dockerfile" "Dockerfile"
check_file "docker-compose.yml" "Docker Compose file"
check_file ".dockerignore" "Docker ignore file"
check_file "nginx-docker.conf" "Nginx configuration"
check_file "gunicorn-docker.conf.py" "Gunicorn configuration"

echo ""

# Check scripts
echo "📋 Checking Scripts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_file "docker-quick-start.sh" "Quick start script"
check_executable "docker-quick-start.sh" "Quick start script"

check_file "install-docker-wsl2.sh" "Docker install script"
check_executable "install-docker-wsl2.sh" "Docker install script"

check_file "Makefile" "Makefile"

echo ""

# Check application files
echo "📋 Checking Application Files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_file "app.py" "Flask application"
check_file "requirements.txt" "Python requirements"
check_file "2025scra.gpx" "GPX data file"

if [ -d "templates" ]; then
    echo "✅ Templates directory exists"
    if [ -f "templates/index.html" ]; then
        echo "✅ Template file: templates/index.html"
    else
        echo "❌ Missing template: templates/index.html"
        ((ERRORS++))
    fi
else
    echo "❌ Templates directory missing"
    ((ERRORS++))
fi

echo ""

# Validate YAML syntax
echo "🔍 Validating Configuration Syntax..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v python3 &> /dev/null; then
    # Test docker-compose.yml
    if python3 -c "import yaml; yaml.safe_load(open('docker-compose.yml'))" 2>/dev/null; then
        echo "✅ docker-compose.yml syntax valid"
    else
        echo "❌ docker-compose.yml syntax error"
        ((ERRORS++))
    fi
    
    # Test gunicorn config
    if python3 -c "compile(open('gunicorn-docker.conf.py').read(), 'gunicorn-docker.conf.py', 'exec')" 2>/dev/null; then
        echo "✅ gunicorn-docker.conf.py syntax valid"
    else
        echo "❌ gunicorn-docker.conf.py syntax error"
        ((ERRORS++))
    fi
    
    # Test app.py
    if python3 -c "compile(open('app.py').read(), 'app.py', 'exec')" 2>/dev/null; then
        echo "✅ app.py syntax valid"
    else
        echo "❌ app.py syntax error"
        ((ERRORS++))
    fi
else
    echo "⚠️  Python3 not available, skipping syntax validation"
    ((WARNINGS++))
fi

echo ""

# Check Dockerfile syntax (basic check)
echo "🔍 Checking Dockerfile..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if grep -q "FROM python:3.12-slim" Dockerfile; then
    echo "✅ Dockerfile uses correct base image"
else
    echo "⚠️  Dockerfile may not use expected base image"
    ((WARNINGS++))
fi

if grep -q "COPY --chown=appuser:appuser" Dockerfile; then
    echo "✅ Dockerfile uses non-root user"
else
    echo "⚠️  Dockerfile may not set proper ownership"
    ((WARNINGS++))
fi

if grep -q "HEALTHCHECK" Dockerfile; then
    echo "✅ Dockerfile includes health check"
else
    echo "⚠️  Dockerfile missing health check"
    ((WARNINGS++))
fi

echo ""

# Check nginx config
echo "🔍 Checking Nginx Configuration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if grep -q "upstream gunicorn" nginx-docker.conf; then
    echo "✅ Nginx upstream configured"
else
    echo "❌ Nginx upstream not found"
    ((ERRORS++))
fi

if grep -q "proxy_pass" nginx-docker.conf; then
    echo "✅ Nginx proxy configuration found"
else
    echo "❌ Nginx proxy configuration missing"
    ((ERRORS++))
fi

if grep -q "add_header" nginx-docker.conf; then
    echo "✅ Nginx security headers configured"
else
    echo "⚠️  Nginx security headers may be missing"
    ((WARNINGS++))
fi

echo ""

# Check documentation
echo "📚 Checking Documentation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_file "DOCKER_DEPLOYMENT.md" "Docker deployment guide"
check_file "DEPLOYMENT_SUMMARY.md" "Deployment summary"
check_file "RECOMMENDATIONS.md" "Recommendations document"
check_file ".docker-validation-checklist.md" "Validation checklist"

echo ""

# Summary
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                     Validation Summary                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "🎉 All checks passed! Configuration is valid."
    echo ""
    echo "Next steps:"
    echo "  1. Install Docker: ./install-docker-wsl2.sh"
    echo "  2. Test setup: ./docker-quick-start.sh"
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Validation passed with $WARNINGS warning(s)"
    echo ""
    echo "The setup should work, but review warnings above."
    echo ""
    echo "Next steps:"
    echo "  1. Install Docker: ./install-docker-wsl2.sh"
    echo "  2. Test setup: ./docker-quick-start.sh"
else
    echo "❌ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)"
    echo ""
    echo "Please fix the errors above before proceeding."
    exit 1
fi

echo ""
echo "📖 For detailed information, see:"
echo "   - DOCKER_DEPLOYMENT.md (comprehensive guide)"
echo "   - RECOMMENDATIONS.md (strategic overview)"
echo "   - INSTALL_DOCKER_WSL2.md (Docker installation help)"
echo ""

