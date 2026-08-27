# P3 — dry-check backfill `dvInvDbt` (SELECT only)

**Дата:** 2026-08-26  
**Скрипт:** [00_VERIFY_before.sql](./00_VERIFY_before.sql)  
**Правило маппинга:** `dvInvDbt` ← `invDbtDbtVar.iddvInvDbt` WHERE `iddvInvDbtVar = dv.dvInvDbtVar`

## Результаты прогона (DBHub)

| Проверка | `sudz` | `test_sudz` |
|----------|--------|-------------|
| `dv_total` | 16 | 16 |
| `no_slot` | **0** | **0** |
| `one_slot` | **16** | **16** |
| `multi_slot` | **0** | **0** |
| `dup_pairs` `(iddvInvDbt, dvUpl)` | **0** | **0** |
| слот vs `invDbtDbt` для текущего `dvDbt` | **16/16 match** | (не требовался для UNIQUE) |

**Вердикт P3:** ✅ backfill однозначен; UNIQUE `(dvInvDbt, dvUpl)` после ALTER выполним.

**Статус P3:** ✅ 2026-08-26  
**Next:** **P4** — черновик SQL-пакета ALTER (без apply).
