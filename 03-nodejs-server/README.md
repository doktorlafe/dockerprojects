# 03 - Node.js Server

Jednoduchý Node.js HTTP server v Dockeru.

## Spuštění

```bash
cd 03-nodejs-server
docker build -t nodejs-server .
docker run -p 3000:3000 nodejs-server
```

## Testování

```bash
curl http://localhost:3000
```

Server běží na portu 3000.
