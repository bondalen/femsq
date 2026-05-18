# Пакет SQL `_2605` для SQL Server 2012

**Назначение:** применение объектов `ags.fnIpgChRsltCstUtl2_2605`, `ags.fnIpgChRsltCstUtlPercentBrn_2605`, `ags.spMstrg_2605` на **Microsoft SQL Server 2012 SP4+** (продуктив: 11.0.7507.2).

**Исходный пакет (2016+):** `../` — использует `CREATE OR ALTER` и `DROP ... IF EXISTS`.

## Отличия от пакета `../`

| Конструкция | Пакет `../` (2016+) | Пакет `MSSQL2012/` |
|-------------|---------------------|---------------------|
| Создание объектов | `CREATE OR ALTER` | `IF OBJECT_ID` + `DROP` + `CREATE` |
| Откат / DROP | `DROP ... IF EXISTS` | `IF OBJECT_ID(...) IS NOT NULL` + `DROP` |
| Логика `_2605` | идентична | идентична |

## Порядок применения на продуктиве

```
1. Резервная копия FishEye
2. 00_VERIFY_before.sql     → package_compat = 'OK for MSSQL2012 package'
3. 01_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2605.sql
4. 02_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2605.sql
5. 03_CREATE_PROCEDURE_spMstrg_2605.sql
6. 04_VERIFY_after.sql      → сверить COUNT с ожиданиями в комментариях
```

При сбое: `05_ROLLBACK.sql`

После перехода клиентов (отдельно): `06_DROP_obsolete_2408.sql`

## Документация

- Порядок работ: `docs/deployment/db-upgrade-spMstrg-2605.md`
- Чеклист дня деплоя: `docs/deployment/db-upgrade-spMstrg-2605-deploy-day-checklist.md`  
  (в шагах SQL указывать путь `.../26-0508/MSSQL2012/`)

## Повторное применение

Скрипты 01–03 **идемпотентны**: перед `CREATE` выполняется `DROP` существующего объекта `_2605` (где применимо).

**Создано:** 2026-05-16
