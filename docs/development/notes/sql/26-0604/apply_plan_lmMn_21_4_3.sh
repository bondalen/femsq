#!/bin/bash
# =============================================================================
# apply_plan_lmMn_21_4_3.sh — этап 21.4.3: 05c LmMn plan + verify + refill RS1
# SQL_HOST=10.7.0.3 на Fedora.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQLCMD="${SQLCMD:-/opt/mssql-tools/bin/sqlcmd}"
DB_HOST="${SQL_HOST:-${DB_HOST:-10.7.0.3}}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
DB_NAME="${DB_NAME:-FishEye}"
LOG="${SCRIPT_DIR}/apply_plan_lmMn_21_4_3_$(date +%Y%m%d_%H%M%S).log"

run_sql() {
    local label="$1"
    local file="$2"
    local timeout_sec="${3:-600}"
    echo "" | tee -a "$LOG"
    echo "========== $label ==========" | tee -a "$LOG"
    if timeout "$timeout_sec" "$SQLCMD" \
        -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
        -i "$file" 2>&1 | tee -a "$LOG"; then
        echo ">> $label: OK" | tee -a "$LOG"
        return 0
    else
        echo ">> $label: FAILED" | tee -a "$LOG"
        return 1
    fi
}

echo "apply_plan_lmMn_21_4_3 @ $DB_HOST -> $LOG" | tee "$LOG"
date | tee -a "$LOG"

FAIL=0
run_sql "05c PercentBrn plan LmMn@212" "$SCRIPT_DIR/05c_PATCH_PercentBrn_plan_LmMn_2606.sql" 900 || FAIL=1

if [[ $FAIL -eq 0 ]]; then
    run_sql "07v plan-align diag" "$SCRIPT_DIR/07v_diag_plan_align_chain5.sql" 900 || FAIL=1
    run_sql "07o plan-align spot 2102" "$SCRIPT_DIR/07o_plan_align_spot_2102.sql" 600 || true
    run_sql "07t agency-spot" "$SCRIPT_DIR/07t_agency_spot_stipg4.sql" 600 || true
    run_sql "refill RS1 chain5" "$SCRIPT_DIR/07_refill_rs1_chain5.sql" 1800 || FAIL=1
    run_sql "07_VERIFY_after" "$SCRIPT_DIR/07_VERIFY_after.sql" 900 || FAIL=1
fi

echo "" | tee -a "$LOG"
if [[ $FAIL -eq 0 ]]; then
    echo "=== apply_plan_lmMn_21_4_3: PASS ===" | tee -a "$LOG"
else
    echo "=== apply_plan_lmMn_21_4_3: FAIL ===" | tee -a "$LOG"
    exit 1
fi
date | tee -a "$LOG"
echo "Log: $LOG"
