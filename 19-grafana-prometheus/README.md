# 19 - Grafana + Prometheus

Monitoring a vizualizace metrik.

## Spuštění

```bash
cd 19-grafana-prometheus
docker compose up
```

- Grafana: http://localhost:3001 (admin/admin)
- Prometheus: http://localhost:9090

## Windows 11 Monitoring

Nejjednodussi cesta je pouzit `windows_exporter` na Windows 11 PC a nechat Prometheus ten exporter scrapeovat.

## Jak to funguje

V tomhle stacku jsou 3 ruzne vrstvy:

1. `windows_exporter`
	To je proces na Windows 11, ktery sam generuje metriky na `http://WINDOWS_IP:9182/metrics`.
	Bez nej nebude Prometheus mit co cist.

2. `scrape_configs` v `prometheus.yml`
	Tady se definuje odkud Prometheus data taha.
	V tomhle projektu je to job `windows11`, ktery cte targety ze souboru `targets/windows11.yml`.

3. `rule_files`
	Tady jsou recording nebo alert pravidla nad uz nasbiranymi metrikami.
	V tomhle projektu jsou sample alerty v `rules/windows11-alerts.yml`.

To znamena:
- nazvy metrik typu `windows_cpu_time_total` nebo `windows_os_visible_memory_bytes` nedefinuje Prometheus
- tyto metriky dodava `windows_exporter`
- Prometheus pouze rika, odkud je ma scrapovat a jaka pravidla nad nimi ma vyhodnocovat

### 1. Nainstaluj windows_exporter na Windows 11

Na Windows nainstaluj exporter tak, aby poslouchal na portu `9182`.

Muzes pouzit MSI instalator z projektu `prometheus-community/windows_exporter` nebo `winget`:

```powershell
winget install prometheuscommunity.windows-exporter
```

Po instalaci over, ze je exporter dostupny:

```powershell
curl http://localhost:9182/metrics
```

Pokud tenhle prikaz na Windows nevypise dlouhy text s radky jako `windows_cpu_time_total ...`, Prometheus nebude mit co sbirat.

### 2. Uprav target v Prometheu

V souboru `targets/windows11.yml` nastav IP adresu sveho Windows 11 PC:

```yaml
- targets:
		- 192.168.1.100:9182
	labels:
		instance: windows11-pc
```

Pokud Prometheus bezi na jinem stroji nebo ve WSL/Dockeru, musi byt Windows firewall otevreny pro TCP `9182`.

Z Linux/WSL musi fungovat i tento test:

```bash
curl http://192.168.0.109:9182/metrics
```

Pokud timeoutuje, problem jeste neni v Prometheu, ale v tom, ze se k exporteru neda sitove dostat.

### 3. Restartuj stack

```bash
cd 19-grafana-prometheus
docker compose up -d
```

### 4. Otevri Grafanu

- Grafana: `http://localhost:3001`
- login: `admin / admin`

Datasource `Prometheus` se nacte automaticky.
Dashboard `Windows 11 Overview` se taky nacte automaticky do slozky `Windows`.

### 5. Co dashboard ukazuje

- vyuziti CPU
- vyuziti RAM
- vyuzitou pamet v bytech
- sitovy provoz
- vyvoj CPU a RAM v case

## Poznamky

- pokud je port `3000` na hostu uz obsazeny jinym kontejnerem, Grafana je v tomto prikladu zamerne vystavena na `3001`
- pokud v Grafane nevidis zadna data, nejdriv over `http://WINDOWS_IP:9182/metrics` a potom target v Prometheu na `http://localhost:9090/targets`
- sample alert pravidla jsou v `rules/windows11-alerts.yml`, ale bez beziciho `windows_exporter` nebudou mit zadna data
