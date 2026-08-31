#!/usr/bin/env bash
# Stage1 / E1′ gate: PIT SQL + Excel verify (база–QI–QII; QIII/QIV ignore).
# Usage:
#   ./verify-rslt-stage1.sh [--ref PATH] [--gen PATH] [--skip-sql] [--skip-export]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../../.." && pwd)"
PKG="$(cd "$(dirname "$0")" && pwd)"
ART="$PKG/artifacts"
mkdir -p "$ART"
STAMP=$(date +%y-%m%d-%H%M)
REF="${REF:-/tmp/rslt_ref.xlsx}"
GEN="${GEN:-}"
SKIP_SQL=0
SKIP_EXPORT=0
PYTHON="${PYTHON:-/tmp/rslt-venv/bin/python}"
API="${API:-http://localhost:8080}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref) REF="$2"; shift 2 ;;
    --gen) GEN="$2"; shift 2 ;;
    --skip-sql) SKIP_SQL=1; shift ;;
    --skip-export) SKIP_EXPORT=1; shift ;;
    --python) PYTHON="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ ! -f "$REF" ]]; then
  # try copy from share
  SHARE="/mnt/d/wire-guard-share-nb-win/femsq/excel/2025-12/debit/ags_Yr_DbtChangesRslt_26-0212_26-0217.xlsx"
  if [[ -f "$SHARE" ]]; then
    cp -f "$SHARE" "$REF"
  else
    echo "REF not found: $REF" >&2
    exit 2
  fi
fi

if [[ "$SKIP_SQL" -eq 0 ]]; then
  echo "=== SQL 99_VERIFY_pit_sums ==="
  node "$ROOT/code/scripts/femsq-sql.js" "$(sed '/^GO$/d' "$PKG/99_VERIFY_pit_sums.sql")"
  echo "=== SQL 99_VERIFY_rslt_stage1 (excerpt) ==="
  node "$ROOT/code/scripts/femsq-sql.js" "$(sed '/^GO$/d' "$PKG/99_VERIFY_rslt_stage1.sql")" | head -60
fi

if [[ -z "$GEN" ]]; then
  GEN="$ART/ags_Yr_DbtChangesRslt_900_asOf803_pit_base-QI-QII_${STAMP}.xlsx"
fi

if [[ "$SKIP_EXPORT" -eq 0 ]]; then
  echo "=== export Rslt yr=900 asOfUpl=803 ==="
  curl -s -o "$GEN" -w "HTTP %{http_code} size=%{size_download}\n" \
    "$API/api/v1/sudz/rslt-sborn.xlsx?yr=900&asOfUpl=803"
  cp -f "$GEN" /tmp/rslt_900_803.xlsx
fi

JSON="$ART/stage1_verify_${STAMP}.json"
echo "=== Python verify_rslt_stage1.py ==="
"$PYTHON" "$PKG/verify_rslt_stage1.py" --ref "$REF" --gen "$GEN" --sample 80 --json "$JSON"
echo "Report: $JSON"
echo "Gen: $GEN"
