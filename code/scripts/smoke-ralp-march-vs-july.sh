#!/usr/bin/env bash
# Smoke RALP: март dry-run → июль dry-run → июль apply.
# Предусловие: домен восстановлен до мартовской базы (1248).
# После smoke выполните: ./code/scripts/rollback-ralp-to-march-baseline.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GRAPHQL_URL="${GRAPHQL_URL:-http://127.0.0.1:8080/graphql}"
PROPS="${FEMSQ_DB_PROPS:-$HOME/.femsq/database.properties}"
LOG="${RALP_SMOKE_LOG:-/tmp/femsq-web-smoke.log}"

read_prop() { grep "^$1=" "$PROPS" | head -1 | cut -d= -f2-; }
DB_HOST="$(read_prop host)"
DB_PORT="$(read_prop port)"
DB_NAME="$(read_prop database)"
DB_USER="$(read_prop username)"
DB_PASS="$(read_prop password)"

run_sql() {
  sqlcmd -S "${DB_HOST},${DB_PORT}" -d "$DB_NAME" -U "$DB_USER" -P "$DB_PASS" -C -h -1 -W -Q "SET NOCOUNT ON; $1" 2>/dev/null | tr -d '\r' | sed '/^$/d'
}

run_audit() {
  local label="$1"
  local add_ra="$2"
  local snapshot="$3"
  local log_mark="$4"

  echo ""
  echo "========== $label (adt_AddRA=$add_ra, snapshot=$snapshot) =========="
  "$ROOT/code/scripts/audit-switch-excel-snapshot.sh" "$snapshot"
  run_sql "UPDATE ags.ra_a SET adt_AddRA = $add_ra WHERE adt_key = 14;
UPDATE ags.ra_f SET af_execute = 0 WHERE af_key = 312;"

  local before_exec
  before_exec="$(run_sql "SELECT ISNULL(MAX(exec_key),0) FROM ags.ra_execution WHERE exec_adt_key=14")"

  curl -s -X POST "$GRAPHQL_URL" -H 'Content-Type: application/json' \
    -d '{"query":"mutation { executeAudit(id: 14) { started alreadyRunning message } }"}'
  echo
  "$ROOT/code/scripts/watch-audit-progress.sh" 14 15

  local exec_key
  exec_key="$(run_sql "SELECT MAX(exec_key) FROM ags.ra_execution WHERE exec_adt_key=14")"
  echo "exec_key=$exec_key"

  grep "\[RALP\] done" "$LOG" | tail -1 || true
  run_sql "SELECT COUNT(*) AS ralpRa_2026 FROM ags.ralpRa WHERE ralprY=2026;
SELECT COUNT(*) AS stg_ralp FROM ags.ra_stg_ralp WHERE ralprt_exec_key=$exec_key;"

  echo "$log_mark exec_key=$exec_key" >> /tmp/ralp-smoke-march-vs-july.txt
}

: > /tmp/ralp-smoke-march-vs-july.txt

run_audit "Март dry-run (baseline)" 0 march "MARCH_DRY"
run_audit "Июль dry-run" 0 july "JULY_DRY"
run_audit "Июль apply" 1 july "JULY_APPLY"

run_sql "UPDATE ags.ra_a SET adt_AddRA = 0 WHERE adt_key = 14;
UPDATE ags.ra_f SET af_execute = 1 WHERE af_key = 312;"

echo ""
echo "Smoke завершён. Откат: ./code/scripts/rollback-ralp-to-march-baseline.sh"
cat /tmp/ralp-smoke-march-vs-july.txt
