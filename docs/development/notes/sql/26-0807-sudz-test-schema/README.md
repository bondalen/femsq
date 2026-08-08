# Песочница СУДЗ — схема `test_sudz`

**Дата:** 2026-08-07  
**Контур:** только **DEV** (Docker `femsq-mssql`). На продуктив **не** переносить.  
**Спецификация:** [08-target-schema.md](../../domain/sudz/08-target-schema.md)

## Назначение

Изолированная схема для проектирования артефактов целевой модели СУДЗ (`Dbt`, `invDbtDbt`, `invDbtVar`, …) и внесения тестовых данных — **без изменения** рабочего контура `ags.*`.

## Правила

1. Новые и экспериментальные таблицы — в `test_sudz.*`.
2. Ссылки на уже живые сущности (`cn`, `inv`, `cnNum`, `invNum`, `cnInv`, `accnt`, `cn_s_org`, `cn_inv_dbt_upl`, …) — **cross-schema FK** на `ags.*` (те же ключи, реальные данные при необходимости).
3. `invDbt` в песочнице — `test_sudz.invDbt` с суррогатным PK `idKey` (не писать тестовые строки в `ags.invDbt`).
4. DDL/DML этой папки — только для dev; в `MSSQL2012/` для прода не копировать, пока модель не утверждена и не перенесена в целевую схему (`ags` или отдельную продуктивную).

## Скрипты

| Файл | Назначение | Статус |
|------|------------|--------|
| `00_CREATE_SCHEMA_test_sudz.sql` | Создание схемы | применён на DEV 2026-08-07 |
| `01_CREATE_TABLE_Dbt.sql` | `test_sudz.Dbt` | применён на DEV 2026-08-07 |
| `02_CREATE_TABLE_invDbt.sql` | `test_sudz.invDbt` (суррогат `idKey`, S35) | применён / обновлён 2026-08-07 |
| `03_CREATE_TABLE_invDbtDbt.sql` | `test_sudz.invDbtDbt` (FK на `idKey`) | применён / обновлён 2026-08-07 |
| `04_RECREATE_invDbt_surrogate.sql` | DROP+CREATE `invDbt`/`invDbtDbt` + триггер | применён на DEV 2026-08-07 |
| `05_CREATE_TABLE_invDbtVar.sql` | `test_sudz.invDbtVar` | применён на DEV 2026-08-07 |
| `06_CREATE_TABLE_invDbtDbtVar.sql` | `test_sudz.invDbtDbtVar` + триггер контекста | применён на DEV 2026-08-07 |
| `07_CREATE_TABLE_DbtValue.sql` | `test_sudz.DbtValue` + триггер согласованности | применён на DEV 2026-08-07 |
| `08_CREATE_TABLE_cn_inv_dbt_upl_sandbox.sql` | sandbox-выгрузки + FK `DbtValue`→`test_sudz` | применён на DEV 2026-08-07 |
| `09_SEED_dbt_82_85_Q4Q1Q2.sql` | seed долгов 82/85 за IV.25–II.26 | применён на DEV 2026-08-07 |
| `10_CREATE_TABLE_cnInvCmm_mirrors.sql` | зеркала `cnInvCmm*`/`cnInvGr`/`yr` (FK → `Dbt`) | применён на DEV 2026-08-07 |
| `11_SEED_cmm_yr_2026.sql` | yr 2026 + группы IV.25–II.26 + комментарии 82/85 | применён на DEV 2026-08-07 |
| `12_CREATE_Yr_DbtChanges_mini.sql` | `vw_Yr_DbtFact`, `vw_Yr_DbtChanges_mini_2026`, proc `Yr_DbtChanges_mini` (S41) | применён; **замещён** `13` |
| `13_CREATE_Yr_DbtChanges_mini_S42b.sql` | S42b: контракт шапки | применён |
| `14_SEED_cst_ag_82_85.sql` | S42c/e: `DbtUplCstAg` + cst/ag/кураторы 82/85 | применён |
| `15_CREATE_Yr_DbtChanges_mini_S42cd.sql` | S42c/d: Cst/Ag/погашено в fact/VIEW/proc | применён |
| `16_CREATE_Yr_DbtChanges_S43.sql` | S43: date-major + `Yr_DbtChanges` обёртка | применён |
| `17_SEED_yr_2025_5slices_S45.sql` | S45: yr 900 + upl 801–805 + факты 82/85 под Rslt_26-0212 | применён |
| `18_SEED_mery_D644_82_85_S44.sql` | S44: полные тексты мероприятий 82/85 из D644_26-05 → `cnInvCmm` gr=903 | применён |
| `19_CREATE_Yr_DbtChangesD644_S44.sql` | S44: `test_sudz.Yr_DbtChangesD644(@yr, @curr_upl)` ~18 кол. | применён |
| `20_SEED_mery_D644_26-03_82_85_S46.sql` | S46: mery + `cnInvCmmCst` gr=805 из D644_26-03 | применён |
| `21_CREATE_Yr_DbtChangesD644Svod_S46.sql` | S46: `Yr_DbtChangesD644Svod` — годовой свод по счетам | применён |

**Проверка:** `EXEC test_sudz.Yr_DbtChanges @yr=901;` (3 среза 2026) · `EXEC test_sudz.Yr_DbtChanges @yr=900;` (5 срезов 2025 / S45).
