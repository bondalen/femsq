# Журнал деплоя spMstrg_2606 на продуктив

**Сервер:** SPB-05-NV-SQL1 | **БД:** FishEye  
**Дата:** 2026-11-18  
**Исполнитель:** Александр  
**Канал:** `продОбмен/26-1117_17-31/` (AES)  
**Backup БД:** недоступен; копии `ags._bak2606_*_1118`  
**Путь:** fn-path (`06`); **04b / 06b не применялись**

| # | Скрипт / шаг | ✓ | Примечание |
|---|--------------|---|------------|
| A.1 | `00_VERIFY_before` (волна 0) | ✅ | `_2605` OK; `_2606` отсутствовал |
| — | `00_SAFETY_bak_before_01` | ✅ | `_bak2606_*_1118` |
| A.2 | perf indexes (+ IX_ra_summ после 01b) | ✅ | |
| A.3 | `01`…`01d1` | ✅ | factDoc + backfill |
| A.4 | `02`…`03d`, `03b1` | ✅ | hotfix `fnStCostFromFd_2606` |
| A.5 | `04`, `05`, `05a`, `05c` | ✅ | |
| A.5b/proc | `05b` CREATE PROCEDURE | ✅ | после FIX zip |
| A.6 | `04b` spFn2 | ⏭ | не в fn-path |
| A.7 | `06` fn-path | ✅ | без `06b` |
| A.10 | `09a`→`09b`→`09c` | ✅ | CHECK gt0 trusted |
| A.8 | `07_VERIFY_after` | ✅ | объекты OK; PBrn −17/−16 vs DEV |
| A.9 | `07_VERIFY_spFn2_schema` | ⏭ | FAIL ожидаемо (нет `04b`) |
| A.11 | `07_VERIFY_spMstrg_2606_chain5` | ✅* | RS1=**15245** RS4=**915**; ~212/220 с; *FAIL скрипта = эталон DEV 15262 |
| — | Smoke P2 Access RA + JAR 156 type 3/6 | ✅ | без инфр. ошибок; АВ idle (Δ=0) |
| — | `02_VERIFY_3new_RA_factDoc` | ✅ | 70072/70073 PASS; 70071 WARN нет ra_summ (Решение 9) |

**Клиенты после окна:** Access + `spMstrg_2605`; JAR **0.1.0.156** — без изменений (**не** 17.5).
