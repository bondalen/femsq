---
title: "Type 5 — отчёт ручной проверки (шаблон)"
created: "2026-03-25"
lastUpdated: "2026-03-25"
version: "1.0.0"
---

## Контекст прогона

- **auditId (adt_key)**: `<number>`
- **exec_key**: `<number>`
- **addRa (adt_AddRA)**: `<true|false>`
- **type**: `5 (AllAgents)`
- **дата/время проверки**: `<YYYY-MM-DD HH:MM>`
- **проверяющий**: `<name>`

## Источники данных (артефакты)

- **Скрипт чек-листа**: `docs/sql-scripts/type5-verification-checklist.sql`
- **Цепочка staging→domain→journal**: `docs/sql-scripts/type5-chain-stg-domain-journal.sql`
- **Счётчики vs БД (baseline required)**: `docs/sql-scripts/type5-counters-vs-db-check.sql`
- **Match categories (RA)**: `docs/sql-scripts/type5-match-categories-check.sql`
- **Post-apply sanity (RA)**: `docs/sql-scripts/type5-post-apply-ra-sanity.sql`

## Journal выполнения (DB)

### `ags.ra_execution`

- **exec_status**: `<COMPLETED|FAILED|...>`
- **exec_started**: `<timestamp>`
- **exec_finished**: `<timestamp>`
- **exec_duration_sec**: `<number>`
- **exec_error**: `<empty|text>`

### `ags.ra_a.adt_results` (фрагменты)

Вставьте сюда ключевые строки/счётчики из `adt_results` (или приложите целиком при необходимости).

```
<paste adt_results snippet>
```

## Staging (scope: `ra_stg_ra` по `exec_key`)

- **stg_rows_total**: `<number>`
- **stg_rows_ra_sign** (`ОА` + `ОА прочие`): `<number>`
- **stg_rows_rc_sign** (`ОА изм`): `<number>`
- **прочие замечания**: `<text>`

## Baseline (до apply)

Если проверяется “счётчики vs факт” (1.6.3), зафиксируйте baseline max‑ключи **до** apply.

- `baseline_max_ra_key`: `<number>`
- `baseline_max_ras_key`: `<number>`
- `baseline_max_rac_key`: `<number>`
- `baseline_max_racs_key`: `<number>`
- `baseline_max_rm_key` (marker, опционально): `<number>`

## Ожидания (expected)

Ожидаемые значения берём из `adt_results` для соответствующего прогона.

### RA apply

- `inserted`: `<number>`
- `updated`: `<number>`
- `summInserted`: `<number>`
- `summUnchangedSkipped`: `<number>`
- `raDeleteApplied` (если deletes включены): `<number>`

### RC apply

- `rcChangesInserted`: `<number>`
- `rcSumsInserted`: `<number>`
- `rcChangesUpdated`: `<number>`
- `rcSumsInsertedChanged`: `<number>`
- `rcSumsUnchangedSkipped`: `<number>`
- `rcDeleteApplied` (если deletes включены): `<number>`

### Idempotency markers

- `marker_*AlreadyDone`: `<true|false>` (для повторных запусков reconcile)
- marker‑строки для `exec_key`: `<count>`

## Факты (actual)

Фактические значения снимаем по DBHub‑скриптам (обычно 1.6.3 через baseline).

### Дельты домена (по baseline)

- **Δ `ags.ra`**: `<number>`
- **Δ `ags.ra_summ`**: `<number>`
- **Δ `ags.ra_change`**: `<number>`
- **Δ `ags.ra_change_summ`**: `<number>`

### Дубликаты (должно быть пусто)

- RA дубли по `(ra_period, ra_num)`: `<none|details>`
- RC дубли по `(ra_period, raс_ra, raс_num)`: `<none|details>`

## Сверка expected vs actual

Опишите расхождения (если есть) и объяснение.

- **RA**: `<OK|Mismatch + details>`
- **RC**: `<OK|Mismatch + details>`
- **Markers**: `<OK|Mismatch + details>`

## Итог

- **Статус**: `<PASS|FAIL|PASS_WITH_NOTES>`
- **Ключевые выводы**:
  - `<bullet>`
  - `<bullet>`
- **Риски/заметки**:
  - `<bullet>`
- **Рекомендованные следующие шаги**:
  - `<bullet>`

