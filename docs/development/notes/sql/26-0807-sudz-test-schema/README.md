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
| `12_CREATE_Yr_DbtChanges_mini.sql` | `vw_Yr_DbtFact`, `vw_Yr_DbtChanges_mini_2026`, proc `Yr_DbtChanges_mini` | применён на DEV 2026-08-07 |

**Ядро + комментарии/год + мини-витрина Rslt.** Проверка: `SELECT * FROM test_sudz.vw_Yr_DbtChanges_mini_2026` или `EXEC test_sudz.Yr_DbtChanges_mini @yr=901`.
