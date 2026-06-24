#!/bin/bash
# =============================================================================
# run_07n_o_pilots_chain5.sh — 07n + 07o для пилотных строек (18.7.2c)
# Список: 2102 (golden) + 8 пилотов из FIXTURE_06_pilots_cst_chain5.sql
# SQL_HOST=10.7.0.3 на Fedora.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_DIR="$SCRIPT_DIR/fixture/dev-chain5-utpl-stcost"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
SQL_HOST="${SQL_HOST:-}"
CONTAINER="${CONTAINER:-femsq-mssql}"
TIMEOUT_07N="${TIMEOUT_07N:-120}"
TIMEOUT_07O="${TIMEOUT_07O:-900}"
LOG="${SCRIPT_DIR}/pilots_07n_o_$(date +%Y%m%d_%H%M%S).log"

PILOTS=(2102 121 631 1251 1608 1713 2080 2146 2212)

run_sql_file() {
    local file="$1"
    local timeout_sec="$2"
    if [[ -n "$SQL_HOST" ]]; then
        timeout "$timeout_sec" sqlcmd -S "$SQL_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C -i "$file"
    else
        timeout "$timeout_sec" docker exec -i "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C -i /dev/stdin < "$file"
    fi
}

run_07n_cst() {
    local cst="$1"
    local tmp out
    tmp="$(mktemp)"
    out="$(mktemp)"
    sed "s/DECLARE @cstAgPn         int   = 2102;/DECLARE @cstAgPn         int   = ${cst};/" \
        "$SCRIPT_DIR/07n_plan_strict_cst_chain5.sql" > "$tmp"
    run_sql_file "$tmp" "$TIMEOUT_07N" >"$out" 2>&1
    local ec=$?
    cat "$out"
    local ok=0
    grep -q '07n.*| PASS' "$out" && ok=1
    rm -f "$tmp" "$out"
    [[ $ec -eq 0 && $ok -eq 1 ]]
}

run_07o_cst() {
    local cst="$1"
    local tmp out
    tmp="$(mktemp)"
    out="$(mktemp)"
    sed "s/DECLARE @cstAgPn         int   = 2102;/DECLARE @cstAgPn         int   = ${cst};/" \
        "$SCRIPT_DIR/07o_plan_17dates_cst_chain5.sql" > "$tmp"
    run_sql_file "$tmp" "$TIMEOUT_07O" >"$out" 2>&1
    local ec=$?
    cat "$out"
    local ok=0
    grep -q '07o.*| PASS' "$out" && ok=1
    rm -f "$tmp" "$out"
    [[ $ec -eq 0 && $ok -eq 1 ]]
}

echo "=== pilots 07n+07o chain 5 | n=${#PILOTS[@]} | log: $LOG ===" | tee "$LOG"
date | tee -a "$LOG"

fixture_out="$(mktemp)"
{
    echo ""
    echo "========== FIXTURE_06_pilots =========="
    run_sql_file "$FIXTURE_DIR/FIXTURE_06_pilots_cst_chain5.sql" 120
} >"$fixture_out" 2>&1
fixture_ec=$?
cat "$fixture_out" | tee -a "$LOG"
if [[ $fixture_ec -ne 0 ]] || grep -qE '^Msg [0-9]+,' "$fixture_out"; then
    echo "FIXTURE_06_pilots FAILED" | tee -a "$LOG"
    rm -f "$fixture_out"
    exit 1
fi
rm -f "$fixture_out"

fail=0
pass=0
for cst in "${PILOTS[@]}"; do
    {
        echo ""
        echo "========== cstAgPn=$cst | 07n =========="
    } | tee -a "$LOG"
    if run_07n_cst "$cst" | tee -a "$LOG"; then
        :
    else
        echo "  >> 07n cst=$cst: FAILED" | tee -a "$LOG"
        ((fail++)) || true
        continue
    fi

    {
        echo ""
        echo "========== cstAgPn=$cst | 07o =========="
    } | tee -a "$LOG"
    if run_07o_cst "$cst" | tee -a "$LOG"; then
        echo "  >> cst=$cst: PASS" | tee -a "$LOG"
        ((pass++)) || true
    else
        echo "  >> 07o cst=$cst: FAILED" | tee -a "$LOG"
        ((fail++)) || true
    fi
done

echo "" | tee -a "$LOG"
echo "=== summary: pass=$pass fail=$fail / ${#PILOTS[@]} ===" | tee -a "$LOG"
date | tee -a "$LOG"
echo "Log: $LOG"

[[ $fail -eq 0 ]]
