# 26 - Private Registry

Privátní Docker registry pro vlastní images.

## Spuštění

```bash
cd 26-private-registry
docker-compose up
```

Registry běží na localhost:5000

## Push image

```bash
docker tag myapp:latest localhost:5000/myapp:latest
docker push localhost:5000/myapp:latest
```
