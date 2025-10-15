# Installing Docker on WSL2

## Option 1: Docker Desktop for Windows (Recommended - Easiest)

This is the simplest approach for WSL2:

1. **Download Docker Desktop for Windows**:
   - Visit: https://www.docker.com/products/docker-desktop
   - Download and install Docker Desktop

2. **Enable WSL2 Integration**:
   - Open Docker Desktop
   - Go to Settings → Resources → WSL Integration
   - Enable integration with your WSL2 distro (Ubuntu)
   - Click "Apply & Restart"

3. **Verify in WSL2**:
   ```bash
   docker --version
   docker-compose --version
   ```

4. **Test the setup**:
   ```bash
   cd /home/shaun/projects/solent-marks-calculator
   ./docker-quick-start.sh
   ```

## Option 2: Docker Engine in WSL2 (Advanced)

If you prefer to run Docker entirely within WSL2:

### Step 1: Install Docker Engine

```bash
# Update package list
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group
sudo usermod -aG docker $USER
```

### Step 2: Start Docker Service

```bash
# Start Docker
sudo service docker start

# Enable Docker to start on boot (if using systemd in WSL2)
# sudo systemctl enable docker
```

### Step 3: Verify Installation

```bash
docker --version
docker compose version
```

### Step 4: Test Docker

```bash
docker run hello-world
```

## Quick Installation Script

I can create a script to automate Option 2:

```bash
# Run this in WSL2
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# You may need to log out and back in for group changes to take effect
```

## After Installation

Once Docker is installed, test the Solent Marks Calculator:

```bash
cd /home/shaun/projects/solent-marks-calculator
./docker-quick-start.sh
```

## Troubleshooting

### "Cannot connect to Docker daemon"
```bash
# Start the Docker service
sudo service docker start

# Check status
sudo service docker status
```

### Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker
```

### WSL2 Specific Issues
- Ensure WSL2 is updated: `wsl --update`
- Restart WSL2: `wsl --shutdown` (in PowerShell), then reopen
- Check Docker Desktop integration settings

## Which Option Should I Choose?

- **Docker Desktop**: Easiest, better integration with Windows, GUI management
- **Docker Engine in WSL2**: More control, lighter weight, command-line only

For most users, **Docker Desktop is recommended**.

