#!/bin/bash
# Install Trivy via apt package manager

set -e

echo "Installing Trivy via apt..."

# Add Trivy repository
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list

# Update and install
sudo apt-get update
sudo apt-get install trivy -y

# Verify installation
trivy --version

echo "✅ Trivy installed successfully!"


