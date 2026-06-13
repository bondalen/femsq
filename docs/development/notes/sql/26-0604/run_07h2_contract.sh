#!/usr/bin/env bash
# Замер fnMasteringCstAgPnSh по стройкам группы stIpg (по одной).
# Использование:
#   ./run_07h2_contract.sh 61              # эталон: все стройки группы 61
#   ./run_07h2_contract.sh 61 120            # группа 61, timeout 120 сек
#   ./run_07h2_contract.sh 46                # все стройки группы 46
#   ./run_07h2_contract.sh 46 1 30           # группа 46, стройки 1..30
#   ./run_07h2_contract.sh 46 1 30 120       # + timeout 120 сек
set -euo pipefail
STIPG="${1:?stIpg required (e.g. 61 or 46)}"
shift || true
FROM=""
TO=""
TIMEOUT_SEC=600
if [[ $# -eq 1 && "$1" -ge 30 ]]; then
  # один аргумент >= 30 — таймаут (не номер стройки)
  TIMEOUT_SEC="$1"
elif [[ $# -ge 1 ]]; then
  FROM="$1"
  TO="${2:-$1}"
  TIMEOUT_SEC="${3:-600}"
fi
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_FILE="$SCRIPT_DIR/07h2_perf_contracts_stIpg46.sql"
TMP_SQL="$(mktemp)"
trap 'rm -f "$TMP_SQL"' EXIT

sed -e "s/DECLARE @stIpg   int = [0-9]*;/DECLARE @stIpg   int = ${STIPG};/" "$SQL_FILE" \
  | if [[ -n "$FROM" ]]; then
      sed -e "s/DECLARE @fromRn  int = NULL;/DECLARE @fromRn  int = ${FROM};/" \
          -e "s/DECLARE @toRn    int = NULL;/DECLARE @toRn    int = ${TO};/"
    else
      cat
    fi > "$TMP_SQL"

echo "[run_07h2] stIpg=${STIPG} from=${FROM:-1} to=${TO:-all} timeout=${TIMEOUT_SEC}s $(date -Iseconds)"
timeout "${TIMEOUT_SEC}" docker exec -i femsq-mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'kolob_OK1' -d FishEye -C -i /dev/stdin < "$TMP_SQL" 2>&1
rc=$?
if [[ $rc -eq 124 ]]; then
  echo "[run_07h2] TIMEOUT after ${TIMEOUT_SEC}s"
fi
exit $rc
