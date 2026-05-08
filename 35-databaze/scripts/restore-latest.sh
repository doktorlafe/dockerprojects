#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

latest_backup="${1:-$(ls -1t backups/*.dump 2>/dev/null | head -n 1 || true)}"

if [[ -z "$latest_backup" ]]; then
  echo "No backup file found in backups/." >&2
  exit 1
fi

database_name="${POSTGRES_DB:-appdb}"
superuser_name="${POSTGRES_SUPERUSER:-admin}"

echo "Restoring backup: $latest_backup"

docker compose exec -T postgres-primary psql -U "$superuser_name" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$database_name' AND pid <> pg_backend_pid();" >/dev/null
docker compose exec -T postgres-primary dropdb -U "$superuser_name" --if-exists "$database_name"
docker compose exec -T postgres-primary createdb -U "$superuser_name" "$database_name"
docker compose exec -T postgres-primary pg_restore -U "$superuser_name" -d "$database_name" --clean --if-exists --no-owner --no-privileges < "$latest_backup"

echo "Restore finished."