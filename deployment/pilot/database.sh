#!/usr/bin/env bash
set -euo pipefail
umask 077

action="$1"
file="$2"
export PGHOST="$DB_HOST"
export PGPORT="$(printenv DB_PORT || printf 5432)"
export PGUSER="$DB_USERNAME"
export PGPASSWORD="$(printenv DB_PASSWORD || true)"
export PGDATABASE="$DB_NAME_PROD"

case "$action" in
  backup)
    if [[ -e "$file" || -e "$file.sha256" ]]; then
      echo "Backup path already exists; choose a new file." >&2
      exit 1
    fi
    partial="$file.part.$$"
    trap 'rm -f -- "$partial"' EXIT
    pg_dump --no-password --format=custom --no-owner --no-acl --file="$partial"
    # A hard link publishes the completed archive without replacing another backup.
    ln -- "$partial" "$file"
    sha256sum -- "$file" | cut -d ' ' -f 1 > "$file.sha256"
    echo "Backup completed: $file"
    ;;
  restore)
    expected="$(cat -- "$file.sha256")"
    actual="$(sha256sum -- "$file" | cut -d ' ' -f 1)"
    if [[ ! "$expected" =~ ^[0-9a-f]{64}$ || "$actual" != "$expected" ]]; then
      echo "Backup checksum mismatch; restoration aborted." >&2
      exit 1
    fi
    objects="$(psql --no-password -X -v ON_ERROR_STOP=1 -Atqc \
      "SELECT COUNT(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname <> 'information_schema'")"
    if [[ "$objects" != "0" ]]; then
      echo "Recovery database must be empty; no existing data was changed." >&2
      exit 1
    fi
    pg_restore --no-password --exit-on-error --single-transaction --no-owner --no-acl \
      --dbname="$PGDATABASE" "$file"
    echo "Restoration completed. Run ops:verify before reopening the application."
    ;;
  *)
    echo "Unknown operation; use backup or restore." >&2
    exit 1
    ;;
esac
