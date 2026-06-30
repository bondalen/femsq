#!/bin/bash
# smoke_post_naming_21_1.sh — smoke после этапа 21.1: 07f4, 07k, 07s
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQLCMD="${SQLCMD:-/opt/mssql-tools/bin/sqlcmd}"
DB_HOST="${DB_HOST:-10.7.0.3}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
DB_NAME="${DB_NAME:-FishEye}"
DT="${MOUNTH_END_DATE:-2022-12-31}"
LOG="${SCRIPT_DIR}/smoke_post_naming_21_1_$(date +%Y%m%d_%H%M%S).log"

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
    else
        echo ">> $label: FAILED (exit $?)" | tee -a "$LOG"
        return 1
    fi
}

echo "smoke_post_naming_21_1 @ $DB_HOST dt=$DT -> $LOG" | tee "$LOG"

echo "" | tee -a "$LOG"
echo "========== spMstrg_2605 fill RS (full chain) ==========" | tee -a "$LOG"
timeout 1200 "$SQLCMD" -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
    -Q "SET NOCOUNT ON; DECLARE @t0 datetime2=SYSDATETIME();
        EXEC ags.spMstrg_2605 @ipgCh=5, @MounthEndDate='$DT', @ipgSt=NULL, @saveToTables=1;
        SELECT DATEDIFF(ms,@t0,SYSDATETIME()) AS ms_spMstrg_2605;" 2>&1 | tee -a "$LOG" || exit 1

echo "" | tee -a "$LOG"
echo "========== spMstrg_2606 fill RS (full chain) ==========" | tee -a "$LOG"
timeout 1200 "$SQLCMD" -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
    -Q "SET NOCOUNT ON; DECLARE @t0 datetime2=SYSDATETIME();
        EXEC ags.spMstrg_2606 @ipgCh=5, @MounthEndDate='$DT', @ipgStKey=NULL, @stCostKey=NULL, @saveToTables=1;
        SELECT DATEDIFF(ms,@t0,SYSDATETIME()) AS ms_spMstrg_2606;" 2>&1 | tee -a "$LOG" || exit 1

FAIL=0
run_sql "07f4 baseline COUNT" "$SCRIPT_DIR/07f4_baseline_count_chain5.sql" 900 || FAIL=1
run_sql "07k RS compare" "$SCRIPT_DIR/07k_RS_full_compare_chain5.sql" 300 || FAIL=1
run_sql "07s calendar gate" "$SCRIPT_DIR/07s_calendar_chain5.sql" 900 || FAIL=1

echo "" | tee -a "$LOG"
if [[ "$FAIL" -eq 0 ]]; then
    echo "=== smoke_post_naming_21_1: ALL PASS ===" | tee -a "$LOG"
else
    echo "=== smoke_post_naming_21_1: SOME FAILED (see log) ===" | tee -a "$LOG"
    exit 1
fi
