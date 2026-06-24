#!/bin/bash
# =============================================================================
# run_07p_aggregate_chain5.sh — этап 18.7.3, агрегация плана на 17 датах
# SQL_HOST=10.7.0.3 на Fedora.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
SQL_HOST="${SQL_HOST:-}"
CONTAINER="${CONTAINER:-femsq-mssql}"
TIMEOUT_SEC="${TIMEOUT_SEC:-600}"
LOG="${SCRIPT_DIR}/07p_aggregate_$(date +%Y%m%d_%H%M%S).log"

run_sql() {
    if [[ -n "$SQL_HOST" ]]; then
        timeout "$TIMEOUT_SEC" sqlcmd -S "$SQL_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C -i "$1"
    else
        timeout "$TIMEOUT_SEC" docker exec -i "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C -i /dev/stdin < "$1"
    fi
}

echo "=== 07p plan aggregate | log: $LOG ===" | tee "$LOG"
date | tee -a "$LOG"

run_sql "$SCRIPT_DIR/07p_plan_aggregate_chain5.sql" 2>&1 | tee -a "$LOG"
ec=${PIPESTATUS[0]}

if grep -q '07p.*| PASS' "$LOG"; then
    echo "=== 07p finished OK ===" | tee -a "$LOG"
elif [[ $ec -ne 0 ]]; then
    echo "=== 07p FAILED (exit $ec) ===" | tee -a "$LOG"
    exit "$ec"
else
    echo "=== 07p FAIL in output ===" | tee -a "$LOG"
    exit 1
fi
date | tee -a "$LOG"
echo "Log: $LOG"
