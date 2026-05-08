# PasswordKeep

Jednoduchy self-hosted password manager postaveny na Flasku. Uklada hesla zasifrovana v SQLite databazi a pouziva jedno master heslo pro odemceni trezoru.

## Co umi

- prvotni nastaveni master hesla
- prihlaseni do trezoru
- pridani, uprava a smazani zaznamu
- lokalni vyhledavani v zaznamech
- generator silnych hesel
- Docker Compose spusteni s perzistentnimi daty

## Bezpecnostni poznamka

Tohle je vlastni, maly projekt pro osobni pouziti a uceni. Na produkcni nebo firemni pouziti je porad bezpecnejsi pouzit auditovane reseni typu Bitwarden nebo KeePassXC.

## Spusteni

```bash
docker compose up --build
```

Aplikace poběží na `http://localhost:8088`.

## Dulezite

- zmen `SECRET_KEY` v `docker-compose.yml`
- data zustavaji v `./data/passwordkeep.db`
- po restartu kontejneru se vsichni uzivatele odhlasi, samotna data zustanou