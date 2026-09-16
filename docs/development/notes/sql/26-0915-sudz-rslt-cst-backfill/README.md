# Пакет: обследование / бэкфилл стройки для Rslt (QIV + QI)

**Создан:** 2026-09-15  
**Цель:** на **проде** (и при наличии данных — на DEV) понять, можно ли дополнить квартальные «Код/Наименование стройки» в FEMSQ Rslt для срезов **QIV** (база года / upl≈901) и **QI** (upl≈902).  
**Правила SQL:** [sql-server-deployment-rules.md](../../../../deployment/sql-server-deployment-rules.md) · prod = MSSQL 2012 SP4.

## Контекст

| Путь | Источник стройки |
|------|------------------|
| Access `Yr_DbtChanges` | `ags.fnCiasDbtUplCst(cias, dbtUpl)` ← `cn_inv_pm` + мост `cn_inv_dbt_upl_g_p` |
| FEMSQ Rslt (`vw_Yr_DbtFact`) | `DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn)` |

На DEV (2026-09-15): `DbtUplCstAg` для 901/902 пуст; `g_p` в `ags` обрывается на **2025-06-30** — поэтому fn(·, 901) пуст. На **проде** ожидается полный горизонт (см. S26: DEV отставал от бэкапов).

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
