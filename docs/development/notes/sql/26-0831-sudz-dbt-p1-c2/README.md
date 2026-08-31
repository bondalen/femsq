# C2 — dbtValueLoad + очередь P1 (сегм. 35)

**Дата:** 2026-08-31  
**DDL:** `30_CREATE_CnInvUplDbtP1.sql` (DEV ✅)

## Шаг воронки

| stepId | После | Действие |
|--------|-------|----------|
| `dbtValueLoad` | `invDbtDbtEnsure` | snapshot; **всегда** rebuild `CnInvUplDbtP1`; при `flLoad` — tail `DbtValue` |

## Логика P1 (режим A)

1. Base upl = `yr.cn_inv_dbt_upl` для года, к которому привязан curr upl (`yr_upl_p`).
2. **Исчезнувший Dbt:** Value на base слоте, нет Value на curr для того же слота.
3. Sum-match: `dvTtl` и `dvOverd` (если > 0) ↔ `cidutDebt` в Tbl curr (ε=0.01), без фильтра cn/контрагент.
4. Очередь: `single` | `multi` | `none` по числу кандидатов Tbl.

## Smoke (после прогона воронки на upl ∈ yr_upl_p)

```sql
SELECT cip1Reason, COUNT(*) FROM sudz.CnInvUplDbtP1
WHERE cip1UnloadKey = @curr GROUP BY cip1Reason;

SELECT COUNT(DISTINCT dbtKey) FROM (
  SELECT dv.dvInvDbt AS slotKey, idd.iddDbt AS dbtKey
  FROM sudz.DbtValue dv
  JOIN sudz.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
  WHERE dv.dvUpl = @base
) b
WHERE NOT EXISTS (
  SELECT 1 FROM sudz.DbtValue dv2
  WHERE dv2.dvInvDbt = b.slotKey AND dv2.dvUpl = @curr
);
```

## Не в scope C2

- UI экран разбора P1 (путь 3 / rebind)
- Auto cross-iKey link
- Retrofix upl 910
- Q↔Q diff (фаза 2)
