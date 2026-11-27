# C2 §6 — LdM / Monf: уточнение планов из Excel (G2)

**Дата:** 2026-11-27 · **Задача:** 0081 · **План:** §6  
**Статус:** 🔶 §6.1–6.6 ✅; compare → §6.7+  
**Контракт O1 (имена):** [excel-load §1–2 / §6](./26-1124-c2-o1-excel-load-contract.md)  
**Access map:** [template-study §Access LdM](./26-1127-c2-o2-utpl-template-study.md#access-ldm-какие-поля-excel-реально-читаются-2026-11-27)  
**O2 UI (ручной):** [utpl-lmmn-42](./26-1127-c2-o2-utpl-lmmn-42.md)  
**Образцы Excel:** `/mnt/nb-win-share/femsq/excel/2026-1127/ipg-utpl-26-III/`

---

## 1. Цель

Аналог Access `Form_ipg>LdM_t`: помесячный Excel агента → `ipgUtPl` / широкие `ipgUtPlP` (семантика **212**) + сравнение сумм с `ipgpSmTtl`/`ipgPnLim`.  
**Не** годовая ИП (O1). Группа планов — только на цепи (`ipgcr*UtPlGr`).

---

## 2. Access → FEMSQ (migrate)

| Access | FEMSQ | Решение |
|--------|-------|---------|
| `ipgLdM` сессия | `impIpgLoad` (уже есть) или контекст ИП | **U** — переиспользовать load ИП |
| `ipgLdM_f` файл | **`impIpgLoadMonf`** | **P** — новая таблица |
| `ipgLdm_fSh` диапазоны схем | дети Monf (позже) | **P** §6.5 |
| `ipgLdm_fShCst` найденные объекты | staging parse (позже) | **P** §6.5–6.6 |
| Write `ipgUtPlP` M/Q/Lim (212) | тот же + sync LmMn@212 через O2 util | **P+U** §6.6 |
| C@195/172/187 из Excel | вне Access LdM | **X** — UI O2 / будущий парсер PART |
| Филиал | не читается | **X** (013) |
| `ipgLdM*_rslt*` / compare | отчёт G-ip / Sm vs Lim | **P** §6.7 |
| `impNewSumCompare` (цепь) | отдельно | **A**/backlog |
| VBA Filter / COM Excel | Apache POI + конфиг якорей | **U** |

**MVP write-path (когда §6.6):** TOTAL@212 → `UtPlP` + `upsert` LmMn@212 (AggAxis/FemsqMoney). PART C — не из LdM.

---

## 3. WBS

| # | Шаг | Статус |
|---|-----|--------|
| 6.1 | Inventory Access + migrate | ✅ |
| 6.2 | Контракт Monf + non-goals | ✅ (этот note) |
| 6.3 | DDL `ags.impIpgLoadMonf` (DEV + MSSQL2012) | ✅ noM6 `OBJECT_ID=205217223` |
| 6.4 | GraphQL CRUD Monf + UI вкладка «Загрузка ут. планов» | ✅ smoke create/update/delete |
| 6.5 | Parse skeleton (якоря/лист/quarter) → staging | ✅ 014 smoke |
| 6.6 | Apply → UtPlP + LmMn@212 | ✅ 014 smoke 32/32 |
| 6.7 | Sum compare / G-ip на загруженном наборе | ☐ ← next |
| 6.8 | HTML-лог + polish UI | ☐ |

---

## 4. `ags.impIpgLoadMonf` (каркас)

| Колонка | Смысл |
|---------|--------|
| `iilmKey` | PK |
| `iilmLoad` | FK → `impIpgLoad` |
| `iilmUtPl` | FK → `ipgUtPl` (nullable до привязки) |
| `iilmNm` | имя |
| `iilmFilePath` | путь Excel |
| `iilmSheet` | лист |
| `iilmLimColumn` | якорь Find текста колонки лимита |
| `iilmQuarter` | 1=16 чисел (Q+M), 0=12 M |
| `iilmSumFirst` | смещение первой суммы от колонки лимита |
| `iilmNote` | заметка |
| `iilmCreated` | дата |
| `iilmResults` | HTML-лог (как `iilResults`) |

SQL: `docs/development/notes/sql/26-1127-imp-ipg-load-monf/`

**Код:** `JdbcImpIpgLoadMonfDao` · `ImpIpgLoadMonfService` · `ImpIpgLoadMonfGraphqlController` · FE `imp-ipg-load-monf-api.ts` / store / вкладка `load-utpl`.

**GraphQL:** `impIpgLoadMonfs` / `impIpgLoadMonfsByLoad` / `create|update|deleteImpIpgLoadMonf`.

**Smoke CRUD (2026-11-27, noM6):** create id=1 @load=11 → update → delete → recreate id=2 «LdM demo 014».

---

## 4.1 §6.5 Parse skeleton

**Код:** `IpgMonfExcelParser` · `ImpIpgLoadMonfParseService` · mutation `parseImpIpgLoadMonf` · UI «Разобрать».

Якоря Access: код (`Код стройки`/…) + `limColumn` (подстрока) + `quarter`/`sumFirst`; маска `NNN-NNNNNNN`; отсев имён ∈ `ipgCostItsNmAll`; Round(8). Staging **только в ответе** (+ HTML → `iilmResults`); без apply / без `fSh`.

**Smoke 014** (`2026_sql`, limColumn=`по итогам`, sumFirst=2, quarter=true):  
codeCol=6 · limCol=11 · **hits=301 · loaded=32 · skipped=269**.

---

## 5. Non-goals (сейчас)

- Полный POI-парсер всех агентов 014/051/060 (051 flat / 060 — позже)  
- Авторазнесение C@stCost из Excel  
- ПИР-файл · филиал multi · `копейки`  
- 20×`801/901/905` (вне скоупа)  
- Persist staging-таблица (достаточно ответа до §6.6)

---

## 4.2 §6.6 Apply

**Код:** `ImpIpgLoadMonfApplyService` · `IpgUtPlService.applyTotalMonths212` · mutation `applyImpIpgLoadMonf` · UI «Проверить»/«Применить».

Матч: Access `код+SmTtl`; fallback **уникальный код на ИП** (Excel limYear ≠ `ipgpSmTtl` типично). Пишет только **212** (PART C не из LdM); wide M/Q/Lim; AggAxis STRUCT.

**Smoke:** utPl=205 @ipg=30 · dryRun 32/32 · apply 32/32 · UtPlP=16 · LmMn@212=106. Повтор кода в Excel → last-write-wins на один `ipgPn` (без `fSh`).

---

## 6. Next

**§6.7** — sum compare / G-ip на загруженном наборе (Sm vs Lim).
