#!/bin/bash
# =============================================================================
# run_plan_stcost_chain5.sh
# Фаза 3: К-12 + К-13 (помесячные планы по stCost) на dev после fixture.
# Использование: ./run_plan_stcost_chain5.sh [YYYY-MM-DD]
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER="${CONTAINER:-femsq-mssql}"
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
DB_USER="sa"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
MOUNTH_END_DATE="${1:-2022-12-31}"
LOG="${SCRIPT_DIR}/plan_stcost_chain5_${MOUNTH_END_DATE//-}_$(date +%Y%m%d_%H%M%S).log"

run_07m() {
    local label="$1"
    local file="$2"
    local timeout_sec="${3:-480}"
    echo "" | tee -a "$LOG"
    echo "========== $label (timeout ${timeout_sec}s) ==========" | tee -a "$LOG"
    sed -e "s/@stIpg           int   = NULL/@stIpg           int   = NULL/" \
        -e "s/@MounthEndDate   date  = '2022-12-31'/@MounthEndDate   date  = '$MOUNTH_END_DATE'/" \
        "$file" | \
    timeout "$timeout_sec" docker exec -i "$CONTAINER" "$SQLCMD" \
        -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
        -i /dev/stdin 2>&1 | tee -a "$LOG"
    local ec=${PIPESTATUS[0]}
    if [[ $ec -ne 0 ]]; then
        echo "  >> $label: FAILED (exit $ec)" | tee -a "$LOG"
        exit "$ec"
    fi
    echo "  >> $label: completed" | tee -a "$LOG"
}

echo "=== Plan stCost acceptance chain 5 | @dt=$MOUNTH_END_DATE | log: $LOG ===" | tee "$LOG"
date | tee -a "$LOG"

# fixture check
echo "" | tee -a "$LOG"
echo "========== fixture check ==========" | tee -a "$LOG"
docker exec -i "$CONTAINER" "$SQLCMD" \
    -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
    -Q "SET NOCOUNT ON; SELECT COUNT(*) AS utpl_stcost_split FROM ags.ipgUtPlPnLmMn m
        JOIN ags.ipgUtPlP up ON up.iuplpKey=m.iuplpmPlPn
        JOIN ags.ipgPn p ON p.ipgpKey=up.iuplpIpgPn
        JOIN ags.ipgChRlV v ON v.ipgcrvIpg=p.ipgpIpg AND v.ipgcrvChain=5
        WHERE m.iuplpmStCost IN (195,172,187);" 2>&1 | tee -a "$LOG"

run_07m "07m К-12 plan=limit" "$SCRIPT_DIR/07m_plan_limit_conformance_chain5.sql" 480
run_07m "07m К-13 plan additive" "$SCRIPT_DIR/07m_plan_additive_chain5.sql" 480

echo "" | tee -a "$LOG"
echo "=== Plan stCost acceptance finished ===" | tee -a "$LOG"
date | tee -a "$LOG"
echo "Log: $LOG"
