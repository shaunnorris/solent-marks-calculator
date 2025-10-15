.PHONY: help build up down restart logs test clean prune shell health

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build Docker images
	sg docker -c "docker compose build"

up: ## Start services in detached mode
	sg docker -c "docker compose up -d"

down: ## Stop and remove containers
	sg docker -c "docker compose down"

restart: ## Restart all services
	sg docker -c "docker compose restart"

logs: ## Follow logs from all services
	sg docker -c "docker compose logs -f"

logs-web: ## Follow logs from web service only
	sg docker -c "docker compose logs -f web"

logs-nginx: ## Follow logs from nginx service only
	sg docker -c "docker compose logs -f nginx"

test: ## Run all tests in Docker container
	sg docker -c "docker build -t solent-marks-test --target builder . -q"
	sg docker -c "docker run --rm -v $(PWD)/dev:/app/dev -e PYTHONPATH=/app solent-marks-test /root/.local/bin/pytest dev/tests/ -v"

test-local: ## Run tests locally (requires dependencies installed)
	python3 -m pytest dev/tests/test_app.py -v

shell: ## Open shell in web container
	docker-compose exec web /bin/bash

ps: ## Show container status
	docker-compose ps

health: ## Check health status of containers
	@echo "Web container health:"
	@docker inspect --format='{{json .State.Health}}' solent-marks-calculator 2>/dev/null || echo "Container not running"
	@echo "\nNginx container health:"
	@docker inspect --format='{{json .State.Health}}' solent-marks-nginx 2>/dev/null || echo "Container not running"

stats: ## Show container resource usage
	docker stats --no-stream solent-marks-calculator solent-marks-nginx

clean: ## Remove stopped containers and dangling images
	docker-compose down -v
	docker system prune -f

prune: ## Remove all unused Docker data (WARNING: removes all unused images, containers, volumes)
	docker system prune -a --volumes -f

dev: ## Run development server locally
	python3 -m flask run --host=0.0.0.0 --port=5000

prod-up: ## Build and start in production mode
	docker-compose build
	docker-compose up -d
	@echo "Waiting for services to be healthy..."
	@sleep 5
	@make health
	@echo "\nApplication should be available at http://localhost"

prod-logs: ## Show recent production logs
	docker-compose logs --tail=100

prod-restart: ## Restart production deployment
	docker-compose restart
	@sleep 3
	@make health

update: ## Pull latest code and rebuild
	git pull origin main
	docker-compose up -d --build
	@echo "Update complete. Checking health..."
	@sleep 5
	@make health

backup: ## Backup GPX data file
	@mkdir -p backup
	docker cp solent-marks-calculator:/app/2025scra.gpx ./backup/2025scra-$$(date +%Y%m%d-%H%M%S).gpx
	@echo "Backup created in backup/ directory"

lint: ## Run linting checks
	@command -v ruff >/dev/null 2>&1 || { echo "ruff not installed. Install with: pip install ruff"; exit 1; }
	ruff check app.py

format: ## Format code
	@command -v black >/dev/null 2>&1 || { echo "black not installed. Install with: pip install black"; exit 1; }
	black app.py

