# Agent Context & Preferences

This file contains project-specific context and user preferences for AI agents working on this codebase.

## User Preferences

### Installation Methods
- **Always use official package managers where possible** (apt, pip, npm, etc.)
- Prefer official repositories over curl-to-bash scripts
- For Ubuntu/Debian: Use apt packages when available
- Avoid manual downloads unless no package manager option exists

### Communication Style
- User is familiar with Linux and command-line operations
- Don't need verbose documentation for every command
- When sudo is needed, just say "please run this as sudo"
- Be concise, avoid over-explaining basic concepts

### Development Workflow
- Follows red/green/demo/commit workflow
- Test-driven development with pytest
- Always run tests after edits
- Fix warnings at root cause, don't silence them
- Include linting in standard test runs
- Make tests pass or adjust/remove if no longer needed

### Testing Preferences
- Unit test Python functions directly with pytest (not Flask endpoints)
- Follow red/green/refactor loops
- Write tests first when possible

## Project-Specific Notes

### Security
- Run security scans on Docker images before production
- Use official security scanning tools (Trivy, Hadolint, etc.)
- Install security tools via package managers

### Docker
- Multi-environment setup (dev/test/prod)
- Different SSL certificates per environment
- Use Docker Compose overrides for environment-specific configs

### Technology Stack
- Flask 3.0.0
- Python 3.12
- Gunicorn for WSGI
- Docker for containerization
- Nginx for reverse proxy
- GPX data files for racing marks

## Installation Commands

### Trivy (Security Scanner)
```bash
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y
```

## Notes for Future Sessions
- User prefers concise, actionable responses
- Focus on best practices and official methods
- Security is important - scan before production deployment


