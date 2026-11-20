# Пакет: `ags.ra_change_au` (multi-presentation ОА изм)

**Дата:** 2026-11-19  
**Задача:** 0086 / plan release-r1x §1.4.3  
**Решение:** [domain/ra/06-decision-rc-au.md](../../domain/ra/06-decision-rc-au.md)  
**Целевая платформа пакета на прод:** SQL Server 2012 → подпапка `MSSQL2012/`

## Назначение

Additive DDL: таблица представлений изменения отчёта агента (аналог `ralpRaAu`).  
UX `ЗаПериодЗаОтчётОдинНомер` на `ra_change` **не** изменяется.

## Базы на DEV

| База | Назначение | `ra_change_au` |
|------|------------|----------------|
| **`FishEye`** | Бизнес-процесс **СУДЗ** — проверенное состояние, **не нарушать** DDL/данными R1 | **нет** (откат 2026-11-20) |
| **`FishEye_prod_noM6`** | Стенд R1 / освоения / ревизий (копия прод-схемы без M6) | **да** (пакет ниже) |

Разработку модели Au и сверки типа 5 вести **только** на `FishEye_prod_noM6` (или отдельном клоне). JAR для СУДЗ подключать к `FishEye`.

## Порядок на стенде R1 (`FishEye_prod_noM6`)

1. `MSSQL2012/00_VERIFY_before.sql`
2. `MSSQL2012/01_CREATE_ra_change_au.sql`
3. `MSSQL2012/02_MIGRATE_one_au_per_change.sql`
4. `MSSQL2012/03_VERIFY_after.sql`
5. `MSSQL2012/04_SEED_ra_at_types_2_6.sql` — если в `ags.ra_at` нет ключей 2..6 (иначе FK на `adt_type`)

## Откат

`MSSQL2012/99_ROLLBACK.sql` — только если Au ещё не используется кандидатом в проде.  
На DEV `FishEye` (СУДЗ) выполнен 2026-11-20 через трёхчастные имена (DSN указывал на noM6).

## Пакет кандидата R1.0

Копия MSSQL2012 входит в `dist/26-1119-R1.0/sql/` (см. [r1.0-candidate-operator.md](../../../../deployment/r1.0-candidate-operator.md)).

**Прод FishEye: не применять до переключения R1** (Решение 2026-11-20, [06 §5](../../domain/ra/06-decision-rc-au.md)).

**Сверка DBHub 2026-11-20** (DSN → `FishEye_prod_noM6`):

| База | `ra_change_au` | Примечание |
|------|----------------|------------|
| `FishEye_prod_noM6` | есть: 3380 строк / 3378 rac, multi=2, FK factDoc, `ra_at` 1–6 | стенд R1 |
| `FishEye` (СУДЗ) | **удалена** (`99_ROLLBACK`); `ra_change` 3047, `ra_at` только 1 | без изменений схемы R1 |
