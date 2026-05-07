#!/bin/bash
set -e

echo "🐳 Task Manager Docker Setup"
echo ""
echo "Starting all services with sudo..."
echo ""

cd "$(dirname "$0")"

# Stop existing containers
echo "Stopping existing containers..."
sudo docker-compose down 2>/dev/null || true

# Build images
echo "Building images..."
sudo docker-compose build --no-cache

# Start containers
echo ""
echo "Starting containers..."
sudo docker-compose up -d

# Wait for services to be ready
echo ""
echo "Waiting for services to start..."
sleep 5

# Check status
echo ""
echo "Service status:"
sudo docker-compose ps

echo ""
echo "✅ Application started!"
echo ""
echo "🌐 Access the application:"
echo "   Frontend: http://localhost:8080"
echo "   API: http://localhost:8080/api"
echo "   Prometheus: http://localhost:9090"
echo "   Grafana: http://localhost:3001 (admin/admin)"
echo ""
echo "📊 Check logs:"
echo "   sudo docker-compose logs -f"
echo ""
