#!/bin/bash
# Quick start script for Docker deployment
# This script builds and starts the application with basic health checks

set -e

echo "========================================"
echo "Solent Marks Calculator - Docker Setup"
echo "========================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed"
    echo "   Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: Docker Compose is not installed"
    echo "   Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "❌ Error: Docker daemon is not running"
    echo "   Please start Docker and try again"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"
echo ""

# Stop existing containers if running
echo "🔄 Stopping any existing containers..."
docker-compose down 2>/dev/null || true
echo ""

# Build images
echo "🔨 Building Docker images..."
docker-compose build
echo ""

# Start services
echo "🚀 Starting services..."
docker-compose up -d
echo ""

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check container status
echo ""
echo "📊 Container Status:"
docker-compose ps
echo ""

# Test application
echo "🧪 Testing application..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80/health | grep -q "200"; then
    echo "✅ Nginx health check: PASSED"
else
    echo "⚠️  Nginx health check: FAILED"
fi

if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ | grep -q "200"; then
    echo "✅ Application health check: PASSED"
else
    echo "⚠️  Application health check: FAILED"
fi
echo ""

# Display access information
echo "========================================"
echo "✅ Deployment Complete!"
echo "========================================"
echo ""
echo "Access the application at:"
echo "  • http://localhost (via Nginx)"
echo "  • http://localhost:8000 (direct to app)"
echo ""
echo "Useful commands:"
echo "  • View logs:        docker-compose logs -f"
echo "  • Stop services:    docker-compose down"
echo "  • Restart services: docker-compose restart"
echo "  • Check status:     docker-compose ps"
echo ""
echo "Or use the Makefile:"
echo "  • make logs         View logs"
echo "  • make health       Check health"
echo "  • make down         Stop services"
echo ""
echo "📖 See DOCKER_DEPLOYMENT.md for full documentation"
echo ""

