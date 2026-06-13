# Пакет SQL `spMstrg_2606` для SQL Server 2012

**Назначение:** применение на **Microsoft SQL Server 2012 SP4+** (продуктив FishEye, `11.0.7507.2`).

**Исходный пакет (dev, 2016+):** `../` — `CREATE OR ALTER`, идемпотентные скрипты.

## Порядок применения

```
00_VERIFY_before.sql
00-perf-indexes.sql
01_CREATE_TABLE_ipgChRlV.sql
01b_CREATE_TABLE_factDoc.sql
01c_CREATE_TRIGGER_factDoc_sync.sql
01d_BACKFILL_factDoc.sql
02_CREATE_FUNCTION_fnIpgChDatsV.sql
03a0_CREATE_FUNCTION_fnStCostIpgPn_2606.sql
03a_CREATE_FUNCTION_fnStCostRsIpgPn_2606.sql
03b0_CREATE_FUNCTION_fnStCost_2606.sql
03b_CREATE_FUNCTION_fnStCostRsCstAgPn_2606.sql
03b1_CREATE_FUNCTION_fnMasteringFact_2606.sql   ← DROP+CREATE (50 функций)
03c_CREATE_FUNCTION_fnMasteringCstAgPnSh_2606.sql
03d_CREATE_FUNCTION_fnMasteringStIpgStCost_2606.sql
04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql  ← v9.0 MSTVF (DROP TF)
05_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2606.sql
05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql
06_CREATE_PROCEDURE_spMstrg_2606.sql
07_VERIFY_after.sql
07_VERIFY_spMstrg_2606_chain5.sql   (в ../ — полный прогон spMstrg)
08_ROLLBACK.sql
```

## Отличия от dev

| Конструкция | dev | MSSQL2012 |
|-------------|-----|-----------|
| `CREATE OR ALTER` | да | `IF OBJECT_ID DROP` + `CREATE` |
| `fn2_2606` | TF (MSTVF) | TF (MSTVF), DROP type `TF` |
| `03b1` | 50× CREATE OR ALTER | 50× DROP + CREATE |

## Документация

- [`docs/deployment/db-upgrade-spMstrg-2606.md`](../../../../deployment/db-upgrade-spMstrg-2606.md)
- [`docs/deployment/db-upgrade-spMstrg-2606-deploy-day-checklist.md`](../../../../deployment/db-upgrade-spMstrg-2606-deploy-day-checklist.md)

**Обновлено:** 2026-06-12
