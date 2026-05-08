# 33-sandboxdockerALL

Tato složka obsahuje pomocný sandbox pro bezpečné spouštění Docker příkladů z tohoto repozitáře odděleně od hlavního Docker prostředí hostitele.

Skript `docker-sandbox.sh` spouští kontejner typu Docker-in-Docker (`docker:27-dind`). Uvnitř tohoto kontejneru běží samostatný Docker daemon. Díky tomu se kontejnery, sítě, image a volumes vytvářejí jen uvnitř sandboxu a nemíchají se s hlavním Dockerem na serveru.

## Kdy to použít

Použij tento script, když chceš:

- testovat více Docker ukázek bez nepořádku v host Dockeru
- izolovat porty, kontejnery a volumes od hlavního systému
- hromadně spouštět projekty přes `docker-projects.sh`, ale uvnitř odděleného prostředí

## Co script dělá při startu

Příkaz `./docker-sandbox.sh start` provede:

1. ověření, že je dostupný příkaz `docker`
2. kontrolu, jestli sandbox kontejner už existuje nebo běží
3. pokud sandbox ještě neexistuje:
   - vytvoří volume `docker-examples-sandbox-data`
   - spustí kontejner `docker-examples-sandbox`
   - připojí aktuální složku do kontejneru jako `/workspace`
4. čeká, až uvnitř kontejneru naběhne Docker daemon

Použitý image je `docker:27-dind`.

## Přehled příkazů

### `start`

Spustí sandbox.

Co přesně dělá:

- pokud sandbox už běží, nic nového nevytváří
- pokud sandbox existuje, ale je zastavený, zavolá `docker start`
- pokud ještě neexistuje, zavolá zhruba tento příkaz:

```bash
docker run -d \
  --privileged \
  --name docker-examples-sandbox \
  --hostname docker-examples-sandbox \
  -e DOCKER_TLS_CERTDIR= \
  -v docker-examples-sandbox-data:/var/lib/docker \
  -v <tato-slozka>:/workspace \
  -w /workspace \
  docker:27-dind
```

Význam parametrů:

- `-d`: spustí kontejner na pozadí
- `--privileged`: dovolí Docker-in-Docker běžet uvnitř kontejneru
- `--name`: nastaví pevné jméno sandbox kontejneru
- `--hostname`: nastaví hostname uvnitř kontejneru
- `-e DOCKER_TLS_CERTDIR=`: vypne automatické TLS certifikáty uvnitř DinD image
- `-v docker-examples-sandbox-data:/var/lib/docker`: ukládá interní Docker data do persistentního volume
- `-v <tato-slozka>:/workspace`: zpřístupní repozitář uvnitř sandboxu
- `-w /workspace`: nastaví pracovní adresář uvnitř kontejneru

### `stop`

Zastaví sandbox kontejner:

```bash
docker stop docker-examples-sandbox
```

Data ale zůstávají zachovaná ve volume, takže další `start` naváže na předchozí stav.

### `clean`

Vyčistí Docker prostředí uvnitř sandboxu, nikoliv na hostiteli.

Script uvnitř sandboxu spustí:

```bash
docker ps -aq
docker stop <vsechny-kontejnery>
docker system prune -af --volumes
```

Co to znamená:

- zastaví všechny kontejnery uvnitř sandboxu
- smaže nepoužívané image
- smaže nepoužívané sítě
- smaže nepoužívané volumes
- ponechá samotný sandbox kontejner běžet

Je to vhodné, když chceš sandbox vyprázdnit, ale nechceš ho celý mazat a znovu vytvářet.

### `destroy`

Odstraní sandbox úplně:

```bash
docker rm -f docker-examples-sandbox
docker volume rm docker-examples-sandbox-data
```

Tím se smaže:

- sandbox kontejner
- veškerý interní Docker stav sandboxu

Použij to jen tehdy, když chceš začít úplně od nuly.

### `list`

Spustí uvnitř sandboxu:

```bash
./docker-projects.sh list
```

Tím vypíše dostupné projekty, které lze přes hlavní launcher spravovat.

### `status`

Ukáže, jestli sandbox existuje a běží.

Pokud běží, script navíc spustí:

```bash
docker exec docker-examples-sandbox docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
```

Takže uvidíš kontejnery běžící uvnitř sandbox Docker daemonu.

### `up <projekt|all>`

Spustí launcher uvnitř sandboxu:

```bash
./docker-projects.sh up 03-nodejs-server
./docker-projects.sh up all
```

To znamená:

- nevolá Docker na hostiteli
- veškeré `docker build`, `docker run` nebo `docker compose up` běží jen uvnitř sandboxu

Příklady:

```bash
./docker-sandbox.sh up 03-nodejs-server
./docker-sandbox.sh up 14-react-nodejs-api
./docker-sandbox.sh up all
```

### `down <projekt|all>`

Zastaví projekt nebo všechny projekty uvnitř sandboxu:

```bash
./docker-sandbox.sh down 03-nodejs-server
./docker-sandbox.sh down all
```

Opět se to týká jen Dockeru běžícího uvnitř sandboxu.

### `shell`

Otevře shell uvnitř sandbox kontejneru:

```bash
docker exec -it docker-examples-sandbox sh
```

To se hodí pro ruční diagnostiku, například:

```bash
./docker-sandbox.sh shell
docker ps
docker images
docker volume ls
```

## Jak script interně funguje

### Kontroly stavu

Script rozlišuje dva stavy:

- `sandbox_exists`: kontejner s daným jménem existuje
- `sandbox_running`: kontejner právě běží

To je důležité proto, že `start` může buď:

- nic neudělat, pokud už běží
- nastartovat existující kontejner
- vytvořit úplně nový kontejner

### Čekání na Docker daemon

Po startu script nečeká jen na spuštění kontejneru, ale i na spuštění Docker daemonu uvnitř něj. Dělá to opakovaným testem:

```bash
docker exec docker-examples-sandbox docker info
```

Když tento příkaz začne fungovat, je sandbox připravený.

### Spouštění příkazů uvnitř sandboxu

Většina akcí používá:

```bash
docker exec -it docker-examples-sandbox sh -lc "<prikaz>"
```

To znamená:

- `docker exec`: spustí příkaz v existujícím kontejneru
- `-it`: interaktivní režim s terminálem
- `sh -lc`: příkaz spustí přes shell, takže fungují argumenty i složitější příkazy

## Typický workflow

```bash
./docker-sandbox.sh start
./docker-sandbox.sh list
./docker-sandbox.sh up 03-nodejs-server
./docker-sandbox.sh status
./docker-sandbox.sh shell
./docker-sandbox.sh down 03-nodejs-server
./docker-sandbox.sh clean
./docker-sandbox.sh stop
```

## Rozdíl mezi `stop`, `clean` a `destroy`

- `stop`: zastaví jen sandbox kontejner, data zůstávají
- `clean`: nechá sandbox běžet, ale smaže Docker objekty uvnitř něj
- `destroy`: smaže sandbox kontejner i jeho data volume

## Omezení a poznámky

- sandbox používá `--privileged`, takže je vhodný hlavně pro lokální lab a testovací prostředí
- porty publikované uvnitř sandboxu nejsou automaticky publikované na hostiteli, protože sandbox kontejner sám nemá mapované porty ven
- pokud uvnitř sandboxu spustíš službu na portu `3000`, bude dostupná uvnitř sandboxu, ne automaticky na host serveru
- script předpokládá, že v té samé složce existuje i `docker-projects.sh`

## Rychlá nápověda

```bash
./docker-sandbox.sh start     # vytvoří/spustí sandbox
./docker-sandbox.sh list      # vypíše projekty
./docker-sandbox.sh up all    # spustí všechny podporované projekty uvnitř sandboxu
./docker-sandbox.sh status    # vypíše stav sandboxu a běžící kontejnery
./docker-sandbox.sh clean     # vyčistí Docker uvnitř sandboxu
./docker-sandbox.sh stop      # zastaví sandbox
./docker-sandbox.sh destroy   # smaže sandbox i data
```