#!/usr/bin/env python3
import argparse
import json
import logging
import os
import pwd
import grp
import socket
import stat
import sys
from collections import defaultdict
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


PRIVILEGED_GROUPS = {"sudo", "wheel", "admin"}
NON_LOGIN_SHELLS = {"/usr/sbin/nologin", "/sbin/nologin", "/bin/false", "/usr/bin/false"}


@dataclass
class Finding:
    level: str
    code: str
    message: str
    user: str | None = None
    details: dict[str, Any] | None = None


@dataclass
class UserIdentity:
    username: str
    uid: int
    gid: int
    primary_group: str | None
    groups: list[str]
    gecos: str
    home: str
    shell: str
    login_enabled: bool
    home_exists: bool
    home_mode: str | None
    ssh_dir_exists: bool
    ssh_dir_mode: str | None
    authorized_keys_exists: bool
    authorized_keys_mode: str | None
    privileged: bool


@dataclass
class AuditReport:
    hostname: str
    generated_at: str
    users_examined: int
    groups_examined: int
    privileged_users: list[str]
    findings: list[Finding]


def setup_logging(level_name: str) -> None:
    logging.basicConfig(
        level=getattr(logging, level_name.upper(), logging.INFO),
        format="[%(asctime)s] %(levelname)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Audit lokálních identit na Linux serveru."
    )
    parser.add_argument(
        "--include-system",
        action="store_true",
        help="Zahrnout i systemove ucty s UID < 1000",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Vypsat report jako JSON",
    )
    parser.add_argument(
        "--fail-on",
        choices=["none", "warning", "error"],
        default="error",
        help="Pri jake zavaznosti ma program vratit nenulovy exit code",
    )
    parser.add_argument(
        "--log-level",
        default=os.getenv("LOG_LEVEL", "INFO"),
        help="Uroven logovani, napr. INFO nebo DEBUG",
    )
    return parser.parse_args()


def get_valid_shells() -> set[str]:
    shells_path = Path("/etc/shells")
    if not shells_path.exists():
        return set()

    shells: set[str] = set()
    try:
        for line in shells_path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            shells.add(line)
    except OSError as exc:
        logging.warning("Nepodarilo se nacist /etc/shells: %s", exc)
    return shells


def is_login_shell(shell: str, valid_shells: set[str]) -> bool:
    if not shell or shell in NON_LOGIN_SHELLS:
        return False
    if valid_shells and shell not in valid_shells:
        return False
    return True


def format_mode(path: Path) -> str | None:
    try:
        return oct(path.stat().st_mode & 0o777)
    except OSError:
        return None


def safe_exists(path: Path) -> bool:
    try:
        return path.exists()
    except OSError:
        return False


def safe_is_dir(path: Path) -> bool:
    try:
        return path.is_dir()
    except OSError:
        return False


def is_path_group_or_world_writable(path: Path) -> bool:
    try:
        mode = path.stat().st_mode
    except OSError:
        return False
    return bool(mode & stat.S_IWGRP or mode & stat.S_IWOTH)


def should_include_user(user: pwd.struct_passwd, include_system: bool) -> bool:
    if include_system:
        return True
    return user.pw_uid == 0 or user.pw_uid >= 1000


def collect_users(include_system: bool) -> tuple[list[UserIdentity], int, list[Finding]]:
    findings: list[Finding] = []
    passwd_entries = pwd.getpwall()
    groups = grp.getgrall()
    group_by_gid = {group.gr_gid: group.gr_name for group in groups}
    memberships: dict[str, set[str]] = defaultdict(set)

    for group in groups:
        for member in group.gr_mem:
            memberships[member].add(group.gr_name)

    valid_shells = get_valid_shells()
    identities: list[UserIdentity] = []

    for entry in passwd_entries:
        if not should_include_user(entry, include_system):
            continue

        primary_group = group_by_gid.get(entry.pw_gid)
        if primary_group is None:
            findings.append(
                Finding(
                    level="error",
                    code="missing_primary_group",
                    user=entry.pw_name,
                    message=f"Uzivatel {entry.pw_name} odkazuje na neexistujici primarni GID {entry.pw_gid}.",
                )
            )

        groups_for_user = set(memberships.get(entry.pw_name, set()))
        if primary_group:
            groups_for_user.add(primary_group)

        home_path = Path(entry.pw_dir)
        ssh_dir = home_path / ".ssh"
        authorized_keys = ssh_dir / "authorized_keys"
        login_enabled = is_login_shell(entry.pw_shell, valid_shells)
        privileged = entry.pw_uid == 0 or bool(groups_for_user & PRIVILEGED_GROUPS)
        home_exists = safe_exists(home_path)
        ssh_dir_exists = safe_exists(ssh_dir)
        authorized_keys_exists = safe_exists(authorized_keys)

        if home_exists and format_mode(home_path) is None:
            findings.append(
                Finding(
                    level="warning",
                    code="unreadable_home_metadata",
                    user=entry.pw_name,
                    message=f"Nepodarilo se precist metadata home adresare {entry.pw_dir}.",
                )
            )

        if ssh_dir_exists and format_mode(ssh_dir) is None:
            findings.append(
                Finding(
                    level="warning",
                    code="unreadable_ssh_metadata",
                    user=entry.pw_name,
                    message=f"Nepodarilo se precist metadata adresare {entry.pw_dir}/.ssh.",
                )
            )

        if authorized_keys_exists and format_mode(authorized_keys) is None:
            findings.append(
                Finding(
                    level="warning",
                    code="unreadable_authorized_keys_metadata",
                    user=entry.pw_name,
                    message=f"Nepodarilo se precist metadata souboru {entry.pw_dir}/.ssh/authorized_keys.",
                )
            )

        identities.append(
            UserIdentity(
                username=entry.pw_name,
                uid=entry.pw_uid,
                gid=entry.pw_gid,
                primary_group=primary_group,
                groups=sorted(groups_for_user),
                gecos=entry.pw_gecos,
                home=entry.pw_dir,
                shell=entry.pw_shell,
                login_enabled=login_enabled,
                home_exists=home_exists,
                home_mode=format_mode(home_path),
                ssh_dir_exists=ssh_dir_exists,
                ssh_dir_mode=format_mode(ssh_dir),
                authorized_keys_exists=authorized_keys_exists,
                authorized_keys_mode=format_mode(authorized_keys),
                privileged=privileged,
            )
        )

    return identities, len(groups), findings


def audit_identities(users: list[UserIdentity], preflight_findings: list[Finding]) -> list[Finding]:
    findings = list(preflight_findings)
    by_uid: dict[int, list[str]] = defaultdict(list)

    for user in users:
        by_uid[user.uid].append(user.username)

        if user.uid == 0 and user.username != "root":
            findings.append(
                Finding(
                    level="error",
                    code="unexpected_uid_0",
                    user=user.username,
                    message=f"Uzivatel {user.username} ma UID 0.",
                )
            )

        if user.privileged:
            findings.append(
                Finding(
                    level="warning",
                    code="privileged_account",
                    user=user.username,
                    message=f"Uzivatel {user.username} ma privilegovany pristup.",
                    details={"groups": user.groups, "uid": user.uid},
                )
            )

        if user.login_enabled and not user.home_exists:
            findings.append(
                Finding(
                    level="error",
                    code="missing_home",
                    user=user.username,
                    message=f"Uzivatel {user.username} ma interaktivni shell, ale neexistuje mu home adresar {user.home}.",
                )
            )

        if user.login_enabled and user.home_exists and safe_is_dir(Path(user.home)) and is_path_group_or_world_writable(Path(user.home)):
            findings.append(
                Finding(
                    level="warning",
                    code="unsafe_home_permissions",
                    user=user.username,
                    message=f"Home adresar {user.home} je zapisovatelny pro group/world.",
                    details={"mode": user.home_mode},
                )
            )

        if user.login_enabled and user.ssh_dir_exists and is_path_group_or_world_writable(Path(user.home) / ".ssh"):
            findings.append(
                Finding(
                    level="warning",
                    code="unsafe_ssh_dir_permissions",
                    user=user.username,
                    message=f"Adresar {user.home}/.ssh ma prilis volne pristupove bity.",
                    details={"mode": user.ssh_dir_mode},
                )
            )

        if user.login_enabled and user.authorized_keys_exists and is_path_group_or_world_writable(Path(user.home) / ".ssh" / "authorized_keys"):
            findings.append(
                Finding(
                    level="warning",
                    code="unsafe_authorized_keys_permissions",
                    user=user.username,
                    message=f"Soubor {user.home}/.ssh/authorized_keys ma prilis volne pristupove bity.",
                    details={"mode": user.authorized_keys_mode},
                )
            )

        if user.login_enabled and user.shell in NON_LOGIN_SHELLS:
            findings.append(
                Finding(
                    level="error",
                    code="shell_state_conflict",
                    user=user.username,
                    message=f"Uzivatel {user.username} je oznacen jako login-enabled, ale shell je {user.shell}.",
                )
            )

        if user.uid < 1000 and user.uid != 0 and user.login_enabled:
            findings.append(
                Finding(
                    level="warning",
                    code="interactive_system_account",
                    user=user.username,
                    message=f"Systemovy ucet {user.username} ma interaktivni shell {user.shell}.",
                )
            )

    for uid, usernames in sorted(by_uid.items()):
        if len(usernames) > 1:
            findings.append(
                Finding(
                    level="error",
                    code="duplicate_uid",
                    message=f"UID {uid} sdili vice uctu: {', '.join(sorted(usernames))}.",
                    details={"uid": uid, "users": sorted(usernames)},
                )
            )

    gid_to_groups: dict[int, list[str]] = defaultdict(list)
    for group in grp.getgrall():
        gid_to_groups[group.gr_gid].append(group.gr_name)
    for gid, group_names in sorted(gid_to_groups.items()):
        if len(group_names) > 1:
            findings.append(
                Finding(
                    level="warning",
                    code="duplicate_gid",
                    message=f"GID {gid} sdili vice skupin: {', '.join(sorted(group_names))}.",
                    details={"gid": gid, "groups": sorted(group_names)},
                )
            )

    return findings


def build_report(users: list[UserIdentity], groups_examined: int, findings: list[Finding]) -> AuditReport:
    privileged_users = sorted(user.username for user in users if user.privileged)
    return AuditReport(
        hostname=socket.gethostname(),
        generated_at=datetime.now(timezone.utc).isoformat(),
        users_examined=len(users),
        groups_examined=groups_examined,
        privileged_users=privileged_users,
        findings=findings,
    )


def render_text_report(report: AuditReport) -> str:
    lines = [
        f"Linux identity audit | host={report.hostname}",
        f"Generated at: {report.generated_at}",
        f"Users examined: {report.users_examined}",
        f"Groups examined: {report.groups_examined}",
        f"Privileged users: {', '.join(report.privileged_users) if report.privileged_users else 'none'}",
        "",
    ]

    if not report.findings:
        lines.append("No findings detected.")
        return "\n".join(lines)

    severity_order = {"error": 0, "warning": 1, "info": 2}
    sorted_findings = sorted(
        report.findings,
        key=lambda item: (severity_order.get(item.level, 99), item.user or "", item.code),
    )

    counts = defaultdict(int)
    for finding in sorted_findings:
        counts[finding.level] += 1

    lines.append(
        f"Findings summary: errors={counts['error']} warnings={counts['warning']} info={counts['info']}"
    )
    lines.append("")

    for finding in sorted_findings:
        prefix = finding.level.upper()
        user_suffix = f" | user={finding.user}" if finding.user else ""
        lines.append(f"[{prefix}] {finding.code}{user_suffix} | {finding.message}")
        if finding.details:
            lines.append(f"  details: {json.dumps(finding.details, ensure_ascii=False, sort_keys=True)}")

    return "\n".join(lines)


def exit_code_for_findings(findings: list[Finding], fail_on: str) -> int:
    if fail_on == "none":
        return 0
    if fail_on == "warning" and any(item.level in {"warning", "error"} for item in findings):
        return 1
    if fail_on == "error" and any(item.level == "error" for item in findings):
        return 1
    return 0


def main() -> int:
    args = parse_args()
    setup_logging(args.log_level)

    try:
        users, groups_examined, preflight_findings = collect_users(args.include_system)
        findings = audit_identities(users, preflight_findings)
        report = build_report(users, groups_examined, findings)

        if args.json:
            payload = asdict(report)
            print(json.dumps(payload, ensure_ascii=False, indent=2))
        else:
            print(render_text_report(report))

        return exit_code_for_findings(findings, args.fail_on)
    except PermissionError as exc:
        logging.error("Nedostatecna opravneni pro audit identit: %s", exc)
        return 2
    except Exception as exc:
        logging.exception("Audit identit selhal: %s", exc)
        return 2


if __name__ == "__main__":
    sys.exit(main())
#!/usr/bin/env python3
import os
import sys
import time
import logging
from datetime import datetime
from typing import Optional


def setup_logging() -> None:
    """Inicializace logovani."""
    log_level = os.getenv("LOG_LEVEL", "INFO").upper()
    logging.basicConfig(
        level=getattr(logging, log_level, logging.INFO),
        format='[%(asctime)s] %(levelname)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )


def read_positive_int(name: str, default: int) -> int:
    """Nacte pozitivni cele cislo z prostredi."""
    raw_value = os.getenv(name, str(default))
    try:
        value = int(raw_value)
    except ValueError:
        logging.error(f"Neplatna hodnota pro {name}: {raw_value}")
        sys.exit(1)

    if value < 1:
        logging.error(f"Promenna {name} musi byt vetsi nebo rovna 1.")
        sys.exit(1)

    return value


def validate_config(app_name: str, total_steps: int, delay_ms: int, mode: str) -> bool:
    """Validace konfigurace aplikace."""
    if not app_name or not isinstance(app_name, str):
        logging.error("APP_NAME musi byt neprazdny string")
        return False
    if mode not in ["demo", "production", "test"]:
        logging.warning(f"Neznamy rezim '{mode}', pouziti 'demo'")
    return True


def main() -> Optional[int]:
    """Hlavni funkce aplikace."""
    try:
        setup_logging()
        
        app_name = os.getenv("APP_NAME", "Docker Python Test App")
        total_steps = read_positive_int("APP_STEPS", 5)
        delay_ms = read_positive_int("APP_DELAY_MS", 1000)
        mode = os.getenv("APP_MODE", "demo")
        delay_seconds = delay_ms / 1000

        if not validate_config(app_name, total_steps, delay_ms, mode):
            return 1

        logging.info(f"Start aplikace: {app_name}")
        logging.info(f"Rezim: {mode}")
        logging.info(f"PID: {os.getpid()}")
        logging.info(f"Pocet kroku: {total_steps}")
        logging.info(f"Zpozdeni mezi kroky: {delay_ms} ms")
        logging.info("-" * 40)

        for step in range(1, total_steps + 1):
            try:
                progress = int((step / total_steps) * 100)
                logging.info(f"Krok {step}/{total_steps} | progress={progress}% | stav=OK")
                time.sleep(delay_seconds)
            except KeyboardInterrupt:
                logging.warning("Aplikace prerusena uzivatelem")
                return 130
            except Exception as e:
                logging.error(f"Chyba pri vykonani kroku {step}: {e}")
                return 1

        logging.info("-" * 40)
        logging.info("Test probehl uspesne.")
        return 0

    except Exception as e:
        logging.exception(f"Neocekayana chyba: {e}")
        return 1


if __name__ == "__main__":
    exit_code = main() or 0
    sys.exit(exit_code)
