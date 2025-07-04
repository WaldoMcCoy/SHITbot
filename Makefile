# File location: /Makefile
# S.H.I.T. Bot Management Commands

.PHONY: help build up down restart logs clean backup restore test lint format

# Default target
help:
	@echo "S.H.I.T. Bot Management Commands"
	@echo "================================"
	@echo "make build      - Build Docker containers"
	@echo "make up         - Start all services"
	@echo "make down       - Stop all services"
	@echo "make restart    - Restart bot container"
	@echo "make logs       - View bot logs"
	@echo "make clean      - Clean up temporary files"
	@echo "make backup     - Backup data and config"
	@echo "make restore    - Restore from backup"
	@echo "make test       - Run tests"
	@echo "make lint       - Run code linting"
	@echo "make format     - Format code with black"
	@echo "make shell      - Enter bot container shell"
	@echo "make db-shell   - Enter database shell"
	@echo "make update     - Update and restart bot"

# Build containers
build:
	docker-compose build --no-cache

# Start services
up:
	docker-compose up -d
	@echo "Bot started! Check logs with 'make logs'"

# Stop services
down:
	docker-compose down

# Restart bot
restart:
	docker-compose restart shit-bot
	@echo "Bot restarted!"

# View logs
logs:
	docker-compose logs -f shit-bot

# Clean temporary files
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf exports/*.xlsx exports/*.csv exports/*.txt
	@echo "Cleaned temporary files"

# Backup data
backup:
	@mkdir -p backups
	@BACKUP_NAME="backup_$$(date +%Y%m%d_%H%M%S).tar.gz"
	@tar -czf backups/$$BACKUP_NAME data/ .env
	@echo "Backup created: backups/$$BACKUP_NAME"

# Restore from backup
restore:
	@if [ -z "$(BACKUP)" ]; then \
		echo "Usage: make restore BACKUP=backup_name.tar.gz"; \
		exit 1; \
	fi
	@if [ -f "backups/$(BACKUP)" ]; then \
		tar -xzf backups/$(BACKUP); \
		echo "Restored from backups/$(BACKUP)"; \
	else \
		echo "Backup file not found: backups/$(BACKUP)"; \
		exit 1; \
	fi

# Run tests
test:
	docker-compose exec shit-bot python -m pytest tests/ -v

# Run linting
lint:
	docker-compose exec shit-bot flake8 apps/ bot/ main.py
	docker-compose exec shit-bot mypy apps/ bot/ main.py

# Format code
format:
	docker-compose exec shit-bot black apps/ bot/ main.py

# Enter bot shell
shell:
	docker-compose exec shit-bot /bin/bash

# Enter database shell
db-shell:
	docker-compose exec bot-db psql -U shitbot

# Update bot (pull, rebuild, restart)
update:
	git pull origin main
	$(MAKE) build
	$(MAKE) down
	$(MAKE) up
	@echo "Bot updated successfully!"

# Development mode
dev:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production mode with monitoring
prod:
	docker-compose --profile production up -d

# Check bot status
status:
	@docker-compose ps
	@echo ""
	@echo "Health check:"
	@curl -s http://localhost:8000/health | python -m json.tool || echo "Health check failed"

# View configuration
config:
	@docker-compose exec shit-bot cat data/game_config.json | python -m json.tool

# Database migrations
migrate:
	docker-compose exec shit-bot python manage.py migrate

# Create admin user
admin:
	@read -p "Enter Telegram User ID for admin: " user_id; \
	echo "ADMIN_USERS=$$user_id" >> .env
	@echo "Admin user added. Restart bot with 'make restart'"

# Show recent game scores
scores:
	docker-compose exec bot-db psql -U shitbot -c "SELECT username, score, timestamp FROM leaderboard ORDER BY score DESC LIMIT 10;"

# Show active games
games:
	docker-compose exec bot-db psql -U shitbot -c "SELECT user_id, username, day, cash, debt FROM game_states WHERE is_active = true;"

# Emergency reset (careful!)
reset:
	@read -p "Are you sure you want to reset all data? (yes/no): " confirm; \
	if [ "$confirm" = "yes" ]; then \
		docker-compose down -v; \
		rm -rf data/db/*; \
		echo "All data reset!"; \
	else \
		echo "Reset cancelled"; \
	fi

# ====================
# DEVELOPMENT HELPERS
# ====================

# Install development dependencies
dev-install:
	pip install -r requirements.txt
	pip install pytest pytest-asyncio pytest-cov black flake8 mypy

# Run unit tests locally
test-local:
	python -m pytest tests/ -v --cov=apps --cov=bot

# Generate test coverage report
coverage:
	python -m pytest tests/ --cov=apps --cov=bot --cov-report=html
	@echo "Coverage report generated in htmlcov/index.html"

# Watch logs with filtering
watch-logs:
	docker-compose logs -f shit-bot | grep -v "DEBUG"

# Watch errors only
watch-errors:
	docker-compose logs -f shit-bot | grep -E "ERROR|CRITICAL|Exception"

# ====================
# DATABASE MANAGEMENT
# ====================

# Backup database to file
db-backup:
	@BACKUP_FILE="backups/db_backup_$(date +%Y%m%d_%H%M%S).sql"
	@mkdir -p backups
	@docker-compose exec bot-db pg_dump -U shitbot shitbot > $BACKUP_FILE
	@echo "Database backed up to $BACKUP_FILE"

# Restore database from file
db-restore:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make db-restore FILE=backups/db_backup_YYYYMMDD_HHMMSS.sql"; \
		exit 1; \
	fi
	@docker-compose exec -T bot-db psql -U shitbot -c "DROP DATABASE IF EXISTS shitbot;"
	@docker-compose exec -T bot-db psql -U shitbot -c "CREATE DATABASE shitbot;"
	@docker-compose exec -T bot-db psql -U shitbot shitbot < $(FILE)
	@echo "Database restored from $(FILE)"

# Show database size
db-size:
	docker-compose exec bot-db psql -U shitbot -c "SELECT pg_database_size('shitbot')/1024/1024 as size_mb;"

# Vacuum database (optimize)
db-vacuum:
	docker-compose exec bot-db psql -U shitbot -c "VACUUM ANALYZE;"
	@echo "Database optimized"

# ====================
# BOT MANAGEMENT
# ====================

# Show bot information
info:
	@echo "S.H.I.T. Bot Information"
	@echo "======================="
	@docker-compose exec shit-bot python -c "import json; c=json.load(open('data/game_config.json', 'r')); print(f'Game Version: {c.get(\"version\", \"1.0\")}')" 2>/dev/null || echo "Game Version: 1.0"
	@echo "Bot Token: $(grep BOT_TOKEN .env | cut -d'=' -f2 | sed 's/\(.\{10\}\).*/\1.../')"
	@echo "Admin Users: $(grep ADMIN_USERS .env | cut -d'=' -f2)"
	@echo ""
	@$(MAKE) status

# Update game configuration
game-config:
	@docker-compose exec shit-bot cat data/game_config.json | python -m json.tool

# Edit game configuration
game-config-edit:
	@docker-compose exec shit-bot vi data/game_config.json

# Export game configuration
game-config-export:
	@docker-compose exec shit-bot cat data/game_config.json > game_config_backup.json
	@echo "Game configuration exported to game_config_backup.json"

# Import game configuration
game-config-import:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make game-config-import FILE=game_config.json"; \
		exit 1; \
	fi
	@docker cp $(FILE) shit-telegram-bot:/app/data/game_config.json
	@echo "Game configuration imported from $(FILE)"

# ====================
# MONITORING & STATS
# ====================

# Show user statistics
user-stats:
	@docker-compose exec bot-db psql -U shitbot -c "SELECT COUNT(*) as total_users, COUNT(CASE WHEN last_seen > NOW() - INTERVAL '1 day' THEN 1 END) as active_today, COUNT(CASE WHEN last_seen > NOW() - INTERVAL '7 days' THEN 1 END) as active_week FROM users;"

# Show game statistics
game-stats:
	@docker-compose exec bot-db psql -U shitbot -c "SELECT COUNT(DISTINCT user_id) as players, COUNT(*) as total_games, AVG(score) as avg_score, MAX(score) as high_score FROM leaderboard;"

# Show AI usage statistics
ai-stats:
	@docker-compose exec bot-db psql -U shitbot -c "SELECT model, COUNT(*) as messages, SUM(tokens_used) as total_tokens FROM chat_history GROUP BY model ORDER BY messages DESC;"

# Show recent errors
errors:
	@docker-compose exec bot-db psql -U shitbot -c "SELECT error_type, COUNT(*) as count, MAX(timestamp) as last_seen FROM error_logs WHERE timestamp > NOW() - INTERVAL '24 hours' GROUP BY error_type ORDER BY count DESC LIMIT 10;"

# ====================
# MAINTENANCE
# ====================

# Clean old logs
clean-logs:
	@find logs -name "*.log" -mtime +7 -delete
	@echo "Cleaned logs older than 7 days"

# Clean old exports
clean-exports:
	@find exports -name "*" -mtime +1 -delete
	@echo "Cleaned exports older than 1 day"

# Clean all temporary files
clean-all: clean clean-logs clean-exports
	@rm -rf data/db/__pycache__
	@rm -rf data/tokens/__pycache__
	@rm -rf data/routers/__pycache__
	@echo "All temporary files cleaned"

# Optimize images
optimize:
	docker image prune -f
	docker volume prune -f
	@echo "Docker resources optimized"

# ====================
# QUICK COMMANDS
# ====================

# Quick restart
restart-quick:
	docker-compose restart shit-bot

# Quick update (no rebuild)
update-quick:
	git pull origin main
	$(MAKE) restart-quick

# Emergency stop
stop-now:
	docker-compose kill shit-bot

# ====================
# DEPLOYMENT
# ====================

# Deploy to production
deploy:
	@echo "Deploying to production..."
	git pull origin main
	$(MAKE) backup
	$(MAKE) build
	$(MAKE) down
	$(MAKE) prod
	@echo "Deployment complete!"

# Rollback deployment
rollback:
	@if [ -z "$(VERSION)" ]; then \
		echo "Usage: make rollback VERSION=v1.0.0"; \
		exit 1; \
	fi
	git checkout $(VERSION)
	$(MAKE) deploy

# ====================
# HELP ADDITIONS
# ====================

help-dev:
	@echo "Development Commands"
	@echo "==================="
	@echo "make dev-install    - Install dev dependencies"
	@echo "make test-local     - Run tests locally"
	@echo "make coverage       - Generate coverage report"
	@echo "make watch-logs     - Watch logs (no debug)"
	@echo "make watch-errors   - Watch errors only"

help-db:
	@echo "Database Commands"
	@echo "================"
	@echo "make db-backup      - Backup database"
	@echo "make db-restore     - Restore database"
	@echo "make db-size        - Show database size"
	@echo "make db-vacuum      - Optimize database"

help-stats:
	@echo "Statistics Commands"
	@echo "=================="
	@echo "make user-stats     - Show user statistics"
	@echo "make game-stats     - Show game statistics"
	@echo "make ai-stats       - Show AI usage stats"
	@echo "make errors         - Show recent errors"

help-all: help help-dev help-db help-stats

# Default .PHONY additions
.PHONY: dev-install test-local coverage watch-logs watch-errors \
        db-backup db-restore db-size db-vacuum \
        info game-config game-config-edit game-config-export game-config-import \
        user-stats game-stats ai-stats errors \
        clean-logs clean-exports clean-all optimize \
        restart-quick update-quick stop-now deploy rollback \
        help-dev help-db help-stats help-all