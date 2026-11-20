# Пакет: `ags.ra_change_au` (multi-presentation ОА изм)

**Дата:** 2026-11-19  
**Задача:** 0086 / plan release-r1x §1.4.3  
**Решение:** [domain/ra/06-decision-rc-au.md](../../domain/ra/06-decision-rc-au.md)  
**Целевая платформа пакета на прод:** SQL Server 2012 → подпапка `MSSQL2012/`

## Назначение

Additive DDL: таблица представлений изменения отчёта агента (аналог `ralpRaAu`).  
UX `ЗаПериодЗаОтчётОдинНомер` на `ra_change` **не** изменяется.

## Порядок на DEV (`FishEye_prod_noM6`)

1. `MSSQL2012/00_VERIFY_before.sql`
2. `MSSQL2012/01_CREATE_ra_change_au.sql`
3. `MSSQL2012/02_MIGRATE_one_au_per_change.sql`
4. `MSSQL2012/03_VERIFY_after.sql`
5. `MSSQL2012/04_SEED_ra_at_types_2_6.sql` — если в `ags.ra_at` нет ключей 2..6 (иначе FK на `adt_type`)

## Откат

`MSSQL2012/99_ROLLBACK.sql` — только если Au ещё не используется кандидатом в проде.

## Пакет кандидата R1.0

Копия MSSQL2012 входит в `dist/26-1119-R1.0/sql/` (см. [r1.0-candidate-operator.md](../../../../deployment/r1.0-candidate-operator.md)).

**Прод FishEye: не применять до переключения R1** (Решение 2026-11-20, [06 §5](../../domain/ra/06-decision-rc-au.md)). Применено: DEV `FishEye_prod_noM6` (01–04) и DEV `FishEye` (таблица Au создана по ошибке DSN 2026-11-19; оставлена — DEV на модели Au; состав применённых шагов сверить при следующем подключении DBHub).
