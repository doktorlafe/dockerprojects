# 21 - Full Stack App

Kompletní full-stack aplikace: PostgreSQL, Flask API, React frontend, Nginx proxy.

## Spuštění

```bash
cd 21-full-stack-app
docker compose up -d
```

- Frontend: http://localhost:8081 (přes Nginx)
- API: http://localhost:8081/api/
- Frontend ani API nejsou publikované přímo na vlastní host porty, používají se přes Nginx reverse proxy na `http://localhost:8081`.
