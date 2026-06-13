#!/usr/bin/env bash
# Запуск одного шага 07h1 с лимитом времени и потоковым выводом NOWAIT.
# Использование: ./run_07h1_step.sh V|A|B|C|D [timeout_sec]
set -euo pipefail
STEP="${1:?step V|A|B|C|D}"
TIMEOUT_SEC="${2:-60}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_FILE="$SCRIPT_DIR/07h1_perf_elements_chain5.sql"
TMP_SQL="$(mktemp)"
trap 'rm -f "$TMP_SQL"' EXIT

sed "s/@step  char(1) = 'A'/@step  char(1) = '${STEP}'/" "$SQL_FILE" > "$TMP_SQL"

echo "[run_07h1] step=${STEP} timeout=${TIMEOUT_SEC}s $(date -Iseconds)"
timeout "${TIMEOUT_SEC}" docker exec -i femsq-mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'kolob_OK1' -d FishEye -C -i /dev/stdin < "$TMP_SQL" 2>&1
rc=$?
if [[ $rc -eq 124 ]]; then
  echo "[run_07h1] TIMEOUT after ${TIMEOUT_SEC}s — stopping, investigate"
  docker exec femsq-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'kolob_OK1' -d FishEye -C -Q \
    "DECLARE @id int; SELECT TOP 1 @id=r.session_id FROM sys.dm_exec_requests r WHERE r.database_id=DB_ID('FishEye') AND r.session_id<>@@SPID ORDER BY r.start_time; IF @id IS NOT NULL EXEC('KILL '+@id);" -W 2>/dev/null || true
  exit 124
fi
exit $rc
