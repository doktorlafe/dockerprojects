# 🐳 30 Docker Projektů - Praktické Příklady

Kompletní sbírka 30 Docker projektů seřazených podle obtížnosti. Každý projekt je v samostatné složce a je připraven k spuštění.

---

## 📊 Organizace Projektů

### **TIER 1 - Základy (Příklady 1-10)**
Jednoduchý úvod do Dockeru - základní kontejnery, image, databáze

| # | Projekt | Popis |
|---|---------|-------|
| 1 | `01-hello-world` | Nejjednoduší Docker projekt - Alpine Linux |
| 2 | `02-python-app` | Python aplikace v kontejneru |
| 3 | `03-nodejs-server` | Node.js HTTP server |
| 4 | `04-nginx-webserver` | Nginx webový server s HTML |
| 5 | `05-mysql-database` | MySQL databáze s inicializací |
| 6 | `06-postgres-database` | PostgreSQL s Docker Compose |
| 7 | `07-redis-cache` | Redis in-memory cache |
| 8 | `08-mongodb-database` | MongoDB NoSQL databáze |
| 9 | `09-flask-api` | Flask REST API server |
| 10 | `10-express-app` | Node.js Express server |

### **TIER 2 - Intermediate (Příklady 11-20)**
Multi-kontejnerové aplikace, orchestrace, registry

| # | Projekt | Popis |
|---|---------|-------|
| 11 | `11-python-flask-postgres` | Flask + PostgreSQL s Docker Compose |
| 12 | `12-nodejs-mysql` | Node.js + MySQL aplikace |
| 13 | `13-django-postgres` | Django framework + PostgreSQL |
| 14 | `14-react-nodejs-api` | React frontend + Node.js API |
| 15 | `15-wordpress-mysql` | Kompletní WordPress instalace |
| 16 | `16-elasticsearch-kibana` | ELK stack pro logování |
| 17 | `17-rabbitmq` | RabbitMQ message broker |
| 18 | `18-jenkins-ci` | Jenkins CI/CD server |
| 19 | `19-grafana-prometheus` | Monitoring a metriky |
| 20 | `20-nextjs-app` | Next.js React framework |

### **TIER 3 - Advanced (Příklady 21-30)**
Production-ready, orchestrace, security, monitoring

| # | Projekt | Popis |
|---|---------|-------|
| 21 | `21-full-stack-app` | Full-stack app: PostgreSQL + Flask + React + Nginx |
| 22 | `22-microservices` | Architektura mikroslužeb s API Gateway |
| 23 | `23-kubernetes-setup` | Kubernetes manifesty a deployment |
| 24 | `24-docker-swarm` | Docker Swarm orchestrace |
| 25 | `25-traefik-reverse-proxy` | Traefik reverse proxy s routingem |
| 26 | `26-private-registry` | Privátní Docker registry |
| 27 | `27-ssl-certificate-setup` | HTTPS s SSL certifikáty |
| 28 | `28-ci-cd-pipeline` | GitLab + Jenkins CI/CD pipeline |
| 29 | `29-logging-elk-stack` | ELK stack pro production logging |
| 30 | `30-production-setup` | Kompletní production setup s monitoring |

---

## 🚀 Rychlý Start

Každý projekt má vlastní složku s README.md.

### Příklad Tier 1 - Hello World:
```bash
cd 01-hello-world
docker build -t hello-world .
docker run hello-world
```

### Příklad Tier 2 - Flask + PostgreSQL:
```bash
cd 11-python-flask-postgres
docker-compose up
# Přístup: http://localhost:5000
```

### Příklad Tier 3 - Production Setup:
```bash
cd 30-production-setup
docker-compose up
# Přístup: http://localhost
# Prometheus monitoring: http://localhost:9090
```

---

## 📚 Co se v jednotlivých projektech naučíš

### Tier 1 - Základní Dovednosti
- ✅ Základní Docker příkazy
- ✅ Dockerfile psaní
- ✅ Docker images a kontejnery
- ✅ Port mapping
- ✅ Spuštění veřejných image (MySQL, PostgreSQL, Redis, MongoDB)
- ✅ Kopírování souborů do kontejneru

### Tier 2 - Intermediate Dovednosti
- ✅ Docker Compose pro multi-kontejnerové aplikace
- ✅ Environment proměnné
- ✅ Networking mezi kontejnery
- ✅ Volumes a data persistence
- ✅ Build custom Dockerfiles
- ✅ Health checks
- ✅ Depends_on a startup order

### Tier 3 - Advanced Dovednosti
- ✅ Full-stack aplikace
- ✅ Microservices architektura
- ✅ API Gateway pattern
- ✅ Kubernetes manifesty
- ✅ Docker Swarm
- ✅ Reverse proxy (Traefik, Nginx)
- ✅ Private Docker registry
- ✅ SSL/TLS certifikáty
- ✅ CI/CD pipelines
- ✅ ELK stack logging
- ✅ Production monitoring
- ✅ Health checks a restarts
- ✅ Security best practices

---

## 🛠️ Užitečné Příkazy

### Listování a Inspekce
```bash
docker images                          # Vypíše všechny images
docker ps                             # Spuštěné kontejnery
docker ps -a                          # Všechny kontejnery
docker logs <container_id>            # Logy kontejneru
docker inspect <container_id>         # Detailní info
```

### Build a Run
```bash
docker build -t myapp:1.0 .          # Build image
docker run -d -p 8080:80 myapp:1.0   # Spustit kontejner
docker exec -it <id> /bin/bash       # Vstup do kontejneru
```

### Čištění
```bash
docker stop <container_id>            # Zastavit kontejner
docker rm <container_id>              # Smazat kontejner
docker system prune -a                # Smazat všechno nepoužívané
```

### Docker Compose
```bash
docker-compose up                     # Spustit
docker-compose down                   # Zastavit a smazat
docker-compose logs -f                # Live logy
docker-compose ps                     # Status služeb
```

---

## 📖 Struktura Projektu

Každý projekt obsahuje:

```
XX-project-name/
├── README.md                  # Instrukce pro daný projekt
├── Dockerfile                # Pro Tier 1 projekty
├── docker-compose.yml        # Pro Tier 2+ projekty
├── app.py / server.js        # Aplikační kód
├── requirements.txt          # Python dependencies
├── package.json              # Node.js dependencies
└── config/                   # Konfigurační soubory
```

---

## 🎯 Jak Používat Tuto Sbírku

### Pro Začátečníky:
1. Začni s **Tier 1** (01-10)
2. Projdi projekty sekvenciálně
3. Zkoušej modifikovat Dockerfiles
4. Experimentuj s porty, proměnnými

### Pro Intermediate:
1. Přejdi na **Tier 2** (11-20)
2. Nauč se Docker Compose
3. Kombinuj více služeb
4. Pouštěj přes proxy servery

### Pro Advanced:
1. Pracuj s **Tier 3** (21-30)
2. Testuj Kubernetes a Swarm
3. Nastavuj production monitoring
4. Pracuj se security features

---

## ⚠️ Požadavky

- **Docker** (https://docker.com)
- **Docker Compose** (obvykle součástí Docker Desktop)
- 2+ GB volné místa na disku

### Instalace na Linuxu:
```bash
sudo apt-get install docker.io docker-compose
sudo usermod -aG docker $USER
```

---

## 🔗 Užitečné Zdroje

- [Docker Official Docs](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Docker Hub](https://hub.docker.com/)

---

## 💡 Tipy

1. **Začni s Tier 1**: Ne všechny projekty hned budou dávat smysl, pokud je začneš spouštět bez fundamentů.
2. **Experimentuj**: Měň porty, proměnné, názvy - to je nejlepší cesta k učení.
3. **Čti logy**: Když něco nefunguje, první místo je `docker logs`.
4. **Nech běžet**: Ponech si kontejnery spuštěné a zkoušej se připojit, měnit konfiguraci.
5. **Kombinuj projekty**: Čím víc experimentů, tím víc se naučíš.

---

## 📝 Poznámky

- Projekty jsou zjednodušené pro učební účely
- V produkci bys měl použít secrets management namísto plain-text hesel
- Každý projekt má v README konkrétní pokyny k spuštění
- Některé projekty vyžadují Linux (Swarm, Kubernetes)

---

**Happy Docker-ing! 🚀**
