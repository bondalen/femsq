# Full-diff `cstAgPn` прод → noM6 (C2 §3.5.1 вариант B)

**Дата:** 2026-11-26  
**Задача:** 0081  
**План:** [chat-plan-26-1120](../../chats/chat-plan/chat-plan-26-1120-c2-d11-ipg-plans.md) §3.5.1  
**Сессия продОбмен:** `~/Downloads/продОбмен/26-1126_09-31/`  
**Стенд:** `FishEye_prod_noM6`

## Назначение

1. Readonly-выгрузка с **прода** всех `ags.cstAgPn` (+ родители).  
2. На DEV — **вариант B**: remap 7 ключей + UPDATE displaced + INSERT ~72 (не truncate).

**На прод:** только чтение.  
**На DEV:** исполнение по [open/RUNBOOK_B.md](open/RUNBOOK_B.md).

## Пакет B (исполнение на noM6)

| Скрипт | Шаг плана |
|--------|-----------|
| `00b_SNAPSHOT_remap_keys_DEV_ONLY.sql` | 3.5.1.0 |
| `03_REMAP_7_codes_DEV_ONLY.sql` | 3.5.1.1 |
| `04_UPDATE_displaced_keys_DEV_ONLY.sql` | 3.5.1.2 |
| `05_UPDATE_3804_code_DEV_ONLY.sql` | 3.5.1.3 SKIP (прод исправлен) |
| `02_IMPORT_noM6_DEV_ONLY.sql` | 3.5.1.4 (~72) |
| `06_VERIFY_sync_DEV_ONLY.sql` | 3.5.1.5 |

Копии в `MSSQL2012/` и `open/`.

## Выгрузка с прода (уже сделано)

| Файл | Назначение |
|------|------------|
| `00_COUNTS_readonly.sql` | counts |
| `01c_EXPORT_sqlcmd_mode.sql` | SQLCMD → TSV |
| `отПрод/femsq_cstagpn_full_diff_20261126.zip` | ответ |

**Запрещено:** DDL/DML на прод; выкладка JAR. Скрипты B — **только** `FishEye_prod_noM6`.
