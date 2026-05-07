#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Task Manager - Docker Application${NC}\n"

case "$1" in
  start)
    echo -e "${YELLOW}Starting containers...${NC}"
    docker-compose up -d
    sleep 3
    echo -e "${GREEN}✅ Application started!${NC}"
    echo -e "\n${BLUE}Available at:${NC}"
    echo "  • Frontend: http://localhost:8080"
    echo "  • API: http://localhost:8080/api"
    echo "  • Prometheus: http://localhost:9090"
    echo "  • Grafana: http://localhost:3001 (admin/admin)"
    ;;
  
  stop)
    echo -e "${YELLOW}Stopping containers...${NC}"
    docker-compose down
    echo -e "${GREEN}✅ Stopped${NC}"
    ;;
  
  restart)
    echo -e "${YELLOW}Restarting containers...${NC}"
    docker-compose restart
    echo -e "${GREEN}✅ Restarted${NC}"
    ;;
  
  logs)
    docker-compose logs -f
    ;;
  
  logs-backend)
    docker-compose logs -f backend
    ;;
  
  logs-frontend)
    docker-compose logs -f frontend
    ;;
  
  ps)
    docker-compose ps
    ;;
  
  clean)
    echo -e "${YELLOW}Removing containers and volumes...${NC}"
    docker-compose down -v
    echo -e "${GREEN}✅ Cleaned${NC}"
    ;;
  
  rebuild)
    echo -e "${YELLOW}Rebuilding images...${NC}"
    docker-compose build --no-cache
    docker-compose up -d
    echo -e "${GREEN}✅ Rebuilt${NC}"
    ;;
  
  shell-backend)
    docker exec -it app-backend sh
    ;;
  
  shell-db)
    docker exec -it app-db psql -U appuser -d appdb
    ;;
  
  health)
    echo -e "${BLUE}Checking service health...${NC}"
    curl -s http://localhost:8080/health && echo -e "\n${GREEN}✅ Healthy${NC}" || echo -e "\n${YELLOW}⚠️  Unhealthy${NC}"
    ;;
  
  *)
    echo "Usage: $0 {start|stop|restart|logs|logs-backend|logs-frontend|ps|clean|rebuild|shell-backend|shell-db|health}"
    echo ""
    echo "Commands:"
    echo "  start           - Start all containers"
    echo "  stop            - Stop all containers"
    echo "  restart         - Restart all containers"
    echo "  logs            - View all logs (follow mode)"
    echo "  logs-backend    - View backend logs"
    echo "  logs-frontend   - View frontend logs"
    echo "  ps              - Show container status"
    echo "  clean           - Remove containers and volumes"
    echo "  rebuild         - Rebuild images"
    echo "  shell-backend   - Access backend shell"
    echo "  shell-db        - Access database shell"
    echo "  health          - Check service health"
    ;;
esac
