.PHONY: help start stop restart logs clean rebuild shell-backend shell-db

help:
	@echo "🐳 Task Manager - Docker Application"
	@echo ""
	@echo "Commands:"
	@echo "  make start          - Start all containers"
	@echo "  make stop           - Stop all containers"
	@echo "  make restart        - Restart all containers"
	@echo "  make logs           - View all logs"
	@echo "  make ps             - Show container status"
	@echo "  make clean          - Remove containers and volumes"
	@echo "  make rebuild        - Rebuild images"
	@echo "  make shell-backend  - Access backend shell"
	@echo "  make shell-db       - Access database"

start:
	docker-compose up -d
	@echo "✅ Started! Available at http://localhost:8080"

stop:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

ps:
	docker-compose ps

clean:
	docker-compose down -v
	@echo "✅ Cleaned"

rebuild:
	docker-compose build --no-cache
	docker-compose up -d
	@echo "✅ Rebuilt"

shell-backend:
	docker exec -it app-backend sh

shell-db:
	docker exec -it app-db psql -U appuser -d appdb

health:
	@curl -s http://localhost:8080/health && echo "✅ Healthy" || echo "⚠️ Unhealthy"
