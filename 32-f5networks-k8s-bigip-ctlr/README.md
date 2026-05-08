# 32 - F5 BIG-IP CIS v Dockeru

Ukázka pro spuštění image `f5networks/k8s-bigip-ctlr` přes Docker Compose.

Pokud teď vidíš chybu `unable to load in-cluster configuration, KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT must be defined`, znamená to prakticky vždycky jediné: CIS nenašel tvůj `kubeconfig` soubor.

Důležité: tenhle controller je primárně určený pro Kubernetes nebo OpenShift a pro skutečný běh potřebuje:

- přístup ke Kubernetes API přes `kubeconfig`
- přístup k F5 BIG-IP zařízení
- platné přihlašovací údaje a partition

Proto jsou v ukázce dvě varianty:

- `cis-smoke`: rychlý smoke test image bez dalších závislostí
- `cis`: plný běh controlleru s parametry pro BIG-IP a Kubernetes

## 1. Smoke test image

Tohle jen ověří, že image jde stáhnout a spustit:

```bash
cd 32-f5networks-k8s-bigip-ctlr
docker compose --profile smoke run --rm cis-smoke
```

## 2. Plný běh controlleru

Nejdřív připrav proměnné prostředí:

```bash
cd 32-f5networks-k8s-bigip-ctlr
cp .env.example .env
```

Pak uprav `.env` podle svého prostředí:

- `KUBECONFIG_PATH`: cesta ke kubeconfig souboru na hostu
- `BIGIP_URL`: adresa nebo hostname BIG-IP
- `BIGIP_USERNAME`: uživatel pro BIG-IP
- `BIGIP_PASSWORD`: heslo pro BIG-IP
- `BIGIP_PARTITION`: partition, do které bude CIS zapisovat
- `K8S_NAMESPACE`: namespace, který má CIS sledovat

Máš dvě možnosti:

- nech výchozí `KUBECONFIG_PATH=./config/kubeconfig` a vlož soubor do `config/kubeconfig`
- nebo nastav `KUBECONFIG_PATH` na absolutní cestu k už existujícímu kubeconfig souboru

Příklad s lokálním souborem v projektu:

```bash
cd 32-f5networks-k8s-bigip-ctlr
mkdir -p config
cp /cesta/k/tvemu/kubeconfig ./config/kubeconfig
```

Příklad s absolutní cestou v `.env`:

```bash
KUBECONFIG_PATH=/absolutni/cesta/ke/kubeconfig
```

Spuštění:

```bash
cd 32-f5networks-k8s-bigip-ctlr
docker compose up -d
```

Logy:

```bash
docker compose logs -f cis
```

Zastavení:

```bash
docker compose down
```

## Co je vystavené ven

- `8080`: HTTP endpoint controlleru pro health a metrics

## Poznámka

Samotné `docker compose up` nebude bez reálného BIG-IP a validního `kubeconfig` fungovat korektně. Pokud chceš jen ověřit image, použij smoke test výše.

Pokud CIS po startu spadne, první kontrola je:

```bash
ls -l ./config
```

nebo zkontroluj, že `KUBECONFIG_PATH` v `.env` ukazuje na skutečný existující soubor.