#!/usr/bin/env bash
# Stage2 QIV gate (S76-G): SQL A1/A2/A2.1 + export Rslt@901 + Excel verify.
# Usage:
#   ./verify-qiv-stage2-gate.sh [--ref PATH] [--gen PATH] [--skip-sql] [--skip-export]
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
UPL=901
YR=900

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
  SHARE="/mnt/d/wire-guard-share-nb-win/femsq/excel/2025-12/debit/ags_Yr_DbtChangesRslt_26-0212_26-0217.xlsx"
  if [[ -f "$SHARE" ]]; then
    cp -f "$SHARE" "$REF"
  else
    echo "REF not found: $REF" >&2
    exit 2
  fi
fi

SQL_OUT="$ART/stage2_sql_gates_${STAMP}.txt"
if [[ "$SKIP_SQL" -eq 0 ]]; then
  echo "=== SQL 99_VERIFY_qiv_stage2.sql ===" | tee "$SQL_OUT"
  node "$ROOT/code/scripts/femsq-sql.js" "$(sed '/^GO$/d' "$PKG/99_VERIFY_qiv_stage2.sql")" | tee -a "$SQL_OUT"

  echo "=== SQL counts @upl=${UPL} ===" | tee -a "$SQL_OUT"
  node "$ROOT/code/scripts/femsq-sql.js" "
SELECT COUNT(*) AS dv901 FROM sudz.DbtValue WHERE dvUpl=${UPL};
SELECT COUNT(*) AS tbl901 FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey=${UPL};
SELECT COUNT(*) AS queue901 FROM sudz.CnInvUplInvDbtDouble AS q INNER JOIN sudz.CnInvDbtUplTbl AS t ON t.cidutKey = q.ciudCidut WHERE t.cidutUnloadKey=${UPL};
" | tee -a "$SQL_OUT"
fi

if [[ -z "$GEN" ]]; then
  GEN="$ART/ags_Yr_DbtChangesRslt_${YR}_asOf${UPL}_clean_apply_${STAMP}.xlsx"
fi

if [[ "$SKIP_EXPORT" -eq 0 ]]; then
  echo "=== export Rslt yr=${YR} asOfUpl=${UPL} ==="
  curl -s -o "$GEN" -w "HTTP %{http_code} size=%{size_download}\n" \
    --max-time 300 \
    "$API/api/v1/sudz/rslt-sborn.xlsx?yr=${YR}&asOfUpl=${UPL}"
  cp -f "$GEN" "/tmp/rslt_${YR}_${UPL}.xlsx"
fi

JSON="$ART/stage2_qiv_verify_clean_apply_${STAMP}.json"
echo "=== Python verify_rslt_stage2_qiv.py ==="
"$PYTHON" "$PKG/verify_rslt_stage2_qiv.py" --ref "$REF" --gen "$GEN" --json "$JSON"
echo "Report: $JSON"
echo "Gen: $GEN"
echo "SQL gates: $SQL_OUT"
