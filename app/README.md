# 🐳 Complete Docker Application - Task Manager

Kompletní full-stack Docker aplikace s best practices.

## 🏗️ Architektura

```
┌─────────────┐
│   Browser   │ http://localhost:8080
└──────┬──────┘
       │
┌──────▼──────────────────────────────────────┐
│         Nginx (Reverse Proxy)                │ Port 8080
├──────────────────────────────────────────────┤
│  ┌──────────────┐        ┌──────────────┐   │
│  │   Frontend   │        │   Backend    │   │
│  │   (React)    │        │  (Node.js)   │   │
│  │  Port 3000   │        │  Port 5000   │   │
│  └──────────────┘        └──────┬───────┘   │
└─────────────────────────────────┼───────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
              ┌─────▼────────┐         ┌────────▼─────┐
              │  PostgreSQL  │         │    Redis     │
              │  Database    │         │    Cache     │
              │  Port 5432   │         │  Port 6379   │
              └──────────────┘         └──────────────┘

Monitoring:
  - Prometheus: http://localhost:9090
  - Grafana: http://localhost:3001
```

## 🚀 Spuštění

### Předpoklady
- Docker (verze 20.10+)
- Docker Compose (verze 1.29+)

### Start
```bash
cd /home/patri/docker/app
docker-compose up -d
```

### Zastavení
```bash
docker-compose down
```

## 📱 Přístup k aplikaci

- **Frontend**: http://localhost:8080
- **API**: http://localhost:8080/api
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3001 (admin/admin)

## 🛠️ Dostupné služby

### 1. **PostgreSQL** (Database)
- Host: `db`
- Port: `5432`
- User: `appuser`
- Password: `apppass123`
- Database: `appdb`

### 2. **Redis** (Cache)
- Host: `redis`
- Port: `6379`
- Používá se pro caching tasks

### 3. **Backend API** (Node.js + Express)
- Port: `5000` (interně), `8080/api` (externě)
- Endpoints:
  - `GET /api/health` - Health check
  - `GET /api/tasks` - Všechny úkoly
  - `POST /api/tasks` - Nový úkol
  - `PUT /api/tasks/:id` - Aktualizace úkolu
  - `DELETE /api/tasks/:id` - Smazání úkolu
  - `GET /api/stats` - Statistiky

### 4. **Frontend** (React + Vite)
- Port: `3000` (interně), `8080/` (externě)
- Komunikuje s API přes reverse proxy

### 5. **Nginx** (Reverse Proxy)
- Port: `8080`
- Routuje requesty na Frontend a Backend

### 6. **Prometheus** (Monitoring)
- Port: `9090`
- Sbírá metriky ze všech služeb

### 7. **Grafana** (Visualization)
- Port: `3001`
- Vizualizuje metriky z Prometheus

## 📊 Užitečné příkazy

```bash
# Zobrazit logy
docker-compose logs -f                    # Všechny logy
docker-compose logs -f backend            # Jen backend logy
docker-compose logs -f frontend           # Jen frontend logy

# Přístup do kontejneru
docker exec -it app-backend sh            # Backend shell
docker exec -it app-db psql -U appuser -d appdb  # Database

# Resetovat data
docker-compose down -v                    # Smazat volumes (data)
docker-compose up -d                      # Spustit znovu

# Rebuild images
docker-compose build --no-cache
docker-compose up -d

# Status služeb
docker-compose ps

# Metriky a monitoring
docker stats                               # CPU/Memory usage

# Čistění
docker-compose down                        # Stop a remove containers
docker image prune -a                      # Smazat nepoužívané images
docker volume prune                        # Smazat nepoužívané volumes
```

## 🔍 Monitorování a Debugging

### Prometheus
- http://localhost:9090
- Ukazuje metriky v reálném čase
- Query jazyk: PromQL

### Grafana
- http://localhost:3001
- Default login: admin/admin
- Vytváří dashboards z Prometheus dat

### Logy
```bash
# Real-time logy
docker-compose logs -f

# Logy specifické služby
docker compose logs -f backend
docker compose logs -f frontend

# Poslední 100 řádků
docker-compose logs --tail=100
```

## 🗄️ Databáze - SQL Queries

```bash
# Přístup do databáze
docker exec -it app-db psql -U appuser -d appdb

# Základní queries
SELECT * FROM tasks;
SELECT COUNT(*) FROM tasks WHERE completed = true;
SELECT * FROM tasks ORDER BY created_at DESC;
```

## 🔐 Security Best Practices

### Implementováno:
- ✅ Health checks na všech službách
- ✅ Automatic restart na failure
- ✅ Resource limits (CPU, Memory)
- ✅ Network isolation (custom bridge network)
- ✅ Docker secrets pro hesla (v produkci)

### Nedoporučuje se v produkci:
- ❌ Plaintext hesla v docker-compose.yml
- ❌ Přístup na porty bez autentizace
- ❌ Volumes bez backupu
- ❌ Spouštění bez monitoring

## 📝 Struktura projektu

```
app/
├── docker-compose.yml          # Orchestrace všech služeb
├── backend/                    # Node.js API
│   ├── Dockerfile
│   ├── app.js
│   └── package.json
├── frontend/                   # React UI
│   ├── Dockerfile
│   ├── package.json
│   ├── vite.config.js
│   ├── App.jsx
│   └── main.jsx
├── nginx/                      # Reverse Proxy
│   ├── Dockerfile
│   └── nginx.conf
├── db/                         # Database
│   └── init.sql
├── prometheus/                 # Monitoring
│   └── prometheus.yml
├── grafana/                    # Dashboards
│   └── provisioning/datasources.yml
└── README.md
```

## 🎯 Příklady použití

### Vytvoření nového úkolu
```bash
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"My Task","description":"Task description"}'
```

### Získání všech úkolů
```bash
curl http://localhost:8080/api/tasks
```

### Aktualizace úkolu
```bash
curl -X PUT http://localhost:8080/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Task","completed":true}'
```

### Smazání úkolu
```bash
curl -X DELETE http://localhost:8080/api/tasks/1
```

## 🐛 Troubleshooting

### "Cannot connect to the Docker daemon"
```bash
sudo systemctl start docker
```

### "Port already in use"
```bash
# Změní port v docker-compose.yml
# Nebo zastaví ostatní služby
lsof -i :8080
kill -9 <PID>
```

### Database connection failed
```bash
# Zkontroluj, že db service je healthy
docker-compose logs db

# Resetuj databázi
docker-compose down -v
docker-compose up -d
```

### Frontend není dostupný
```bash
# Zkontroluj nginx logy
docker-compose logs nginx

# Resetuj frontend
docker-compose down
docker-compose build --no-cache frontend
docker-compose up -d
```

## 📚 Naučíš se:

- ✅ Docker containers a images
- ✅ Docker Compose pro orchestraci
- ✅ Multi-kontejnerové aplikace
- ✅ Networking a port mapping
- ✅ Volumes a data persistence
- ✅ Health checks
- ✅ Reverse proxy (Nginx)
- ✅ Database (PostgreSQL)
- ✅ Caching (Redis)
- ✅ Monitoring (Prometheus, Grafana)
- ✅ Production best practices

## 🚀 Rozšíření

Podle potřeby můžeš přidat:
- Authentication/Authorization
- API Documentation (Swagger)
- Unit/Integration testing
- CI/CD Pipeline (GitHub Actions)
- Kubernetes deployment
- SSL/TLS certificates
- Logging stack (ELK)
- Load balancing

---

**Happy Dockering! 🐳**
