#!/bin/bash
# =============================================================================
# run_agency_golden_21_3.sh — этап 21.3: agency-golden 849/1862 @ stIpg=4
#   07n strict plan (849, 1862) + 07t agency-spot gate
# SQL_HOST=10.7.0.3 на Fedora.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQLCMD="${SQLCMD:-/opt/mssql-tools/bin/sqlcmd}"
DB_HOST="${SQL_HOST:-${DB_HOST:-10.7.0.3}}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
DB_NAME="${DB_NAME:-FishEye}"
LOG="${SCRIPT_DIR}/agency_golden_21_3_$(date +%Y%m%d_%H%M%S).log"

run_sql() {
    local label="$1"
    local file="$2"
    local timeout_sec="${3:-480}"
    echo "" | tee -a "$LOG"
    echo "========== $label ==========" | tee -a "$LOG"
    if timeout "$timeout_sec" "$SQLCMD" \
        -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
        -i "$file" 2>&1 | tee -a "$LOG"; then
        echo ">> $label: completed" | tee -a "$LOG"
    else
        echo ">> $label: FAILED (exit $?)" | tee -a "$LOG"
        return 1
    fi
}

run_cst_07n() {
    local cst="$1"
    local label="07n strict cst=$cst"
    echo "" | tee -a "$LOG"
    echo "========== $label ==========" | tee -a "$LOG"
    sed "s/@cstAgPn         int   = 2102/@cstAgPn         int   = $cst/" \
        "$SCRIPT_DIR/07n_plan_strict_cst_chain5.sql" \
        | timeout 480 "$SQLCMD" \
            -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
            2>&1 | tee -a "$LOG"
}

echo "agency_golden_21_3 @ $DB_HOST -> $LOG" | tee "$LOG"
date | tee -a "$LOG"

FAIL=0
run_cst_07n 849 || FAIL=1
run_cst_07n 1862 || FAIL=1
run_sql "07t agency-spot stIpg=4" "$SCRIPT_DIR/07t_agency_spot_stipg4.sql" 120 || FAIL=1

echo "" | tee -a "$LOG"
if [[ $FAIL -eq 0 ]]; then
    echo "=== agency_golden_21_3: PASS ===" | tee -a "$LOG"
else
    echo "=== agency_golden_21_3: FAIL ===" | tee -a "$LOG"
    exit 1
fi
date | tee -a "$LOG"
echo "Log: $LOG"
