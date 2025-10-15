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
- **Inspired by XP (Extreme Programming)** - Kent Beck-style programming practices
- Follows **red/green/demo/commit** workflow
- **Test-Driven Development (TDD)** and **Behavior-Driven Development (BDD)** with pytest
- **ALWAYS write tests BEFORE writing functionality code**
- All tests must ALWAYS pass - no exceptions
- Always run tests after edits
- Fix warnings at root cause, don't silence them
- Include linting in standard test runs
- Make tests pass or adjust/remove if no longer needed

### Testing Preferences
- **Red-Green-Refactor Loop (XP-style):**
  1. **RED**: Write a failing test first
  2. **GREEN**: Write minimal code to make the test pass
  3. **REFACTOR**: Improve code quality while keeping tests green
  4. Commit after green, commit again after refactor
- Unit test Python functions directly with pytest (not Flask endpoints)
- Write tests FIRST, then implement functionality
- Manual acceptance testing in browser after automated tests pass
- Eventually automate acceptance tests

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
- pytest for testing

### Development Environment
- **Always use Docker for development and testing**
- Run tests in Docker container: `make test`
- No local virtual environment needed - dependencies encapsulated in Docker
- Consistent environment across dev/test/prod
- Test image built from Dockerfile using multi-stage build

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


