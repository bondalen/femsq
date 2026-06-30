#!/bin/bash
# apply_naming_21_1.sh — этап 21.1: миграция имён + переприменение зависимых объектов
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQLCMD="${SQLCMD:-/opt/mssql-tools/bin/sqlcmd}"
DB_HOST="${DB_HOST:-10.7.0.3}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
DB_NAME="${DB_NAME:-FishEye}"
LOG="${SCRIPT_DIR}/apply_naming_21_1_$(date +%Y%m%d_%H%M%S).log"

run_sql() {
    local label="$1"
    local file="$2"
    local timeout_sec="${3:-300}"
    echo "" | tee -a "$LOG"
    echo "========== $label ==========" | tee -a "$LOG"
    echo "  file: $file" | tee -a "$LOG"
    if timeout "$timeout_sec" "$SQLCMD" \
        -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
        -i "$file" 2>&1 | tee -a "$LOG"; then
        echo "  >> $label: OK" | tee -a "$LOG"
    else
        echo "  >> $label: FAILED" | tee -a "$LOG"
        return 1
    fi
}

echo "apply_naming_21_1 @ $DB_HOST -> $LOG" | tee "$LOG"

run_sql "01b migrate" "$SCRIPT_DIR/01b_MIGRATE_naming_21_1.sql" 120 || exit 1

run_sql "01 fnIpgChRlEnd" "$SCRIPT_DIR/01b_RECREATE_fnIpgChRlEnd_2606.sql" 120 || exit 1

for f in \
    02_CREATE_FUNCTION_fnIpgChDats_2606.sql \
    03a_CREATE_FUNCTION_fnStCostRsIpgPn_2606.sql \
    03b_CREATE_FUNCTION_fnStCostRsCstAgPn_2606.sql \
    03c_CREATE_FUNCTION_fnMasteringCstAgPnSh_2606.sql \
    03d_CREATE_FUNCTION_fnMasteringStIpgStCost_2606.sql \
    10d_CREATE_FUNCTION_fnIpgChContractsForStIpg_2606.sql \
    04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql \
    04b_CREATE_PROCEDURE_spIpgChRsltCstUtl2_2606.sql \
    05a_PATCH_PercentBrn_fnIpgChDats_2606.sql
do
    run_sql "$f" "$SCRIPT_DIR/$f" 600 || exit 1
done

run_sql "07_VERIFY_after" "$SCRIPT_DIR/07_VERIFY_after.sql" 300 || exit 1

echo "=== apply_naming_21_1: completed ===" | tee -a "$LOG"
