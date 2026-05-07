# Configuration
version: '3.8'

# Services
- name: PostgreSQL
  description: Relational database
  port: 5432
  
- name: Redis
  description: In-memory cache
  port: 6379
  
- name: Backend API
  description: Node.js Express application
  port: 5000
  endpoints:
    - /api/health
    - /api/tasks
    - /api/stats
  
- name: Frontend
  description: React web application
  port: 3000
  
- name: Nginx
  description: Reverse proxy and load balancer
  port: 8080
  routes:
    - / -> frontend:3000
    - /api -> backend:5000
  
- name: Prometheus
  description: Metrics collection
  port: 9090
  
- name: Grafana
  description: Visualization dashboards
  port: 3001
  credentials: admin/admin

# Features
- Multi-container orchestration
- Health checks on all services
- Automatic restart policies
- Custom bridge network
- Data persistence with volumes
- Resource monitoring
- Reverse proxy with routing
- Database initialization scripts
- Development and production ready
