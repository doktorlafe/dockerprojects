# 04 - Nginx Webserver

Nginx webový server v Dockeru se starou dobrou HTML stránkou.

## Spuštění

```bash
cd 04-nginx-webserver
docker build -t nginx-server .
docker run -p 8080:80 nginx-server
```

## Přístup

Otevři v prohlížeči: http://localhost:8080
