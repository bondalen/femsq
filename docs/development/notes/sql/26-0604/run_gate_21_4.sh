#!/bin/bash
# =============================================================================
# run_gate_21_4.sh — этап 21.4.7: orchestrator gates 21.4.0–21.4.6 (strict A)
#
# Порядок:
#   21.4.1  07_VERIFY_after   — объекты _2606, fn2/PercentBrn COUNT
#   21.4.0  07u               — div-by-zero smoke (_2605/_2606)
#   21.4.4  run_gate_21_4_4   — 07o plan-align + 07t
#   21.4.5  run_gate_21_4_5   — 07n 849/1862 + 07t agency-spot
#   21.4.6  run_gate_21_4_6   — 07s parity + calendar (@refresh=1)
#
# PASS всех подпунктов — условие перехода к 21.5 / 19.7.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQLCMD="${SQLCMD:-/opt/mssql-tools/bin/sqlcmd}"
DB_HOST="${SQL_HOST:-${DB_HOST:-10.7.0.3}}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
DB_NAME="${DB_NAME:-FishEye}"
LOG="${SCRIPT_DIR}/run_gate_21_4_$(date +%Y%m%d_%H%M%S).log"

run_sql() {
    local label="$1"
    local file="$2"
    local timeout_sec="${3:-900}"
    local pass_pat="${4:-}"
    echo "" | tee -a "$LOG"
    echo "========== $label ==========" | tee -a "$LOG"
    if timeout "$timeout_sec" "$SQLCMD" \
        -S "$DB_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d "$DB_NAME" -C \
        -i "$file" 2>&1 | tee -a "$LOG"; then
        if [[ -n "$pass_pat" ]] && ! grep -q "$pass_pat" "$LOG"; then
            echo ">> $label: FAIL (marker '$pass_pat' not found)" | tee -a "$LOG"
            return 1
        fi
        echo ">> $label: done" | tee -a "$LOG"
        return 0
    else
        echo ">> $label: FAILED (exit $?)" | tee -a "$LOG"
        return 1
    fi
}

run_subgate() {
    local label="$1"
    local script="$2"
    echo "" | tee -a "$LOG"
    echo "########## $label ##########" | tee -a "$LOG"
    if "$script" 2>&1 | tee -a "$LOG"; then
        echo ">> $label: subgate OK" | tee -a "$LOG"
        return 0
    else
        echo ">> $label: subgate FAILED" | tee -a "$LOG"
        return 1
    fi
}

echo "run_gate_21_4 (21.4.7) @ $DB_HOST -> $LOG" | tee "$LOG"
date | tee -a "$LOG"

FAIL=0

run_sql "21.4.1 07_VERIFY_after" "$SCRIPT_DIR/07_VERIFY_after.sql" 600 || FAIL=1
if grep -q 'MISSING!' "$LOG"; then
    echo ">> 21.4.1: FAIL (MISSING objects)" | tee -a "$LOG"
    FAIL=1
fi

run_sql "21.4.0 07u div-by-zero" "$SCRIPT_DIR/07u_div_by_zero_smoke.sql" 1800 \
    '07u div-by-zero smoke: PASS' || FAIL=1

run_subgate "21.4.4 plan-align" "$SCRIPT_DIR/run_gate_21_4_4.sh" || FAIL=1
run_subgate "21.4.5 agency-spot" "$SCRIPT_DIR/run_gate_21_4_5.sh" || FAIL=1
run_subgate "21.4.6 parity/calendar" "$SCRIPT_DIR/run_gate_21_4_6.sh" || FAIL=1

echo "" | tee -a "$LOG"
date | tee -a "$LOG"

if [[ $FAIL -eq 0 ]]; then
    echo "=== run_gate_21_4: PASS — этап 21.4 закрыт ===" | tee -a "$LOG"
    exit 0
else
    echo "=== run_gate_21_4: FAIL ===" | tee -a "$LOG"
    exit 1
fi
