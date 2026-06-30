#!/bin/bash
# =============================================================================
# run_07o_cst2102_17dates.sh — 07o strict plan @ 17 дат, пилот cstAgPn=2102
# После FIXTURE_06. SQL_HOST=10.7.0.3 на Fedora.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_DIR="$SCRIPT_DIR/fixture/dev-chain5-utpl-stcost"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
SQL_HOST="${SQL_HOST:-}"
CONTAINER="${CONTAINER:-femsq-mssql}"
TIMEOUT_SEC="${TIMEOUT_SEC:-900}"
LOG="${SCRIPT_DIR}/07o_cst2102_17dates_$(date +%Y%m%d_%H%M%S).log"

run_remote() {
    timeout "$TIMEOUT_SEC" sqlcmd -S "$SQL_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
        -i "$1" 2>&1 | tee -a "$LOG"
}

run_docker() {
    timeout "$TIMEOUT_SEC" docker exec -i "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
        -i /dev/stdin < "$1" 2>&1 | tee -a "$LOG"
}

echo "=== 07o cst 2102 × 17 dates | log: $LOG ===" | tee "$LOG"
date | tee -a "$LOG"

echo "" | tee -a "$LOG"
echo "========== FIXTURE_06 check ==========" | tee -a "$LOG"
CHK="SET NOCOUNT ON; SELECT CASE WHEN EXISTS (SELECT 1 FROM ags.ipgChRl_2606 WHERE ipgcrvChain=5 AND ipgcrvUtPlGr=18) THEN 1 ELSE 0 END AS ok;"
if [[ -n "$SQL_HOST" ]]; then
    sqlcmd -S "$SQL_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C -Q "$CHK" | tee -a "$LOG"
else
    docker exec -i "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C -Q "$CHK" | tee -a "$LOG"
fi

echo "" | tee -a "$LOG"
echo "========== 07o_plan_17dates_cst_chain5.sql (timeout ${TIMEOUT_SEC}s) ==========" | tee -a "$LOG"

if [[ -n "$SQL_HOST" ]]; then
    run_remote "$SCRIPT_DIR/07o_plan_17dates_cst_chain5.sql"
else
    run_docker "$SCRIPT_DIR/07o_plan_17dates_cst_chain5.sql"
fi
ec=${PIPESTATUS[0]}

echo "" | tee -a "$LOG"
if [[ $ec -eq 0 ]]; then
    echo "=== 07o finished OK ===" | tee -a "$LOG"
else
    echo "=== 07o FAILED (exit $ec) ===" | tee -a "$LOG"
    exit "$ec"
fi
date | tee -a "$LOG"
echo "Log: $LOG"
