# B1 apply result (2026-08-26)

**GO:** владелец `GO B1`  
**Backup:** `/mnt/d/Backups/femsq/database/manual/FishEye_20260826_100908_pre-B1-DbtValue-M2.bak` (143M)

## SQL

Исправления черновика перед успехом: `COL_NAME`→`COL_LENGTH`; `GO` после `ADD dvInvDbt`.

| Шаг | Результат |
|-----|-----------|
| 00_VERIFY_before | 16/16 one_slot, dup=0 |
| 01 sudz | `dvInvDbt` NOT NULL; `dvDbt` dropped |
| 02 test_sudz | зеркало |
| 03 trigger | sudz + test_sudz |
| 04 view | fact **16** / **16** |
| 99 verify | UX + triggers OK |

## App

| | |
|--|--|
| JAR | `femsq-web-0.1.0.217-SNAPSHOT` (fat + thin) |
| Backend | `:8080` up |
| Vite | `:5175` up |

## Smoke vs P2 baseline

| Check | Result |
|-------|--------|
| sums new (70525000.01) | **8** (`dvInvDbt=8201`, `dbtKey=82`) |
| `dv.invDbt` from dvKey=1 | → idKey **8201** |
| `invDbt.dv` from 8201 | **8** Values |
| fact | **16** |
| GQL `sudzD644(900/805)` | **2** rows |
| REST d644/svod/rslt xlsx (901/903) | **200** |

Next: **B1b / Value-in-calm / A2** (не писать `Dbt`/`invDbtDbt` в воронке).
