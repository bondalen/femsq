#!/bin/bash
# =============================================================================
# apply_fixture_chain5.sh — применить dev-fixture UtPlMn split (цепь 5)
# Только Docker dev. Не запускать на prod.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER="${CONTAINER:-femsq-mssql}"
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
DB_USER="sa"
DB_PASSWORD="${DB_PASSWORD:-kolob_OK1}"

run_sql() {
    local label="$1"
    local file="$2"
    echo ""
    echo "========== $label =========="
    echo "  file: $file"
    if docker exec -i "$CONTAINER" "$SQLCMD" \
        -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -d FishEye -C \
        -i /dev/stdin < "$file"; then
        echo "  >> $label: OK"
    else
        echo "  >> $label: FAILED"
        exit 1
    fi
}

echo "=== apply_fixture_chain5 (dev-only) ==="
date

run_sql "FIXTURE_00" "$SCRIPT_DIR/FIXTURE_00_setup_journal.sql"
run_sql "FIXTURE_01" "$SCRIPT_DIR/FIXTURE_01_normalize_utplmn.sql"
run_sql "FIXTURE_03" "$SCRIPT_DIR/FIXTURE_03_split_stcost.sql"
run_sql "FIXTURE_04" "$SCRIPT_DIR/FIXTURE_04_verify_data.sql"

echo ""
echo "=== fixture apply finished ==="
date
