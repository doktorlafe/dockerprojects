# 30 Docker Příkladů - Tiered Difficulty Guide

## TIER 1: Začátečník (Příklady 1-10)

### 1. Spuštění základní image - Alpine Linux
```bash
docker run alpine echo "Hello Docker!"
```
**Popis:** Nejjednoduší příklad. Stáhne malou Alpine Linux image a spustí echo příkaz.

---

### 2. Spuštění interaktivního shellů
```bash
docker run -it ubuntu /bin/bash
```
**Popis:** `-it` flag umožňuje interaktivní přístup do kontejneru. Můžete psát příkazy přímo.

---

### 3. Spuštění webového serveru - Nginx
```bash
docker run -d -p 8080:80 nginx
```
**Popis:** `-d` = background, `-p 8080:80` = mapuje port. Webový server běží na http://localhost:8080

---

### 4. Listování spuštěných kontejnerů
```bash
docker ps
docker ps -a  # všechny kontejnery včetně zastavených
```
**Popis:** `docker ps` ukazuje aktivní kontejnery, `-a` zobrazí i zastavené.

---

### 5. Zastavení a smazání kontejneru
```bash
docker stop <container_id>
docker rm <container_id>
```
**Popis:** `stop` zastaví kontejner, `rm` ho smaže. ID najdete v `docker ps`.

---

### 6. Spuštění MySQL databáze
```bash
docker run -d --name mydb -e MYSQL_ROOT_PASSWORD=secret mysql:8.0
```
**Popis:** Spustí MySQL databázi v pozadí s názvem a heslem.

---

### 7. Prohlížení logů kontejneru
```bash
docker logs <container_id>
docker logs -f <container_id>  # live stream
```
**Popis:** `logs` zobrazí výstup, `-f` sleduje nové zprávy v reálném čase.

---

### 8. Vstup do běžícího kontejneru
```bash
docker exec -it <container_id> /bin/bash
```
**Popis:** Umožňuje spustit příkazy uvnitř běžícího kontejneru bez restartování.

---

### 9. Vytvoření Dockerfile pro Python aplikaci
```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY . .
RUN pip install flask
CMD ["python", "app.py"]
```
**Popis:** Základní Dockerfile pro Python Flask aplikaci. Definuje základní image, pracovní adresář, kopíruje kód a spouští aplikaci.

---

### 10. Build a spuštění vlastní image
```bash
docker build -t myapp:1.0 .
docker run -d -p 5000:5000 myapp:1.0
```
**Popis:** Vytvoří image z Dockerfile a spustí ji. `-t` nastavuje tag (jméno).

---

## TIER 2: Středně pokročilý (Příklady 11-20)

### 11. Multi-stage build pro optimalizaci velikosti
```dockerfile
FROM golang:1.19 AS builder
WORKDIR /app
COPY . .
RUN go build -o app .

FROM alpine:latest
COPY --from=builder /app/app /app
CMD ["/app"]
```
**Popis:** Dva stage - první builduje aplikaci, druhý obsahuje jen binárku. Výrazně menší finální image.

---

### 12. Docker Compose - více služeb
```yaml
version: '3.8'
services:
  web:
    image: nginx
    ports:
      - "8080:80"
  db:
    image: postgres:13
    environment:
      POSTGRES_PASSWORD: secret
```
**Popis:** Spustí Nginx a PostgreSQL společně jedním příkazem `docker-compose up`.

---

### 13. Volumes - trvalé uložení dat
```bash
docker run -d -v /home/data:/data postgres:13
```
**Popis:** `-v` vytvoří volume. Data z /data uvnitř kontejneru se uloží na disku.

---

### 14. Environment proměnné v kontejneru
```bash
docker run -d -e DB_HOST=localhost -e DB_PORT=5432 myapp
```
**Popis:** `-e` nastavuje proměnné, které aplikace může číst.

---

### 15. Network mezi kontejnery
```bash
docker network create mynet
docker run -d --network mynet --name db postgres
docker run -d --network mynet --name app myapp
```
**Popis:** Vytvoří vlastní síť, kde se kontejnery mohou vzájemně oslovit jménem.

---

### 16. Health check pro kontejner
```dockerfile
FROM nginx
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost/ || exit 1
```
**Popis:** Docker automaticky kontroluje zdraví aplikace každých 30 sekund.

---

### 17. Resource limity pro kontejner
```bash
docker run -d --memory="512m" --cpus="1" nginx
```
**Popis:** Limituje RAM na 512MB a CPU na 1 jádro. Zabraňuje hltavým aplikacím.

---

### 18. Docker Registry - push image
```bash
docker login
docker tag myapp:1.0 myusername/myapp:1.0
docker push myusername/myapp:1.0
```
**Popis:** Přihlásí se do Docker Hubu a nahraje image na registry.

---

### 19. ARG a BUILD_ARG - parametrizace Dockerfile
```dockerfile
ARG PYTHON_VERSION=3.9
FROM python:${PYTHON_VERSION}
ARG APP_NAME=myapp
WORKDIR /app
```
**Popis:** Parametry lze nastavit při buildu: `docker build --build-arg PYTHON_VERSION=3.11 .`

---

### 20. Copy vs Add - kopírování souborů
```dockerfile
FROM alpine
COPY ./src /app/src
ADD ./archive.tar.gz /app/
```
**Popis:** `COPY` jednoduše kopíruje. `ADD` umí rozbalit archivy a tažení z URL.

---

## TIER 3: Pokročilý (Příklady 21-30)

### 21. Dockerfile s секret managementem
```dockerfile
FROM ubuntu
RUN --mount=type=secret,id=mysecret cat /run/secrets/mysecret
```
**Popis:** Build s tajnými údaji bez jejich zahrnutí v image vrstvě. 

```bash
docker build --secret id=mysecret,src=secret.txt .
```

---

### 22. Docker Swarm - orchestrace
```bash
docker swarm init
docker service create --name web --replicas 3 -p 8080:80 nginx
docker service scale web=5
```
**Popis:** Vytvoří cluster a nasadí službu s 3 replikami. Automaticky load-balancuje.

---

### 23. Kubernetes - YAML manifest
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    ports:
    - containerPort: 5000
    resources:
      limits:
        memory: "512Mi"
        cpu: "500m"
```
**Popis:** Kubernetes definice. Deploy: `kubectl apply -f pod.yaml`

---

### 24. Networking - custom bridge
```bash
docker network create --driver bridge --subnet=172.20.0.0/16 mynet
docker run -d --network mynet --ip 172.20.0.2 nginx
```
**Popis:** Vytvoří síť s vlastním subntem a přiřadí kontejneru statickou IP.

---

### 25. Multi-compose orchestrace s Traefik
```yaml
version: '3.8'
services:
  traefik:
    image: traefik:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
  
  web:
    image: nginx
    labels:
      - "traefik.http.routers.web.rule=Host(`example.com`)"
```
**Popis:** Traefik jako reverse proxy pro více služeb s automatickým routingem.

---

### 26. Docker Security - seccomp a AppArmor
```bash
docker run --security-opt seccomp=unconfined \
  --security-opt apparmor=docker-default \
  -it ubuntu
```
**Popis:** Nastavuje bezpečnostní profily pro omezení syscall.

---

### 27. Tmpfs a anonymní volumes
```bash
docker run -d --tmpfs /tmp:size=1G \
  -v /data --name app myimage
```
**Popis:** `/tmp` je jen v paměti, `/data` je anonymní volume.

---

### 28. Buildkit - paralelní builds
```bash
DOCKER_BUILDKIT=1 docker build -t myapp .
```
**Pbeskop:** Paralelní buildování vrstev pro zrychlení. Vyžaduje BuildKit.

---

### 29. Docker Compose deployment s conditions
```yaml
version: '3.8'
services:
  db:
    image: postgres
    healthcheck:
      test: ["CMD", "pg_isready"]
  
  app:
    image: myapp
    depends_on:
      db:
        condition: service_healthy
```
**Popis:** Aplikace se spustí jen když je databáze zdravá.

---

### 30. Private registry s autentizací a TLS
```bash
docker run -d -p 5000:5000 \
  -v /certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/cert.pem \
  -e REGISTRY_HTTP_TLS_KEY=/certs/key.pem \
  registry:2
```
**Popis:** Privátní Docker Registry s šifrováním. Vytvořuje bezpečný interní katalog obrazů.

---

## Shrnutí podle tiers:

**Tier 1 (Základy):** Spouštění imagí, základní kontejnery, web servery
**Tier 2 (Intermediate):** Compose, volumes, networking, registry, optimization
**Tier 3 (Pokročilé):** Orchestrace, security, Kubernetes, custom networking, production setups

---

## Užitečné příkazy na závěr:

```bash
# Čištění
docker system prune -a              # Smaže nepoužívané objekty
docker image prune -a               # Smaže nepoužívané images
docker volume prune                 # Smaže nepoužívané volumes

# Inspekce
docker inspect <container>          # Detailní info o kontejneru
docker stats                        # Reálné využívání zdrojů
docker history myimage:1.0          # Historie vrstev image
```
