# 10 - Express App

Node.js Express server API.

## Spuštění

```bash
cd 10-express-app
docker build -t express-app .
docker run -p 3000:3000 express-app
```

## Testování

```bash
curl http://localhost:3000/
curl http://localhost:3000/api/items
```
