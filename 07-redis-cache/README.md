# 07 - Redis Cache

Redis cache server v Dockeru.

## Spuštění

```bash
cd 07-redis-cache
docker-compose up -d
```

## Testování

```bash
redis-cli
> SET mykey "Hello"
> GET mykey
> FLUSHALL
```

## Zastavení

```bash
docker-compose down
```
