# DbtSlotLink — реестр P1 (L001–L010) и синхронизация invDbtDbt

**Дата:** 2026-08-31  
**lastUpdated:** 2026-09-01  
**Схема DEV:** `sudz`  
**Прод:** `MSSQL2012/` → `ags`  
**Документация:** [04-5](../../domain/sudz/04-5_dbt-invdbt-cardinality-d1.md), [04-6 §3.3](../../domain/sudz/04-6_multi-dbt-p1-three-paths.md)

## Назначение

- Хранить прецеденты **1 Dbt → N invDbt-слотов** (равноправные members).
- **`canonicalDbtKey`** — NOT NULL после Apply; вычисляется алгоритмом (без оператора).
- Триггеры **I2/I3/I4** — согласованность группы и `invDbtDbt` при любом CRUD.

## Порядок применения (DEV)

```text
01_CREATE_TABLE_DbtSlotLink.sql
02_SEED_L001_L010.sql          -- только group pending + members
03_PROC_ApplyDbtSlotLinks.sql
04_TRIGGER_invDbtDbt_GroupConsistency.sql
05_TRIGGER_Dbt_NoDeleteIfCanonical.sql
11_TRIGGER_DbtValue_no_sibling_dup.sql   -- A1 P1: sibling same-ttl + one-per-Dbt@upl
09_BACKFILL_DbtValue_pit_ags26_28.sql  -- Stage1: 801←26, 802←27, 803←28 (PIT)
EXEC sudz.ApplyDbtSlotLinks;           -- или @lid = N'L001'
08_SEED_cmm_grp805_stage1.sql          -- Cmm seed для сверки Rslt (7947, L001)
99_VERIFY_rslt_stage1.sql
99_VERIFY.sql

-- legacy (не для sum-parity row1):
-- 06 / 07 — last-asOf-any (широкий портфель ~10k)
```

**Stage 1 Rslt (2025.I–II):** `asOfUpl=803`, без upl 804/901. Экспорт:  
`GET /api/v1/sudz/rslt-sborn.xlsx?yr=900&asOfUpl=803`  
Эталон: `ags_Yr_DbtChangesRslt_26-0212_26-0217.xlsx` (строки 129, 134–144; row1 = `SUBTOTAL`).

### Stage 1 — полный Rslt и суммы row1

| Артефакт | Путь |
|----------|------|
| Полный FEMSQ Rslt base–QI–QII (PIT) | `artifacts/ags_Yr_DbtChangesRslt_900_asOf803_pit_base-QI-QII_*.xlsx` |
| Gate (SQL+Excel) | `./verify-rslt-stage1.sh` → `artifacts/stage1_verify_*.json` |
| PIT SQL gate | `99_VERIFY_pit_sums.sql` |
| Протокол | `artifacts/stage1_verify_*.json` / `stage1_sum_verify_pit_*.json` |

| Проверка | Результат |
|----------|-----------|
| L* / 7947 (бизнес-ключ) | ✅ |
| Access Excel row1 Ttl/Overd/погашено ≡ FEMSQ (база–QI–QII) | ✅ |
| Колонки QIII/QIV в эталоне | **игнор** (отдельного Excel QIII нет) |
| погашено QI/QII | ✅ формула Access в экспортёре (JAR ≥240) |

**Cutover:** [E1′ PIT](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md#e1--паритет-исторических-rslt-pit-2026-08-31) — запрет last-asOf-any (`06`/`07`).

**Exit stage1:** `verify-rslt-stage1.sh` exit 0; JAR ≥0.1.0.240; upl 804/901 вне scope.

### Stage 2 — QIV (variant B, S76)

| Артефакт | Путь |
|----------|------|
| Реестр дельт A/B | [stage2_qiv_delta_registry.md](./stage2_qiv_delta_registry.md) |
| PASS после подгонки (не gate) | `artifacts/stage2_qiv_verify_26-0831.json` |
| Экспорт asOfUpl=901 | `artifacts/ags_Yr_DbtChangesRslt_900_asOf901_qiv_parity_26-0831.xlsx` |
| B-seed (deprecated) | `10_SEED_access_q4_missing_9.sql` — **не применять** |
| P3 manifest | [p3_data_gap_manifest.json](./p3_data_gap_manifest.json) |
| A1 trigger (P1) | `11_TRIGGER_DbtValue_no_sibling_dup.sql` |
| Gate A1 SQL | `99_VERIFY_qiv_stage2.sql` |

**Важно:** PASS QIV 2026-08-31 достигнут ручными SQL — см. реестр §6. Целевой gate: apply без SQL + `verify_qiv_excel_only` / `verify_qiv_full_access` (черновик в реестре §7).

**Exit stage2 (целевой):** группа A закрыта в коде; группа B задокументирована; QIII по-прежнему вне scope.

## C1 (воронка)

Backend `invDbtDbtEnsure` использует active-группы (`lPick`) до F1/new Dbt.

## Rebind (0071, фаза 2)

Прямой CRUD `invDbtDbt` для grouped slots блокируется триггером; rebind — через сервис/API.
