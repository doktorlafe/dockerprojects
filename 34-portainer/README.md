# 34 - Portainer

Webové rozhraní pro správu Dockeru, kontejnerů, image, sítí a volumes.

## Spuštění

```bash
cd 34-portainer
docker compose up -d
```

## Přístup

- Portainer HTTPS: https://localhost:9444
- Portainer HTTP: http://localhost:9001

Při prvním otevření vytvoříš administrační účet a potom vybereš prostředí `local`.

## Co projekt ukazuje

- správu kontejnerů přes GUI
- přehled image, volumes a sítí
- napojení na lokální Docker daemon přes `/var/run/docker.sock`

## Zastavení

```bash
cd 34-portainer
docker compose down
```

Pokud chceš zachovat konfiguraci a data, nemaž volume `portainer_data`.

## Poznámka

Portainer má v tomto příkladu přístup k lokálnímu Docker daemonu přes Docker socket. To je praktické pro lab a domácí prostředí, ale na produkci je potřeba přístup řešit opatrněji.