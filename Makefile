# ============================================
# Meeting AI Platform - Makefile
# ============================================

.PHONY: help setup start stop restart logs clean build test shell db-migrate db-rollback prod

# Default target
help:
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║          Meeting AI Platform - Docker Commands                ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Setup & Installation:"
	@echo "  make setup          - Initial setup (copy .env, build containers)"
	@echo "  make build          - Build all Docker containers"
	@echo ""
	@echo "Container Management:"
	@echo "  make start          - Start all containers"
	@echo "  make stop           - Stop all containers"
	@echo "  make restart        - Restart all containers"
	@echo "  make down           - Stop and remove all containers"
	@echo ""
	@echo "Logs & Monitoring:"
	@echo "  make logs           - View all container logs"
	@echo "  make logs-backend   - View backend logs"
	@echo "  make logs-frontend  - View frontend logs"
	@echo "  make logs-celery    - View Celery worker logs"
	@echo ""
	@echo "Development:"
	@echo "  make shell          - Access backend container shell"
	@echo "  make shell-db       - Access PostgreSQL shell"
	@echo "  make test           - Run tests"
	@echo "  make lint           - Run code linting"
	@echo ""
	@echo "Database:"
	@echo "  make db-migrate     - Run database migrations"
	@echo "  make db-rollback    - Rollback last migration"
	@echo "  make db-reset       - Reset database (WARNING: deletes data)"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean          - Clean up containers, volumes, and cache"
	@echo "  make clean-all      - Clean everything including images"
	@echo ""
	@echo "Production:"
	@echo "  make prod           - Start in production mode"
	@echo ""

# ============================================
# Setup & Installation
# ============================================

setup:
	@echo "🚀 Setting up Meeting AI Platform..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Created .env file from .env.example"; \
		echo "⚠️  Please edit .env file with your API keys!"; \
	else \
		echo "ℹ️  .env file already exists"; \
	fi
	@mkdir -p backend/recordings backend/transcriptions backend/logs
	@mkdir -p frontend/public frontend/src
	@echo "✅ Created necessary directories"
	@docker-compose build
	@echo "✅ Setup complete!"

build:
	@echo "🔨 Building Docker containers..."
	@docker-compose build
	@echo "✅ Build complete!"

build-no-cache:
	@echo "🔨 Building Docker containers (no cache)..."
	@docker-compose build --no-cache
	@echo "✅ Build complete!"

# ============================================
# Container Management
# ============================================

start:
	@echo "🚀 Starting all containers..."
	@docker-compose up -d
	@echo "✅ All containers started!"
	@echo ""
	@echo "📊 Services available at:"
	@echo "   Frontend:  http://localhost:3000"
	@echo "   Backend:   http://localhost:8000"
	@echo "   API Docs:  http://localhost:8000/docs"
	@echo "   Adminer:   http://localhost:8080"
	@echo ""

stop:
	@echo "🛑 Stopping all containers..."
	@docker-compose stop
	@echo "✅ All containers stopped!"

restart:
	@echo "🔄 Restarting all containers..."
	@docker-compose restart
	@echo "✅ All containers restarted!"

down:
	@echo "🗑️  Stopping and removing containers..."
	@docker-compose down
	@echo "✅ Containers removed!"

# ============================================
# Logs & Monitoring
# ============================================

logs:
	@docker-compose logs -f

logs-backend:
	@docker-compose logs -f backend

logs-frontend:
	@docker-compose logs -f frontend

logs-celery:
	@docker-compose logs -f celery-worker

logs-nginx:
	@docker-compose logs -f nginx

logs-db:
	@docker-compose logs -f postgres

status:
	@docker-compose ps

# ============================================
# Development
# ============================================

shell:
	@echo "🐚 Accessing backend container shell..."
	@docker-compose exec backend /bin/bash

shell-db:
	@echo "🐚 Accessing PostgreSQL shell..."
	@docker-compose exec postgres psql -U meeting_user -d meeting_db

shell-redis:
	@echo "🐚 Accessing Redis CLI..."
	@docker-compose exec redis redis-cli

test:
	@echo "🧪 Running tests..."
	@docker-compose exec backend pytest

test-coverage:
	@echo "🧪 Running tests with coverage..."
	@docker-compose exec backend pytest --cov=app --cov-report=html

lint:
	@echo "🔍 Running linters..."
	@docker-compose exec backend black app/
	@docker-compose exec backend flake8 app/
	@docker-compose exec backend mypy app/

format:
	@echo "✨ Formatting code..."
	@docker-compose exec backend black app/
	@docker-compose exec backend isort app/

# ============================================
# Database
# ============================================

db-migrate:
	@echo "🔄 Running database migrations..."
	@docker-compose exec backend alembic upgrade head
	@echo "✅ Migrations complete!"

db-rollback:
	@echo "⏮️  Rolling back last migration..."
	@docker-compose exec backend alembic downgrade -1
	@echo "✅ Rollback complete!"

db-reset:
	@echo "⚠️  WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		docker-compose up -d postgres; \
		sleep 5; \
		docker-compose exec backend alembic upgrade head; \
		echo "✅ Database reset complete!"; \
	fi

db-backup:
	@echo "💾 Creating database backup..."
	@mkdir -p backups
	@docker-compose exec postgres pg_dump -U meeting_user meeting_db > backups/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup created in backups/ directory"

# ============================================
# Cleanup
# ============================================

clean:
	@echo "🧹 Cleaning up..."
	@docker-compose down -v
	@docker system prune -f
	@echo "✅ Cleanup complete!"

clean-all:
	@echo "🧹 Deep cleaning (removes images too)..."
	@docker-compose down -v --rmi all
	@docker system prune -a -f
	@echo "✅ Deep cleanup complete!"

clean-logs:
	@echo "🧹 Cleaning log files..."
	@find backend/logs -type f -name "*.log" -delete
	@echo "✅ Logs cleaned!"

# ============================================
# Production
# ============================================

prod:
	@echo "🚀 Starting in PRODUCTION mode..."
	@docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
	@echo "✅ Production containers started!"

prod-logs:
	@docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f

prod-down:
	@docker-compose -f docker-compose.yml -f docker-compose.prod.yml down

# ============================================
# Monitoring
# ============================================

stats:
	@docker stats

health:
	@echo "🏥 Checking service health..."
	@curl -s http://localhost/health || echo "❌ Nginx not responding"
	@curl -s http://localhost:8000/health || echo "❌ Backend not responding"

# ============================================
# Utils
# ============================================

seed-data:
	@echo "🌱 Seeding database with sample data..."
	@docker-compose exec backend python -m app.scripts.seed_data
	@echo "✅ Database seeded!"

create-admin:
	@echo "👤 Creating admin user..."
	@docker-compose exec backend python -m app.scripts.create_admin
	@echo "✅ Admin user created!"
