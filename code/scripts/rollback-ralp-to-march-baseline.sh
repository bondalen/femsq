#!/usr/bin/env bash
# Откат домена RALP (ags.ralpRa / ags.ralpRaAu за 2026) к мартовской базе.
#
# База: staging exec_key=1152 (март) + trim/SQL restore.
# Ожидаемый результат: ralpRa_2026=420, ralpRaAu_2026=420.
#
# Использование:
#   ./code/scripts/rollback-ralp-to-march-baseline.sh
#
# Требует запущенный backend (GraphQL executeAudit).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GRAPHQL_URL="${GRAPHQL_URL:-http://127.0.0.1:8080/graphql}"
PROPS="${FEMSQ_DB_PROPS:-$HOME/.femsq/database.properties}"

read_prop() { grep "^$1=" "$PROPS" | head -1 | cut -d= -f2-; }
DB_HOST="$(read_prop host)"
DB_PORT="$(read_prop port)"
DB_NAME="$(read_prop database)"
DB_USER="$(read_prop username)"
DB_PASS="$(read_prop password)"

run_sql() {
  sqlcmd -S "${DB_HOST},${DB_PORT}" -d "$DB_NAME" -U "$DB_USER" -P "$DB_PASS" -C -h -1 -W -Q "SET NOCOUNT ON; $1" 2>/dev/null | tr -d '\r' | sed '/^$/d'
}

echo "=== 1. SQL-восстановление домена из staging exec_key=1152 (март, 420) ==="
sqlcmd -S "${DB_HOST},${DB_PORT}" -d "$DB_NAME" -U "$DB_USER" -P "$DB_PASS" -C -i "$ROOT/code/scripts/restore-ralp-march-baseline-from-staging.sql"

echo "=== 2. Переключение на мартовский снимок ==="
"$ROOT/code/scripts/audit-switch-excel-snapshot.sh" march

echo "=== 3. adt_AddRA=true, dry-run verify (type=5 отключён) ==="
run_sql "UPDATE ags.ra_a SET adt_AddRA = 0 WHERE adt_key = 14;
UPDATE ags.ra_f SET af_execute = 0 WHERE af_key = 312;"

echo "=== 4. executeAudit(14) — verify мартовская идемпотентность ==="
curl -s -X POST "$GRAPHQL_URL" -H 'Content-Type: application/json' \
  -d '{"query":"mutation { executeAudit(id: 14) { started alreadyRunning message } }"}'
echo

"$ROOT/code/scripts/watch-audit-progress.sh" 14 20

echo "=== 5. Проверка домена ==="
run_sql "SELECT COUNT(*) AS ralpRa_2026 FROM ags.ralpRa WHERE ralprY = 2026;
SELECT COUNT(*) AS ralpRaAu_2026 FROM ags.ralpRaAu au JOIN ags.ralpRa r ON au.ralpraRa = r.ralprKey WHERE r.ralprY = 2026;
SELECT MIN(ralprKey) AS ralpr_min, MAX(ralprKey) AS ralpr_max FROM ags.ralpRa WHERE ralprY = 2026;"

echo "=== 6. type=5 снова включён ==="
run_sql "UPDATE ags.ra_f SET af_execute = 1 WHERE af_key = 312;"

echo "Готово."
