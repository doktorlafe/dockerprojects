# 09 - Flask API

Jednoduchý Flask REST API server.

## Spuštění

```bash
cd 09-flask-api
docker build -t flask-api .
docker run -p 5000:5000 flask-api
```

## Testování

```bash
curl http://localhost:5000/
curl http://localhost:5000/api/users
```
