#!/usr/bin/env bash
# Apply sudz target schema scripts to DEV Docker FishEye.
# Usage: PASS='…' ./apply-dev.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ -z "${PASS:-}" ]]; then
  if [[ -f "${HOME}/.femsq/database.properties" ]]; then
    PASS="$(sed -n 's/^password=//p' "${HOME}/.femsq/database.properties" | head -1)"
  fi
fi
if [[ -z "${PASS:-}" ]]; then
  echo "Set PASS=… or ~/.femsq/database.properties password=" >&2
  exit 1
fi
SQLCMD=(docker exec -i femsq-mssql /opt/mssql-tools18/bin/sqlcmd
  -S localhost -U sa -P "$PASS" -d FishEye -I -b -C)

shopt -s nullglob
files=("$ROOT"/[0-9]*.sql)
if ((${#files[@]} == 0)); then
  echo "No scripts in $ROOT" >&2
  exit 1
fi

# numeric sort
IFS=$'\n' files=($(printf '%s\n' "${files[@]}" | sort -V))
unset IFS

for f in "${files[@]}"; do
  echo "=== $(basename "$f") ==="
  "${SQLCMD[@]}" < "$f"
done

echo "=== SMOKE D644 901/902 ==="
"${SQLCMD[@]}" <<'SQL'
SET NOCOUNT ON;
SELECT 'schema' AS k, name AS v FROM sys.schemas WHERE name = N'sudz';
EXEC sudz.Yr_DbtChangesD644 @yr = 901, @curr_upl = 902;
SQL

echo "OK apply-dev"
