# 08 - MongoDB Database

MongoDB NoSQL databáze v Dockeru.

## Spuštění

```bash
cd 08-mongodb-database
docker-compose up -d
```

## Připojení

```bash
mongosh -u admin -p password --authenticationDatabase admin localhost:27017/myapp
> db.users.find()
```

## Zastavení

```bash
docker-compose down
```
