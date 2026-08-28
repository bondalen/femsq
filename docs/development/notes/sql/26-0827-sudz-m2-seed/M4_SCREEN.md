# M4 — экран двоящих + чекбокс 7 (seeded)

**Дата:** 2026-08-27  
**JAR:** `0.1.0.226-SNAPSHOT`  
**Cutover:** §G / S74 M4 · сегм. 22 / 20

## Scope

Доработка UI/регламента на **заполненной** новой структуре после M2+M3.  
**Не** писать `Dbt` / `invDbtDbt` на экране и на чекбоксе 7 (остаётся C1 → M5).

## Сделано

| # | Тема | Суть |
|---|------|------|
| 1 | Old sums `ciaName` | `findOldSumMatches` JOIN `cnInvAccnt`; GQL + FE колонка (экран двоящих и КСДСФ) |
| 2 | Деревья сумм | Как КСДСФ: таблица + `RelationTree` (`ksdsf-cid-sum` / `ksdsf-dv-sum`) |
| 3 | Live messages | Панель «Сообщения»: `[queue.build]` + `[row.select]` (слоты, old/new counts, ciaName) |
| 4 | Refresh | После Create/Link/var — `reloadQueue(ciudKey)` + re-select |
| 5 | Сегм. 22 | Регламент оператора на seeded кейсах (ниже); defer/bulk — вне M4 |

## Регламент оператора (сегм. 22, UI)

1. Открыть лаунчер → upl → вкладка двоящих / экран «Разбор…».
2. Строка **без var** (`ambiguous`) → **Create var** (кандидаты) → затем Create/Link.
3. Строка **multi** с var:
   - если Excel-сумма **уникально** совпадает с историей `DbtValue` одного слота на `iKey` → **Link** к этому `idKey`;
   - иначе сверка old (`ciaName`) / new trees → Link или **Create слот** (без `Dbt` до C1).
4. Цель строки: слой I + **`DbtValue` на текущий upl** → строка уходит из open при rebuild.
5. Чекбокс 7 (`invDbtLoad`): calm + F1; очередь — хвост для экрана.

## UAT DEV (upl 910)

| Кейс | Наблюдение | Действие UAT |
|------|------------|--------------|
| `iKey=329` · ciud **2443** · debt 30404.4 · multi+var | 2 слота (42/`ciaName=1`, 43/`2`); сумма **не** в истории Value → нужен ручной выбор | осмотр / без мутации в smoke |
| `iKey=12032` · 7 Excel · multi+var | у каждой строки **уникальный** sum→слот (4405…4399) | **Link** ciud **2446** → idKey **4405**; Value на 910 |
| ambiguous open | ~большинство open без `ciudIdvvKey` | Create var — вручную / отдельно |
| `invDbtLoad` dry | `flLoad=false` | без новых Value; очередь стабильна |

### Link smoke (факт)

`linkSudzInvDbtDouble(2446, 4405)`:

- `ciudStatus` = `created`, `ciudCreatedIdKey` = 4405;
- `DbtValue` dvKey **43997** (`dvInvDbt=4405`, `dvUpl=910`, `dvTtl=186961.48`);
- Values на 910: **1630** (=1629+1); open после dry rebuild: **124**.

### Чекбокс 7 dry

Префикс до `invDbtLoad`, `flLoad=false`: `values=0`, `queued=124`, `stub=false`.

## Out of M4

- Defer / bulk ETL / «Create вслепую» как канон.
- F1 на уже открытых multi с уникальной суммой (хвост rebuild) — опционально позже.
- C1 / `Dbt` на 7 — **M5**.

## Next

**M5** — остальные чекбоксы воронки.
