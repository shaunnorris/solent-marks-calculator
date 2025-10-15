#!/bin/bash
# Docker installation script for WSL2
# This installs Docker Engine directly in WSL2

set -e

echo "=========================================="
echo "Docker Installation for WSL2"
echo "=========================================="
echo ""

# Check if running in WSL2
if ! grep -qi microsoft /proc/version; then
    echo "⚠️  This script is designed for WSL2"
    echo "   If you're on native Linux, it should still work"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo "✅ Docker is already installed"
    docker --version
    echo ""
    echo "Would you like to reinstall? (y/n)"
    read -p "" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

echo "📦 Installing Docker Engine..."
echo ""

# Update package list
echo "Updating package list..."
sudo apt-get update -qq

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo "Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true

# Set up the repository
echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "Installing Docker Engine..."
sudo apt-get update -qq
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
echo "Adding user to docker group..."
sudo usermod -aG docker $USER

# Start Docker service
echo "Starting Docker service..."
sudo service docker start 2>/dev/null || true

echo ""
echo "=========================================="
echo "✅ Docker Installation Complete!"
echo "=========================================="
echo ""

# Verify installation
if command -v docker &> /dev/null; then
    echo "Docker version:"
    docker --version
    echo ""
    echo "Docker Compose version:"
    docker compose version
    echo ""
else
    echo "❌ Installation may have failed"
    exit 1
fi

echo "⚠️  IMPORTANT: You may need to log out and back in"
echo "   for group permissions to take effect."
echo ""
echo "Or run: newgrp docker"
echo ""
echo "To test Docker, run:"
echo "  docker run hello-world"
echo ""
echo "To test Solent Marks Calculator:"
echo "  ./docker-quick-start.sh"
echo ""

