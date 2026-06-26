#!/bin/bash
# =============================================================================
# run_plan_full_chain5.sh — 18.7.4 perf gate: FIXTURE_07 + 07o full chain × 17 dates
# SQL_HOST=10.7.0.3 на Fedora.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_DIR="$SCRIPT_DIR/fixture/dev-chain5-utpl-stcost"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
SQL_HOST="${SQL_HOST:-}"
CONTAINER="${CONTAINER:-femsq-mssql}"
TIMEOUT_FIXTURE="${TIMEOUT_FIXTURE:-600}"
TIMEOUT_07O="${TIMEOUT_07O:-7200}"
LOG="${SCRIPT_DIR}/plan_full_chain5_$(date +%Y%m%d_%H%M%S).log"

run_sql_file() {
    local file="$1"
    local timeout_sec="$2"
    if [[ -n "$SQL_HOST" ]]; then
        timeout "$timeout_sec" sqlcmd -S "$SQL_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C -i "$file"
    else
        timeout "$timeout_sec" docker exec -i "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C -i /dev/stdin < "$file"
    fi
}

echo "=== plan full chain 5 (18.7.4) | log: $LOG ===" | tee "$LOG"
date | tee -a "$LOG"

{
    echo ""
    echo "========== FIXTURE_07_full_chain_sparse =========="
    run_sql_file "$FIXTURE_DIR/FIXTURE_07_full_chain_sparse.sql" "$TIMEOUT_FIXTURE"
} 2>&1 | tee -a "$LOG"
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    echo "FIXTURE_07 FAILED" | tee -a "$LOG"
    exit 1
fi

{
    echo ""
    echo "========== 07o_plan_17dates_chain5 (FULL) =========="
    run_sql_file "$SCRIPT_DIR/07o_plan_17dates_chain5.sql" "$TIMEOUT_07O"
} 2>&1 | tee -a "$LOG"
ec=${PIPESTATUS[0]}
if [[ $ec -ne 0 ]]; then
    echo "07o full chain FAILED (exit $ec)" | tee -a "$LOG"
    exit "$ec"
fi
if ! grep -q '07o.*| PASS' "$LOG"; then
    echo "07o full chain: no PASS in log" | tee -a "$LOG"
    exit 1
fi

echo "" | tee -a "$LOG"
echo "=== plan full chain 5 | PASS ===" | tee -a "$LOG"
date | tee -a "$LOG"
echo "Log: $LOG"
