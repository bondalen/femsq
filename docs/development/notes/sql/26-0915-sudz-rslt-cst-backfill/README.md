# Пакет: обследование / бэкфилл стройки для Rslt (QIV + QI)

**Создан:** 2026-09-15  
**Цель:** на **проде** (и при наличии данных — на DEV) понять, можно ли дополнить квартальные «Код/Наименование стройки» в FEMSQ Rslt для срезов **QIV** (база года / upl≈901) и **QI** (upl≈902).  
**Правила SQL:** [sql-server-deployment-rules.md](../../../../deployment/sql-server-deployment-rules.md) · prod = MSSQL 2012 SP4.

## Контекст

| Путь | Источник стройки |
|------|------------------|
| Access `Yr_DbtChanges` | `ags.fnCiasDbtUplCst(cias, dbtUpl)` ← `cn_inv_pm` + мост `cn_inv_dbt_upl_g_p` |
| FEMSQ Rslt (`vw_Yr_DbtFact`) | `DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn)` |

На DEV (2026-09-15…16): `ags.cn_inv_dbt_upl` **нет** дат QIV/QI/QII (2025-12-31 / 2026-03-31 / 2026-06-30); `g_p` max **2025-06-30** → `fn(·, 901+)` пуст. Канон `00`→`01`→`02` — для **прода** (или после появления g_p).

**DEV-обход (S80.1, 2026-09-16):** скрипт [`03_BACKFILL_DbtUplCstAg_FROM_ACCESS_EXCEL.mjs`](./03_BACKFILL_DbtUplCstAg_FROM_ACCESS_EXCEL.mjs) — `*_CstAgPnKey` из Access `26-0505` → softBase → softQi (QI-only / twin inv) → INSERT @901/@902; @903 = carry с 902 при Value@903. GEN inv = base **или** QI (col Q). Stub `cst`/`cstAg`/`cstAgPn` для Access keys вне каталога DEV (`artifacts/stage2_s80_*miss47*`, `*remain11*`, `*remain1_23393*`).

| upl | DbtUplCstAg (итог S80.2b) |
|-----|---------------------------|
| 901 | **1660** |
| 902 | **1636** |
| 903 | **1446** (carry) |

**S80.2b:** row QIV+QI ↔ Access — PASS, `E-S80-cst-backfill-miss=0` ([`stage2_s80_qiv_qi_vs_access_final_26-0916.json`](../26-0831-sudz-dbt-slot-link/artifacts/stage2_s80_qiv_qi_vs_access_final_26-0916.json)).

Артефакты: `artifacts/stage2_s80_dbtuplcstag_from_access_*.json`, `…_insert_26-0916.sql`, patch SQL.

## Порядок на проде (SSMS, READ → кандидаты → apply)

1. **`00_SURVEY_prod_cst_qiv_qi.sql`** — только SELECT. Есть ли upl QIV/QI, `g_p`, покрытие fn, есть ли `DbtUplCstAg` / `invDbtCia`.  
2. **`01_CANDIDATES_DbtUplCstAg.sql`** — READ: кандидаты `(dbtKey, femsqUpl, cstapKey)` + отказы (multi / нет g_p / нет cia).  
3. **`02_BACKFILL_DbtUplCstAg_DRAFT.sql`** — INSERT только однозначных; по умолчанию **ROLLBACK**. Apply — после ревью result set’ов и смены на COMMIT.

Копии под 2012: `MSSQL2012/` (те же тексты; синтаксис без 2016+).

## Параметры (в шапке скриптов)

| Переменная | Смысл | DEV пример |
|------------|--------|------------|
| `@YrKey` | год-вариант FEMSQ | `901` |
| `@UplQiv` / `@UplQi` | ключи выгрузок ДЗ в схеме FEMSQ | `901` / `902` |
| `@SudzSchema` | схема новой модели | `sudz` (на prod после cutover может быть `ags` — сверить) |

Сопоставление FEMSQ upl ↔ ags upl для `fn`: по **`uplStatusOnDate`** (не предполагать равенство ключей).

## Запреты

- Не INSERT при `countCstAgPn <> 1` / коде вида `строек: N`.  
- Не «угадывать» стройку из pm без `g_p` (naive any-pm) как prod backfill — только обследование.  
- Не применять `02` на прод без бэкапа / окна и без PASS `00`+`01`.

## Связь

- Домен: [04-data-model §2.6 `fnCiasDbtUplCst`](../../domain/sudz/04-data-model.md)  
- План 1.1.1.2: [chat-plan-26-0819-cn-inv-pmt-upl.md](../../chats/chat-plan/chat-plan-26-0819-cn-inv-pmt-upl.md)  
- Cutover: [db-upgrade-sudz-invdbt-cutover.md](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md)
