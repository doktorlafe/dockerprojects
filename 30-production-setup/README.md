# 30 - Production Setup

Kompletní produkční setup: PostgreSQL, Python app, Nginx, Prometheus monitoring.

## Spuštění

```bash
cd 30-production-setup
docker-compose up
```

## Přístup

- Aplikace: http://localhost
- Health check: http://localhost/health
- Prometheus: http://localhost:9090

## Vlastnosti

- Health checks pro všechny služby
- Automatic restart
- Monitoring s Prometheus
- Nginx reverse proxy
- Produktivní WSGI server (Gunicorn)
