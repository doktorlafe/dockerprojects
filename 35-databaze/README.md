# 35 - PostgreSQL Docker Lab

Pokrocilejsi databazovy projekt zamereny na PostgreSQL v Dockeru. Cilem neni jen "mit databazi v kontejneru", ale pochopit, jak funguje inicializace, replikace, migrace, healthchecky, zalohy a obnova dat v realnem stacku.

## Co se na projektu naucis

- rozdil mezi primary a read replica instanci
- jak se dela inicializace role, databaze a pristupu pres `docker-entrypoint-initdb.d`
- jak oddelit schema migrace a seed data do samostatnych jednorazovych sluzeb
- jak periodicky delat dump databaze do host filesystemu
- jak overovat replikaci a proc na replice nelze zapisovat
- jak v Dockeru pracovat s volumes, healthchecky a zavislostmi mezi sluzbami

## Architektura

- `postgres-primary`: hlavni zapisova PostgreSQL instance
- `postgres-replica`: read replica vytvorena pres `pg_basebackup`
- `pgadmin`: GUI pro kontrolu databaze, indexu, view a SQL dotazu
- `migrate`: jednorazova sluzba, ktera aplikuje SQL migrace
- `seed`: jednorazova sluzba, ktera vlozi ukazkova data
- `backup`: periodicky vytvari `pg_dump` do lokalni slozky `backups/`

## Struktura

- `docker-compose.yml`: cely stack
- `.env.example`: prehled nastavitelných promennych
- `postgres/primary/conf/`: konfigurace primary instance
- `postgres/primary/init/`: bootstrap role pro aplikaci a replikaci
- `migrations/`: schema a databazove objekty
- `seed/`: demo data
- `exercises/`: SQL cviceni pro samostatne zkouseni
- `scripts/restore-latest.sh`: obnova posledni zalohy

## Rychly start

```bash
cd 35-databaze
cp .env.example .env
docker compose up -d postgres-primary postgres-replica pgadmin backup
docker compose up migrate seed
```

Pokud nechces `.env`, stack se spusti i s defaultnimi hodnotami z `docker-compose.yml`.

## Pristupove udaje a porty

- primary PostgreSQL: `localhost:5435`
- replica PostgreSQL: `localhost:5436`
- pgAdmin: `http://localhost:5050`
- superuser: `admin / adminpass`
- app user: `app / apppass`
- replication user: `replicator / replicatorpass`
- database: `appdb`

## Jak projekt zkoumat

### 1. Over, ze replica opravdu bezi v recovery modu

```bash
docker compose exec postgres-replica psql -U admin -d appdb -c "SELECT pg_is_in_recovery();"
```

### 2. Podivej se na WAL replikaci z primary

```bash
docker compose exec postgres-primary psql -U admin -d appdb -c "SELECT client_addr, state, sync_state, write_lag, flush_lag, replay_lag FROM pg_stat_replication;"
```

### 3. Zkus cteni z repliky

```bash
docker compose exec postgres-replica psql -U admin -d appdb -c "SELECT order_reference, status, total_amount FROM app.orders ORDER BY id;"
```

### 4. Zkus zapis na repliku

Ten musi skoncit chybou. To je spravne.

```bash
docker compose exec postgres-replica psql -U admin -d appdb -c "INSERT INTO app.customers(email, full_name) VALUES ('replica-test@example.com', 'Replica Test');"
```

### 5. Proved zapis na primary a sleduj propagaci

```bash
docker compose exec postgres-primary psql -U admin -d appdb -c "UPDATE app.products SET price = price + 10 WHERE sku = 'SKU-DOCKER-BOOK';"
docker compose exec postgres-replica psql -U admin -d appdb -c "SELECT sku, price FROM app.products WHERE sku = 'SKU-DOCKER-BOOK';"
```

## Prace se zalohami

Backup kontejner uklada dumpy do `backups/` kazdych 5 minut. Interval lze zmenit v `.env` pres `BACKUP_INTERVAL_SECONDS`.

Rucni obnova posledni zalohy:

```bash
./scripts/restore-latest.sh
```

Obnova konkretniho dumpu:

```bash
./scripts/restore-latest.sh backups/appdb-YYYYMMDD-HHMMSS.dump
```

## pgAdmin

Prihlaseni do pgAdminu:

- email: `admin@example.com`
- heslo: `admin123`

Pridani serveru v pgAdminu:

- Name: `postgres-primary`
- Host: `postgres-primary`
- Port: `5432`
- Username: `admin`
- Password: `adminpass`

Pro repliku pouzij host `postgres-replica`.

## Doporučeny postup uceni

1. Spust stack a projdi tabulky v pgAdminu.
2. Otevri `migrations/001_init.sql` a sleduj, jak jsou navrzene constrainty a indexy.
3. Spust dotazy z `exercises/01_read_replica.sql` a `exercises/02_locking.sql`.
4. Zastav primary a pozoruj, jak se chova replica a backup service.
5. Smaz data a obnov je ze zalohy.

## Zastaveni

```bash
docker compose down
```

Pokud chces smazat i persistentni data:

```bash
docker compose down -v
rm -f backups/*.dump
```