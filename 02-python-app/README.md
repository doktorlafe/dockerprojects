# 02 - Linux Identity Audit

Python CLI program pro kontrolu lokálních identit na Linux serveru.

## Co kontroluje

- lokální uživatele z `/etc/passwd`
- skupiny z `/etc/group`
- privilegované účty (`UID 0`, `sudo`, `wheel`, `admin`)
- duplicitní `UID` a `GID`
- chybějící primární skupinu
- interaktivní účty bez home adresáře
- příliš volná oprávnění na home adresáři, `.ssh` a `authorized_keys`
- systémové účty s interaktivním shellem

Program je navržený tak, aby běžel i bez root oprávnění. Pokud na některé cesty nevidí, nespadne kvůli tomu celý audit.

## Lokální spuštění

```bash
cd 02-python-app
python app.py
```

JSON výstup:

```bash
python app.py --json
```

Audit i systémových účtů:

```bash
python app.py --include-system
```

## Exit code

- `0`: bez nálezů nad zvolený práh
- `1`: nalezeny warningy nebo errory podle `--fail-on`
- `2`: samotný audit selhal

Příklady:

```bash
python app.py --fail-on error
python app.py --fail-on warning
python app.py --fail-on none
```

## Docker

```bash
cd 02-python-app
docker build -t linux-identity-audit .
docker run --rm linux-identity-audit
```

Pokud chceš auditovat identitu hostitele z kontejneru, je potřeba kontejneru zpřístupnit hostitelské soubory jako `/etc/passwd`, `/etc/group` a případně home adresáře uživatelů.
