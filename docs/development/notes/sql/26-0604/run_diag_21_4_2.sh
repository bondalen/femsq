#!/bin/bash
# =============================================================================
# run_diag_21_4_2.sh — этап 21.4.2: preflight + plan-align chain diagnosis
# SQL_HOST=10.7.0.3 на Fedora.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQLCMD="${SQLCMD:-/opt/mssql-tools/bin/sqlcmd}"
DB_HOST="${SQL_HOST:-${DB_HOST:-10.7.0.3}}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
DB_NAME="${DB_NAME:-FishEye}"
LOG="${SCRIPT_DIR}/diag_21_4_2_$(date +%Y%m%d_%H%M%S).log"

run_sql() {
    local label="$1"
    local file="$2"
    local timeout_sec="${3:-600}"
    echo "" | tee -a "$LOG"
    echo "========== $label ==========" | tee -a "$LOG"
    if timeout "$timeout_sec" "$SQLCMD" \
        -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
        -i "$file" 2>&1 | tee -a "$LOG"; then
        echo ">> $label: completed" | tee -a "$LOG"
        return 0
    else
        echo ">> $label: FAILED (exit $?)" | tee -a "$LOG"
        return 1
    fi
}

run_07n_cst() {
    local cst="$1"
    local label="07n strict cst=$cst"
    echo "" | tee -a "$LOG"
    echo "========== $label ==========" | tee -a "$LOG"
    sed "s/@cstAgPn         int   = 2102/@cstAgPn         int   = $cst/" \
        "$SCRIPT_DIR/07n_plan_strict_cst_chain5.sql" \
        | timeout 480 "$SQLCMD" \
            -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
            2>&1 | tee -a "$LOG"
    grep -q '07n.*| PASS' "$LOG" && return 0 || return 1
}

echo "diag_21_4_2 @ $DB_HOST -> $LOG" | tee "$LOG"
date | tee -a "$LOG"

FAIL=0
run_sql "07_VERIFY_after (preflight)" "$SCRIPT_DIR/07_VERIFY_after.sql" 600 || FAIL=1
run_07n_cst 2102 || FAIL=1
run_07n_cst 849 || FAIL=1
run_sql "07o plan-align spot 2102" "$SCRIPT_DIR/07o_plan_align_spot_2102.sql" 300 || true
run_sql "07v plan-align chain diag" "$SCRIPT_DIR/07v_diag_plan_align_chain5.sql" 600 || FAIL=1

echo "" | tee -a "$LOG"
if grep -q 'BREAKPOINT:' "$LOG"; then
    grep 'BREAKPOINT:' "$LOG" | tail -1 | tee -a "$LOG"
fi
if [[ $FAIL -eq 0 ]]; then
    echo "=== diag_21_4_2: scripts completed (see BREAKPOINT in log) ===" | tee -a "$LOG"
else
    echo "=== diag_21_4_2: FAIL (preflight or 07v) ===" | tee -a "$LOG"
    exit 1
fi
date | tee -a "$LOG"
echo "Log: $LOG"
