# Диагностика ключей RALP (type=3) на prod — только SELECT

Zip password: `au#LL891`

## Зачем
На prod dry-run дал 1262 NEW + 1217 orphan при 0 match.
На тестовой БД тот же июльский Excel vs март-домен: **420 match, 828 insert, 0 orphan**.
Нужно понять, какое поле ключа ломается на FishEye.

## Порядок в SSMS
1. `SPB-05-NV-SQL1` → БД `FishEye`
2. `00_FIND_LAST_TYPE3_EXEC.sql` — найти `exec_key` с `stg_cnt≈1262`
3. В `01` и `02` заменить `@exec_key = 0` на найденный
4. Выполнить `01_MATCH_SIMULATION.sql`, затем `02_SAMPLE_MISMATCHES.sql`
5. Результаты (grid → CSV/txt или скрин) вернуть в `26-0730_to_prod/`

## Как читать 01
| Показатель | Норма (как на тесте) | Плохо (как prod UI) |
|------------|----------------------|---------------------|
| matched_full_key | ≈420…1248 | **0** |
| would_insert | ≈828 (март→июль) | ≈1262 |
| would_orphan_delete | **0** | ≈1217 |
| num_date_only ≫ full_key | — | ломаются **cst** и/или **og** |

## Важно
- Только чтение. **Не** ставить `adt_AddRA` / apply.
- Access не трогать.
