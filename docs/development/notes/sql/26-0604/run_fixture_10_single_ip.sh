#!/bin/bash
# =============================================================================
# run_fixture_10_single_ip.sh — FIXTURE_10 + gate 07o single-IP yearend
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_DIR="${SCRIPT_DIR}/fixture/dev-single-ip-chains"
SQLCMD="${SQLCMD:-/opt/mssql-tools/bin/sqlcmd}"
DB_HOST="${SQL_HOST:-${DB_HOST:-10.7.0.3}}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
DB_NAME="${DB_NAME:-FishEye}"
LOG="${SCRIPT_DIR}/run_fixture_10_single_ip_$(date +%Y%m%d_%H%M%S).log"

run_sql() {
    local label="$1"
    local file="$2"
    echo "" | tee -a "$LOG"
    echo "========== $label ==========" | tee -a "$LOG"
    if timeout 900 "$SQLCMD" \
        -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
        -i "$file" 2>&1 | tee -a "$LOG"; then
        echo ">> $label: done" | tee -a "$LOG"
        return 0
    else
        echo ">> $label: FAILED" | tee -a "$LOG"
        return 1
    fi
}

echo "run_fixture_10_single_ip @ $DB_HOST -> $LOG" | tee "$LOG"
FAIL=0
run_sql "FIXTURE_10_00" "${FIXTURE_DIR}/FIXTURE_10_00_single_ip_chains.sql" || FAIL=1
if [[ $FAIL -eq 0 ]]; then
    run_sql "07o single-IP yearend" "${SCRIPT_DIR}/07o_single_ip_yearend_2606.sql" || FAIL=1
fi

if [[ $FAIL -eq 0 ]] && grep -q '07o single-IP yearend: PASS' "$LOG"; then
    echo "=== run_fixture_10_single_ip: PASS ===" | tee -a "$LOG"
else
    echo "=== run_fixture_10_single_ip: FAIL ===" | tee -a "$LOG"
    exit 1
fi
