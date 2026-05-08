# 25 - Traefik Reverse Proxy

Traefik reverse proxy s automatickým routingem.

## Spuštění

```bash
cd 25-traefik-reverse-proxy
docker compose up -d
```

- Traefik Dashboard: http://localhost:8051
- App1: http://app1.localhost:8050
- App2: http://app2.localhost:8050

(Přidej do /etc/hosts: 127.0.0.1 app1.localhost app2.localhost)

## Jak to funguje

- Traefik přijímá webový provoz na host portu `8050`
- podle hostname přesměruje požadavek na `app1` nebo `app2`
- dashboard Traefiku běží samostatně na `8051`

## Rychlý test bez DNS

Pokud se hostname nechová správně, můžeš routing ověřit i přes `curl`:

```bash
curl -H "Host: app1.localhost" http://localhost:8050
curl -H "Host: app2.localhost" http://localhost:8050
```
