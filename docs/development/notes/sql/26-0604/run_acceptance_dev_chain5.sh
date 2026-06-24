#!/bin/bash
# =============================================================================
# run_acceptance_dev_chain5.sh
# Dev-приёмка: сходимость _2606↔_2605 + замеры К-6/К-7/К-8/К-9
# @ipgCh=5, @MounthEndDate — см. MOUNTH_END_DATE (по умолчанию 2022-12-31)
# Использование:
#   ./run_acceptance_dev_chain5.sh [YYYY-MM-DD]
#   ./run_acceptance_dev_chain5.sh [YYYY-MM-DD] --with-plan-stcost
#   ./run_acceptance_dev_chain5.sh --with-plan-stcost
# Автор: Александр | Дата: 2026-06-15
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER="${CONTAINER:-femsq-mssql}"
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
DB_USER="sa"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
WITH_PLAN_STCOST=false
MOUNTH_END_DATE="2022-12-31"

for arg in "$@"; do
    case "$arg" in
        --with-plan-stcost) WITH_PLAN_STCOST=true ;;
        *)
            if [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                MOUNTH_END_DATE="$arg"
            fi
            ;;
    esac
done
LOG="${SCRIPT_DIR}/acceptance_dev_chain5_${MOUNTH_END_DATE//-}_$(date +%Y%m%d_%H%M%S).log"

run_sql() {
    local label="$1"
    local file="$2"
    local timeout_sec="${3:-600}"
    echo "" | tee -a "$LOG"
    echo "========== $label (timeout ${timeout_sec}s) ==========" | tee -a "$LOG"
    echo "  file: $file" | tee -a "$LOG"
    if timeout "$timeout_sec" docker exec -i "$CONTAINER" "$SQLCMD" \
        -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
        -i /dev/stdin < "$file" 2>&1 | tee -a "$LOG"; then
        echo "  >> $label: completed" | tee -a "$LOG"
    else
        local ec=$?
        echo "  >> $label: FAILED (exit $ec)" | tee -a "$LOG"
        return "$ec"
    fi
}

run_sql_var() {
    local label="$1"
    local stIpg="$2"
    local timeout_sec="${3:-600}"
    echo "" | tee -a "$LOG"
    echo "========== $label stIpg=$stIpg ==========" | tee -a "$LOG"
    sed "s/@stIpg int = 61/@stIpg int = $stIpg/" "$SCRIPT_DIR/07h_compare_fn2_to_2605.sql" | \
    timeout "$timeout_sec" docker exec -i "$CONTAINER" "$SQLCMD" \
        -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
        -i /dev/stdin 2>&1 | tee -a "$LOG"
}

run_sql_07m() {
    local label="$1"
    local file="$2"
    local timeout_sec="${3:-480}"
    echo "" | tee -a "$LOG"
    echo "========== $label (timeout ${timeout_sec}s) ==========" | tee -a "$LOG"
    sed -e "s/@MounthEndDate   date  = '2022-12-31'/@MounthEndDate   date  = '$MOUNTH_END_DATE'/" \
        -e "s/@stIpg           int   = NULL/@stIpg           int   = NULL/" \
        "$file" | \
    timeout "$timeout_sec" docker exec -i "$CONTAINER" "$SQLCMD" \
        -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
        -i /dev/stdin 2>&1 | tee -a "$LOG"
}

run_sql_inline() {
    local label="$1"
    local stIpg="$2"
    local timeout_sec="${3:-600}"
    echo "" | tee -a "$LOG"
    echo "========== $label stIpg=$stIpg ==========" | tee -a "$LOG"
    sed "s/@stIpg   int   = 61/@stIpg   int   = $stIpg/" "$SCRIPT_DIR/07i_COMPARE_stCost_additive_chain5.sql" | \
    timeout "$timeout_sec" docker exec -i "$CONTAINER" "$SQLCMD" \
        -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
        -i /dev/stdin 2>&1 | tee -a "$LOG"
    sed "s/@stIpg   int   = 61/@stIpg   int   = $stIpg/" "$SCRIPT_DIR/07j_COMPARE_stCost_fact_additive_chain5.sql" | \
    timeout "$timeout_sec" docker exec -i "$CONTAINER" "$SQLCMD" \
        -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
        -i /dev/stdin 2>&1 | tee -a "$LOG"
}

echo "=== Acceptance dev chain 5 | @MounthEndDate=$MOUNTH_END_DATE | log: $LOG ===" | tee "$LOG"
date | tee -a "$LOG"

# --- Фаза 1: fn2 + PercentBrn + perf ---
run_sql "07h6 K-7 profile" "$SCRIPT_DIR/07h6_fn2_profile_stIpgNULL.sql" 600
run_sql_var "07h fn2 vs _2605" 61 300
run_sql_var "07h fn2 vs _2605" 46 600
run_sql "07f PercentBrn" "$SCRIPT_DIR/07f_COMPARE_PercentBrn_full_chain5.sql" 900

# --- Fill ResultSets @ MOUNTH_END_DATE ---
echo "" | tee -a "$LOG"
echo "========== spMstrg_2605 fill RS @ $MOUNTH_END_DATE ==========" | tee -a "$LOG"
timeout 1200 docker exec -i "$CONTAINER" "$SQLCMD" \
    -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
    -Q "SET NOCOUNT ON; DECLARE @t0 datetime2=SYSDATETIME();
        EXEC ags.spMstrg_2605 @ipgCh=5, @MounthEndDate='$MOUNTH_END_DATE', @ipgSt=NULL, @saveToTables=1;
        SELECT DATEDIFF(ms,@t0,SYSDATETIME()) AS ms_spMstrg_2605;" 2>&1 | tee -a "$LOG"

echo "" | tee -a "$LOG"
echo "========== spMstrg_2606 fill RS @ $MOUNTH_END_DATE ==========" | tee -a "$LOG"
timeout 1200 docker exec -i "$CONTAINER" "$SQLCMD" \
    -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
    -Q "SET NOCOUNT ON; DECLARE @t0 datetime2=SYSDATETIME();
        EXEC ags.spMstrg_2606 @ipgCh=5, @MounthEndDate='$MOUNTH_END_DATE', @ipgStKey=NULL, @stCostKey=NULL, @saveToTables=1;
        SELECT DATEDIFF(ms,@t0,SYSDATETIME()) AS ms_spMstrg_2606;" 2>&1 | tee -a "$LOG"

run_sql "07k full RS compare" "$SCRIPT_DIR/07k_RS_full_compare_chain5.sql" 1800
run_sql "07l RS4-7 spot" "$SCRIPT_DIR/07l_RS_derivative_spot_chain5.sql" 1800

# --- 07_VERIFY spMstrg (saveToTables=0 smoke) ---
echo "" | tee -a "$LOG"
echo "========== 07_VERIFY spMstrg saveToTables=0 @ $MOUNTH_END_DATE ==========" | tee -a "$LOG"
sed "s/2022-12-31/$MOUNTH_END_DATE/g" "$SCRIPT_DIR/07_VERIFY_spMstrg_2606_chain5.sql" | \
timeout 1200 docker exec -i "$CONTAINER" "$SQLCMD" \
    -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
    -i /dev/stdin 2>&1 | tee -a "$LOG"

# --- Фаза 2: stCost additive (mastering) ---
run_sql_inline "07i+07j stCost" 61 300
run_sql_inline "07i+07j stCost" 46 600

# --- Фаза 3: планы UtPl по stCost (dev, после fixture) ---
if [[ "$WITH_PLAN_STCOST" == true ]]; then
    run_sql_07m "07m К-12 plan=limit" "$SCRIPT_DIR/07m_plan_limit_conformance_chain5.sql" 480
    run_sql_07m "07m К-13 plan additive" "$SCRIPT_DIR/07m_plan_additive_chain5.sql" 480
    echo "" | tee -a "$LOG"
    echo "========== 07i stCost NULL (control) ==========" | tee -a "$LOG"
    sed -e "s/@stIpg   int   = 61/@stIpg   int   = NULL/" \
        "$SCRIPT_DIR/07i_COMPARE_stCost_additive_chain5.sql" | \
    timeout 480 docker exec -i "$CONTAINER" "$SQLCMD" \
        -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
        -i /dev/stdin 2>&1 | tee -a "$LOG"
fi

echo "" | tee -a "$LOG"
echo "=== Acceptance run finished ===" | tee -a "$LOG"
date | tee -a "$LOG"
echo "Log: $LOG"
