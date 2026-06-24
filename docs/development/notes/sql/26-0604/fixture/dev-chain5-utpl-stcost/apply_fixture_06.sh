#!/bin/bash
# =============================================================================
# apply_fixture_06.sh — FIXTURE_06: изолированные группы UtPl + golden cst 2102
# Только dev. Не запускать на prod.
#
# На Fedora (remote Docker на nb-win): SQL_HOST=10.7.0.3 ./apply_fixture_06.sh
# На nb-win (локальный Docker): ./apply_fixture_06.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER="${CONTAINER:-femsq-mssql}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"
SQL_HOST="${SQL_HOST:-}"

run_sql() {
    local label="$1"
    local file="$2"
    echo ""
    echo "========== $label =========="
    echo "  file: $(basename "$file")"
    if [[ -n "$SQL_HOST" ]]; then
        if sqlcmd -S "$SQL_HOST" -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
            -i "$file"; then
            echo "  >> $label: OK"
        else
            echo "  >> $label: FAILED"
            exit 1
        fi
    else
        if docker exec -i "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
            -i /dev/stdin < "$file"; then
            echo "  >> $label: OK"
        else
            echo "  >> $label: FAILED"
            exit 1
        fi
    fi
}

echo "=== apply_fixture_06 (dev-only) ==="
date
[[ -n "$SQL_HOST" ]] && echo "  SQL_HOST=$SQL_HOST" || echo "  mode=docker ($CONTAINER)"

run_sql "FIXTURE_06_00" "$SCRIPT_DIR/FIXTURE_06_00_setup_journal.sql"
run_sql "FIXTURE_06_01" "$SCRIPT_DIR/FIXTURE_06_01_swap_utplgr.sql"
run_sql "FIXTURE_06_golden" "$SCRIPT_DIR/FIXTURE_06_golden_cst_2102.sql"
run_sql "FIXTURE_06_verify" "$SCRIPT_DIR/FIXTURE_06_verify_golden.sql"

echo ""
echo "=== FIXTURE_06 apply finished ==="
date
