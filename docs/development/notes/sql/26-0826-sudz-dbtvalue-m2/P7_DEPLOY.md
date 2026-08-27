# P7 — стратегия выкладки B1 «без окна поломки»

**Дата:** 2026-08-26  
**Машина:** nb-win · Docker `femsq-mssql`  
**Предусловие:** B1-prep P0–P6 ✅; гейт **P9 GO** от владельца.

## Порядок (жёсткий)

| # | Шаг | Кто / чем | Критерий |
|---|-----|-----------|----------|
| 0 | Остановить backend `:8080` и Vite `:5175` (или не трогать UI до шага 3) | вручную | нет запросов к `DbtValue` / RelationTree / sums во время DDL |
| 1 | Повтор `00_VERIFY_before.sql` | DBHub / sqlcmd | sudz+test_sudz: one_slot = all, dup = 0 |
| 2 | Apply SQL: `01` → `02` → `03` → `04` | пакет `26-0826-sudz-dbtvalue-m2/` | без ошибок; колонка `dvInvDbt`, нет `dvDbt` |
| 3 | `99_VERIFY_after.sql` | SELECT | UX, триггер, fact count ≈ baseline 16 |
| 4 | Сборка JAR с патчем P6 + рестарт backend | `./code/scripts/check-fequlib.sh` → `build-thin-jar.sh` (версия +1) | health `/api/v1/connection/*` OK |
| 5 | Frontend (если не из JAR) | `npm run build` / `dev` в `femsq-frontend-q` | нет запросов поля `dvDbt` |
| 6 | Smoke = повтор **P2a–P2e** vs [P2_BASELINE](./P2_BASELINE.md) | UI + SQL | очередь 910; sums new; hints; деревья `dv.invDbt`; D644/Rslt xlsx |

## Запреты

- **Не** оставлять работающий JAR **до** P6 на БД **после** B1 (SQL error на `dvDbt`).
- **Не** выкладывать JAR P6 на БД **до** B1 (SQL error на `dvInvDbt`).
- Окно «SQL уже M2, app ещё старый» — только минуты между шагами 2 и 4; UI лучше выключен.
- Seed-файлы репо (`09`/`17`) **не** трогать в B1 → **B2**.

## Откат при сбое

См. [P8_ROLLBACK.md](./P8_ROLLBACK.md): restore `.bak` **или** пересоздать схему из `26-0807-*` + воронка 910. После отката БД — вернуть JAR **без** P6 (git checkout предыдущего билда / ветки).
