#!/bin/bash
# Проверка ручных gate'ов воронки 0069 (без UI).
# Использование: ./verify-funnel-manual-gates.sh <uplKey> [graphql_url]
#
# Exit 0 — все проверенные gate'ы PASS; 1 — есть блокеры.
# Документация: docs/development/notes/sudz-dbt-upl-funnel-uat-runbook.md

set -euo pipefail

UPL_KEY="${1:-}"
GRAPHQL_URL="${2:-http://127.0.0.1:8080/graphql}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ -z "$UPL_KEY" ]] || ! [[ "$UPL_KEY" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 <uplKey> [graphql_url]"
  exit 2
fi

FAIL=0

echo -e "${YELLOW}=== FEMSQ: gate-проверка воронки upl=${UPL_KEY} ===${NC}"

# --- G2 из HTML-лога (последний прогон) ---
QUERY='{"query":"query($upl:Int!){ sudzDbtUplLauncher(uplKey:$upl){ file { cidufLoadingProgress }}}","variables":{"upl":'"$UPL_KEY"'}}'
PROGRESS=$(curl -sf -X POST "$GRAPHQL_URL" -H 'Content-Type: application/json' -d "$QUERY" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('sudzDbtUplLauncher',{}).get('file',{}).get('cidufLoadingProgress') or '')" 2>/dev/null || true)

if [[ -z "$PROGRESS" ]]; then
  echo -e "${RED}✗ Не удалось прочитать cidufLoadingProgress (backend / GraphQL)${NC}"
  FAIL=1
else
  if echo "$PROGRESS" | grep -q 'имеются договора.*не соответствует\|<font color="CadetBlue">имеются договора</font>'; then
    echo -e "${RED}✗ G2 CnExistCtptNotLoad: FAIL (в логе «имеются договора … не соответствует»)${NC}"
    FAIL=1
  elif echo "$PROGRESS" | grep -q 'CnExistCtptNotLoad'; then
    if echo "$PROGRESS" | grep -q 'отсутствуют договора.*не соответствует'; then
      echo -e "${GREEN}✓ G2 CnExistCtptNotLoad: PASS (лог)${NC}"
    else
      echo -e "${YELLOW}? G2: блок CnExistCtptNotLoad есть, текст не распознан — проверьте лог вручную${NC}"
      FAIL=1
    fi
  else
    echo -e "${YELLOW}? G2: шаг CnExistCtptNotLoad не найден в логе — выполните префикс 1–3${NC}"
    FAIL=1
  fi
fi

# --- G3/G4 через sqlcmd (опционально) ---
if command -v sqlcmd >/dev/null 2>&1 && [[ -n "${FEMSQ_DB_HOST:-}" ]]; then
  DB="${FEMSQ_DB_NAME:-FishEye}"
  HOST="${FEMSQ_DB_HOST}"
  PORT="${FEMSQ_DB_PORT:-1433}"
  USER="${FEMSQ_DB_USER:-sa}"
  PASS="${FEMSQ_DB_PASSWORD:-}"

  run_sql() {
    sqlcmd -S "$HOST,$PORT" -d "$DB" -U "$USER" -P "$PASS" -C -h -1 -W -Q "$1" 2>/dev/null || echo "ERR"
  }

  KSFSF=$(run_sql "SET NOCOUNT ON; SELECT COUNT(*) FROM sudz.CnInvUplSfDouble WHERE ciusUnloadKey=$UPL_KEY AND ciusStatus=N'open'")
  KSDD=$(run_sql "SET NOCOUNT ON; SELECT COUNT(*) FROM sudz.CnInvUplInvDbtDouble WHERE ciudUnloadKey=$UPL_KEY AND ciudStatus=N'open'")

  if [[ "$KSFSF" =~ ^[0-9]+$ ]]; then
    if [[ "$KSFSF" -eq 0 ]]; then
      echo -e "${GREEN}✓ G3 КСДСФ open: 0${NC}"
    else
      echo -e "${RED}✗ G3 КСДСФ open: $KSFSF${NC}"
      FAIL=1
    fi
  fi
  if [[ "$KSDD" =~ ^[0-9]+$ ]]; then
    if [[ "$KSDD" -eq 0 ]]; then
      echo -e "${GREEN}✓ G4 КСДД open: 0${NC}"
    else
      echo -e "${RED}✗ G4 КСДД open: $KSDD${NC}"
      FAIL=1
    fi
  fi
else
  echo -e "${YELLOW}  (G3/G4 SQL: задайте FEMSQ_DB_* и sqlcmd для проверки очередей)${NC}"
fi

if [[ "$FAIL" -eq 0 ]]; then
  echo -e "${GREEN}=== Gate-проверка: PASS ===${NC}"
  exit 0
else
  echo -e "${RED}=== Gate-проверка: FAIL — см. runbook ===${NC}"
  echo "  docs/development/notes/sudz-dbt-upl-funnel-uat-runbook.md"
  exit 1
fi
