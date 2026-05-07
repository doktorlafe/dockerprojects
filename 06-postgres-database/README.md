# 06 - PostgreSQL Database

PostgreSQL databáze spuštěná přes Docker Compose.

## Spuštění

```bash
cd 06-postgres-database
docker-compose up -d
```

## Připojení

```bash
psql -h localhost -U admin -d myapp
SELECT * FROM products;
```

## Zastavení

```bash
docker-compose down
```
