#!/bin/bash
# apply_div_by_zero_fix.sh — hotfix div-by-zero на dev: SaveToTables → 2605 → 05b → 2606 → smoke
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
SQLCMD="${SQLCMD:-/opt/mssql-tools/bin/sqlcmd}"
DB_HOST="${SQL_HOST:-${DB_HOST:-10.7.0.3}}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
DB_NAME="${DB_NAME:-FishEye}"
LOG="${SCRIPT_DIR}/apply_div_by_zero_$(date +%Y%m%d_%H%M%S).log"

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
    else
        echo ">> $label: FAILED" | tee -a "$LOG"
        return 1
    fi
}

echo "apply_div_by_zero_fix @ $DB_HOST -> $LOG" | tee "$LOG"
date | tee -a "$LOG"

FAIL=0
run_sql "spMstrg_2408_SaveToTables" "$ROOT/code/scripts/spMstrg_2408_SaveToTables.sql" 120 || FAIL=1
run_sql "spMstrg_2605 rebuild" "$ROOT/docs/development/notes/sql/26-0508/03_CREATE_PROCEDURE_spMstrg_2605.sql" 120 || FAIL=1
run_sql "PercentBrn 05b" "$SCRIPT_DIR/05b_PATCH_PercentBrn_ipgChRl_2606.sql" 600 || FAIL=1
run_sql "spMstrg_2606 rebuild" "$SCRIPT_DIR/06_CREATE_PROCEDURE_spMstrg_2606.sql" 120 || FAIL=1
run_sql "07_VERIFY_after" "$SCRIPT_DIR/07_VERIFY_after.sql" 900 || FAIL=1
run_sql "07u div-by-zero smoke" "$SCRIPT_DIR/07u_div_by_zero_smoke.sql" 1800 || FAIL=1

echo "" | tee -a "$LOG"
if [[ $FAIL -eq 0 ]]; then
    echo "=== apply_div_by_zero_fix: PASS ===" | tee -a "$LOG"
else
    echo "=== apply_div_by_zero_fix: FAIL ===" | tee -a "$LOG"
    exit 1
fi
date | tee -a "$LOG"
echo "Log: $LOG"
