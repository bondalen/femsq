#!/bin/bash
# =============================================================================
# run_gate_21_4_6.sh — этап 21.4.6: parity + calendar gates (@refresh=1)
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQLCMD="${SQLCMD:-/opt/mssql-tools/bin/sqlcmd}"
DB_HOST="${SQL_HOST:-${DB_HOST:-10.7.0.3}}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
DB_NAME="${DB_NAME:-FishEye}"
LOG="${SCRIPT_DIR}/run_gate_21_4_6_$(date +%Y%m%d_%H%M%S).log"

run_sql() {
    local label="$1"
    local file="$2"
    local timeout_sec="${3:-900}"
    echo "" | tee -a "$LOG"
    echo "========== $label ==========" | tee -a "$LOG"
    if timeout "$timeout_sec" "$SQLCMD" \
        -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
        -i "$file" 2>&1 | tee -a "$LOG"; then
        echo ">> $label: done" | tee -a "$LOG"
        return 0
    else
        echo ">> $label: FAILED (exit $?)" | tee -a "$LOG"
        return 1
    fi
}

echo "run_gate_21_4_6 @ $DB_HOST -> $LOG" | tee "$LOG"
FAIL=0
run_sql "07s calendar" "$SCRIPT_DIR/07s_calendar_chain5.sql" 900 || FAIL=1
run_sql "07s parity" "$SCRIPT_DIR/07s_rs1_parity_chain5.sql" 900 || FAIL=1

if [[ $FAIL -eq 0 ]] \
   && grep -q '07s: PASS (calendar)' "$LOG" \
   && grep -qE '07s: PASS \(parity\)' "$LOG"; then
    echo "=== run_gate_21_4_6: PASS ===" | tee -a "$LOG"
else
    echo "=== run_gate_21_4_6: FAIL ===" | tee -a "$LOG"
    exit 1
fi
