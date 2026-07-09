#!/usr/bin/env bash
# Мониторинг хода executeAudit: статус ra_execution, последняя строка Excel, staging-счётчики.
#
# Использование:
#   ./code/scripts/watch-audit-progress.sh [adt_key] [интервал_сек]
#
# Параллельно:
#   curl -s -X POST http://127.0.0.1:8080/graphql -H 'Content-Type: application/json' \
#     -d '{"query":"mutation { executeAudit(id: 14) { started alreadyRunning message } }"}'

set -euo pipefail

ADT_KEY="${1:-14}"
INTERVAL_SEC="${2:-15}"
PROPS="${FEMSQ_DB_PROPS:-$HOME/.femsq/database.properties}"
GRAPHQL_URL="${GRAPHQL_URL:-http://127.0.0.1:8080/graphql}"

if [[ ! -f "$PROPS" ]]; then
  echo "Не найден $PROPS" >&2
  exit 1
fi

read_prop() {
  grep "^$1=" "$PROPS" | head -1 | cut -d= -f2-
}

DB_HOST="$(read_prop host)"
DB_PORT="$(read_prop port)"
DB_NAME="$(read_prop database)"
DB_USER="$(read_prop username)"
DB_PASS="$(read_prop password)"

run_sql() {
  timeout 12 sqlcmd -S "${DB_HOST},${DB_PORT}" -d "$DB_NAME" -U "$DB_USER" -P "$DB_PASS" -C -h -1 -W -Q "SET NOCOUNT ON; $1" 2>/dev/null | tr -d '\r' | sed '/^$/d'
}

graphql_status() {
  timeout 5 curl -s -X POST "$GRAPHQL_URL" -H 'Content-Type: application/json' \
    -d "{\"query\":\"{ audit(id: $ADT_KEY) { adtStatus } }\"}" 2>/dev/null \
    | grep -oE '"adtStatus":"[^"]+"' | head -1 | cut -d'"' -f4 || echo "?"
}

echo "Мониторинг ревизии adt_key=$ADT_KEY (интервал ${INTERVAL_SEC}s). Ctrl+C для выхода."
echo "GraphQL: $GRAPHQL_URL | БД: ${DB_HOST}:${DB_PORT}/${DB_NAME}"
echo "---"

while true; do
  ts="$(date '+%H:%M:%S')"
  mem_status="$(graphql_status)"

  exec_key="$(run_sql "SELECT TOP 1 exec_key FROM ags.ra_execution WHERE exec_adt_key = $ADT_KEY ORDER BY exec_key DESC" || true)"
  exec_status="$(run_sql "SELECT TOP 1 exec_status FROM ags.ra_execution WHERE exec_adt_key = $ADT_KEY ORDER BY exec_key DESC" || true)"
  running_min="$(run_sql "SELECT TOP 1 DATEDIFF(MINUTE, exec_started, SYSUTCDATETIME()) FROM ags.ra_execution WHERE exec_adt_key = $ADT_KEY ORDER BY exec_key DESC" || true)"

  excel_row=""
  stg_ra="?"
  stg_ralp="?"

  if [[ -n "$exec_key" && "$exec_key" =~ ^[0-9]+$ ]]; then
    stg_ra="$(run_sql "SELECT COUNT(*) FROM ags.ra_stg_ra WHERE rain_exec_key = $exec_key" || echo "?")"
    stg_ralp="$(run_sql "SELECT COUNT(*) FROM ags.ra_stg_ralp WHERE ralprt_exec_key = $exec_key" || echo "?")"
    excel_row="$(run_sql "SELECT TOP 1 SUBSTRING(adt_results, LEN(adt_results)-350, 350) FROM ags.ra_a WHERE adt_key = $ADT_KEY" \
      | grep -oE 'строка листа Excel [0-9]+' | grep -oE '[0-9]+$' | tail -1 || true)"
  fi

  printf '%s | mem=%s | exec_key=%s status=%s running_min=%s' \
    "$ts" "$mem_status" "${exec_key:-?}" "${exec_status:-?}" "${running_min:-?}"
  if [[ -n "$excel_row" ]]; then
    printf ' | excel_row≈%s' "$excel_row"
  fi
  printf ' | stg_ra=%s stg_ralp=%s\n' "$stg_ra" "$stg_ralp"

  if [[ "$exec_status" == "COMPLETED" || "$exec_status" == "FAILED" ]]; then
    if [[ "$mem_status" == "COMPLETED" || "$mem_status" == "FAILED" || "$mem_status" == "IDLE" ]]; then
      echo "--- Ревизия завершена: exec_key=$exec_key status=$exec_status ---"
      break
    fi
  fi

  sleep "$INTERVAL_SEC"
done
