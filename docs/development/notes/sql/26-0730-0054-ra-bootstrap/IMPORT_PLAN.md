# 0054.4 — План импорта Access → MSSQL (после CREATE)

## Порядок загрузки (IDENTITY_INSERT ON)

1. `ra_at` — сохранить `at_key`
2. `ra_dir` — сохранить `key`; **пути `dir`**: на prod для FEMSQ заменить на доступный путь (SMB/mount), Access `X:\...` оставить только если FEMSQ читает тот же диск
3. `ra_ft` — ключи 1…6 (уже частично в `05_SEED`; при полном импорте — upsert)
4. `ra_ft_st` — если локальная в Access (есть в панели объектов)
5. `ra_ft_s` — сохранить `ft_s_key`; `ft_s_period`: `CAST(AccessValue AS nvarchar(50))`
6. `ra_ft_sn` — сохранить `ftsn_key`
7. `ra_a` — сохранить `adt_key` (на Access сейчас ~2…12, **нет** Docker `adt_key=14`)
8. `ra_f` — сохранить `af_key`; `af_source` Yes/No → bit

Staging / `ra_execution` / mapping — **не** из Access (пустые или seed FEMSQ).

## Smoke после импорта

- Выбрать существующую ревизию Access (например год 2026) **или** создать новую через FEMSQ UI
- Путь `ra_dir.dir` + файлы `ra_f` с `af_execute=1` должны быть читаемы сервисом FEMSQ
- thin JAR ≥ **0.1.0.152**; dry-run type=5 и type=3

## Выгрузка из Access

**Предпочтительно:** VBA `import-tools/mod_0054_4_ExportRaSql.bas` → папка с `01_*.sql`…`08_*.sql`  
(см. `import-tools/README.md`). Затем dry-run на Docker (shadow `ags.i_ra_*`), после OK — те же скрипты на prod.

Альтернатива: CSV/Excel вручную (не предпочтительно).
