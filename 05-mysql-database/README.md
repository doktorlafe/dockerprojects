# 05 - MySQL Database

MySQL databáze v Dockeru s automatickou inicializací.

## Spuštění

```bash
cd 05-mysql-database
docker build -t mysql-app .
docker run -d --name mysql-container -p 3306:3306 mysql-app
```

## Připojení

```bash
mysql -h localhost -u root -prootpass -D myapp
SELECT * FROM users;
```

## Zastavení

```bash
docker stop mysql-container
docker rm mysql-container
```
