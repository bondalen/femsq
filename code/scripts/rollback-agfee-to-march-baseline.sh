#!/usr/bin/env bash
# Откат домена AgFee (ags.ogAgFee / ogAgFeeP за 2026) к мартовскому baseline.
#
# 1) DELETE YEAR(oafDate)=2026 (CASCADE пункты)
# 2) Снимок march + adt_AddRA=1
# 3) executeAudit(14)
# 4) adt_AddRA=0, проверка счётчиков (ожид. acts≈31, pns≈521)
#
# Использование:
#   ./code/scripts/rollback-agfee-to-march-baseline.sh
#
# Требует: backend на GRAPHQL_URL, npm mssql в .cursor/dbhub.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GRAPHQL_URL="${GRAPHQL_URL:-http://127.0.0.1:8080/graphql}"
SQL=(node "$ROOT/code/scripts/femsq-sql.js")

echo "=== 1. Удаление актов YEAR=2026 (CASCADE пункты) ==="
"${SQL[@]}" "DELETE FROM ags.ogAgFee WHERE YEAR(oafDate) = 2026;
SELECT COUNT(*) AS acts2026 FROM ags.ogAgFee WHERE YEAR(oafDate)=2026;"

echo "=== 2. Снимок март + adt_AddRA=1, только type=6 на dir=15 ==="
"$ROOT/code/scripts/audit-switch-agfee-snapshot.sh" march
"${SQL[@]}" "UPDATE ags.ra_a SET adt_AddRA = 1 WHERE adt_key = 14;
UPDATE ags.ra_f SET af_execute = 0 WHERE af_dir = 15 AND af_key <> 313;
UPDATE ags.ra_f SET af_execute = 1, af_source = 1 WHERE af_key = 313;
SELECT adt_AddRA FROM ags.ra_a WHERE adt_key=14;"

echo "=== 3. executeAudit(14) — seed марта ==="
curl -s -X POST "$GRAPHQL_URL" -H 'Content-Type: application/json' \
  -d '{"query":"mutation { executeAudit(id: 14) { started alreadyRunning message } }"}'
echo

for i in $(seq 1 90); do
  st="$(curl -s -X POST "$GRAPHQL_URL" -H 'Content-Type: application/json' \
    -d '{"query":"{ audit(id: 14) { adtStatus } }"}' \
    | grep -oE '"adtStatus":"[^"]+"' | cut -d'"' -f4 || true)"
  echo "status=$st ($i)"
  [[ "$st" == "COMPLETED" || "$st" == "FAILED" ]] && break
  sleep 2
done

echo "=== 4. Проверка домена + adt_AddRA=0 ==="
"${SQL[@]}" "
SELECT
  (SELECT COUNT(*) FROM ags.ogAgFee WHERE YEAR(oafDate)=2026) AS acts2026,
  (SELECT COUNT(*) FROM ags.ogAgFeeP p JOIN ags.ogAgFee a ON p.oafpOaf=a.oafKey WHERE YEAR(a.oafDate)=2026) AS pns2026,
  (SELECT SUM(p.oafpTotal) FROM ags.ogAgFee a JOIN ags.ogAgFeeP p ON a.oafKey=p.oafpOaf WHERE YEAR(a.oafDate)=2026) AS smm;
UPDATE ags.ra_a SET adt_AddRA = 0 WHERE adt_key = 14;
SELECT adt_AddRA FROM ags.ra_a WHERE adt_key=14;
"

echo "Готово (март baseline)."
