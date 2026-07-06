#!/bin/bash
# =============================================================================
# run_gate_21_4_4.sh — этап 21.4.4: plan-align gates 07o + 07t
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQLCMD="${SQLCMD:-/opt/mssql-tools/bin/sqlcmd}"
DB_HOST="${SQL_HOST:-${DB_HOST:-10.7.0.3}}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
DB_NAME="${DB_NAME:-FishEye}"
LOG="${SCRIPT_DIR}/run_gate_21_4_4_$(date +%Y%m%d_%H%M%S).log"

run_sql() {
    local label="$1"
    local file="$2"
    echo "" | tee -a "$LOG"
    echo "========== $label ==========" | tee -a "$LOG"
    if timeout 900 "$SQLCMD" \
        -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
        -i "$file" 2>&1 | tee -a "$LOG"; then
        if grep -qE ': PASS ===' "$LOG" | tail -1; then
            true
        fi
        echo ">> $label: done" | tee -a "$LOG"
        return 0
    else
        echo ">> $label: FAILED" | tee -a "$LOG"
        return 1
    fi
}

echo "run_gate_21_4_4 @ $DB_HOST -> $LOG" | tee "$LOG"
FAIL=0
run_sql "07o plan-align invest" "$SCRIPT_DIR/07o_plan_align_spot_2102.sql" || FAIL=1
run_sql "07t agency-spot+plan" "$SCRIPT_DIR/07t_agency_spot_stipg4.sql" || FAIL=1

if [[ $FAIL -eq 0 ]] && grep -q '07o plan-align spot: PASS' "$LOG" && grep -q '07t agency-spot: PASS' "$LOG"; then
    echo "=== run_gate_21_4_4: PASS ===" | tee -a "$LOG"
else
    echo "=== run_gate_21_4_4: FAIL ===" | tee -a "$LOG"
    exit 1
fi
