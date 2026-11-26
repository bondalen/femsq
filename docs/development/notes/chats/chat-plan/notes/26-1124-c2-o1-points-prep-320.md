# §3.2.0 Prep — загрузка пунктов из staging (ИП A / load8)

**Дата:** 2026-11-24  
**lastUpdated:** 2026-11-25  
**Задача:** 0081 · план C2 **§3.2.0–3.2.3**  
**Стенд:** `FishEye_prod_noM6` · JAR `0.1.0.396-SNAPSHOT`  
**Контракт:** [26-1124-c2-o1-excel-load-contract.md](./26-1124-c2-o1-excel-load-contract.md) §5.6–5.7  
**ipgpSh:** [26-1123-c2-o1-prod-delta-requirements.md](./26-1123-c2-o1-prod-delta-requirements.md) §5.2  
**Пилот A:** ipg **27**, load **8**, stNet **5**, Excel `sql_0.xlsx`

---

## 1. Staging `ags.impIpg` (фактические колонки)

| Колонка | Тип | Роль для пунктов |
|---------|-----|------------------|
| `iiKey` | int PK | id строки staging |
| `iiLoad` | int | FK `impIpgLoad` |
| `iiRowNo` | int | номер строки Excel |
| `iiRowKind` | char(1) | `S` раздел / `L` лист-стройка |
| `iiText` | nvarchar(500) | для L — имя стройки (из кол. C) |
| `iiParent` | int NULL | **id раздела-родителя в staging** (`iiKey` S), не sti |
| `iiStiKey` | int NULL | на L **не пишется** парсером; на S — после сверки |
| `iiCtx` | nvarchar(max) JSON | поля листа + path |

Отдельных колонок сумм/`cstAgPn` в таблице **нет** — всё в `iiCtx`.

### 1.1 JSON `iiCtx` для L (парсер)

Ключи: `sheet`, `excelRow`, `path[]`, `cstAgPn`, `nnn?`, `name?`, `ttl?`, `work?`, `equip?`, `others?`, `commissioning?`.

Пример (load8, row 10):

```json
{"sheet":"Приложение № 1 ","excelRow":10,"path":["План капитального строительства","Приоритетные проекты","Проекты развития","Обустройство Чаяндинского м/р и МГ «Сила Сибири»"],"cstAgPn":"051-2000860","nnn":"1","name":"Обустройство Чаяндинского НГКМ","ttl":16423.18,"work":12420.5,"equip":3202.03,"others":800.65,"commissioning":"16 газ.скв."}
```

Колонки Excel (A…H) → парсер: `nnn`/`№`, код `cstAgPn`, наименование, ttl/work/equip/others, commissioning.  
**Нет в парсере:** `ipgpSmAgFee`, `ipgpCostAdjust`, `ipgpSmReserv`, `ipgpSh` (схема — алгоритмом §5.2).

---

## 2. Домен `ags.ipgPn` ↔ Leaves API

| `ipgPn` | CreateIpgPnInput | Источник из staging |
|---------|------------------|---------------------|
| `ipgpIpg` | ✅ | load→`ipg` (A=27) |
| `ipgpNum` | ✅ optional | `iiCtx.nnn` |
| `ipgpCstAgPn` | ✅ **int FK** | lookup `cstAgPn.cstapIpgPnN` = `iiCtx.cstAgPn` |
| `ipgpSh` | ✅ | §3.2.3 / §3.7 (prev-IP / else **2**) |
| `ipgpSmTtl/Wrk/Equ/Oth` | ✅ | `iiCtx.ttl/work/equip/others` |
| `ipgpTskCms` | ✅ | `iiCtx.commissioning` |
| `ipgpSmAgFee` | ✅ | **нет в годовом листе** → null |
| `ipgpCostAdjust` | ✅ | **нет** → null |
| `ipgpSmReserv` | ✅ | **нет** → null |

`ipgStPn`: GraphQL уже есть — `addIpgPnStructure` / `setIpgPnStructure`.  
CRUD пункта: `createIpgPn` / update / delete (cascade StPn; forbid UtPl).

**Нет:** bulk apply из `impIpgLoad`; gate-mutation; resolve `cstAgPn` по коду; сервис наследования L←S.

Справочник схем на noM6: `ipgSh` **1…4** (4 = «Не определена») — ✅.

---

## 3. Объём load8 (ИП A)

| Метрика | Значение |
|---------|---------:|
| S (разделы) | 39, все с `iiStiKey` |
| L (листья) | **398** |
| L с `iiParent` | 398 (0 null) |
| L, у родителя S есть `iiStiKey` | **398 / 398** (`lBad=0`) |
| Уникальные `iiCtx.cstAgPn` | 398 (дублей кода в файле **0**) |
| Уже `ipgPn` на ipg=27 | **0** (чисто для smoke) |
| `iiStiKey` на L | все NULL (ожидаемо) |

Наследование sti для A **готово по данным**: каждый L → parent S → sti.

Полнота опциональных сумм в ctx (из 398): нет `commissioning` у 259; `work` 80; `equip` 45; `others` 25 — допустимо (null).

---

## 4. Gaps (блокеры следующих подпунктов)

| # | Gap | Куда |
|---|-----|------|
| G1 | ~~Нет сервиса/GraphQL **gate**~~ → ✅ `impIpgPointsGate` / `ImpIpgPointsGateService` (JAR 397) | §3.2.1 ✅ |
| G2 | ~~Нет проставления/проверки **sti на L** из S~~ → ✅ `impIpgStiInherit` / `ImpIpgStiInheritService` (резолв L←S без записи `iiStiKey`) | §3.2.2 ✅ |
| G3 | ~~Нет резолвера **`ipgpSh`**~~ → ✅ `impIpgShResolve` / `ImpIpgShResolveService` (§5.2) | §3.2.3 ✅ |
| G4 | ~~Нет bulk `impIpg`→`ipgPn`+`ipgStPn`~~ → ✅ `applyImpIpgPoints` / `ImpIpgPointsApplyService` (TX) | §3.2.4 ✅ |
| G5 | ~~92 кода нет на noM6~~ → ✅ догружены с прода (`26-1125_09-50`): +3 `cst`, +24 `cstAg`, +92 `cstAgPn`; load8 lookup **398/398** | §3.2.4 prep ✅ |
| G6 | ~~UI «Загрузить пункты»~~ → ✅ кнопка на Structure + dryRun/commit | §3.2.5 ✅ |
| G7 | Поля AgFee/CostAdjust/Reserv не парсятся — ок для этапа 1 (null) | зафиксировать |

Образец отсутствующих кодов (chunk0): `023-3000860`, `057-3002160`, `001-3000010`, `040-2005400`, … — рядом часто есть `051-2…` с тем же хвостом объекта.

---

## 5. Вывод Prep

- Staging + парсер **достаточны** по форме для A: L↔S, JSON полей → почти полный `CreateIpgPnInput`.  
- Leaves CRUD **достаточен как примитив**; нужен оркестратор load→bulk.  
- ~~Критичный пробел данных noM6~~ → закрыт G5 (398/398 lookup).  
- Дублей `cstAgPn` в sql_0 нет → ветка «N схем на один код» на smoke A не стреляет (проверить на B/D в §3.4).

**DoD §3.2.0:** ✅ инвентарь и gaps зафиксированы.

### §3.2.1 Gate (2026-11-24)

- `DefaultImpIpgPointsGateService.evaluate` / `assertReady`
- GraphQL query `impIpgPointsGate(loadKey)`
- Smoke: load**8** → `ready=true`, sections=39, open=0, stNet=5
- Unit: `DefaultImpIpgPointsGateServiceTest`

### §3.2.2 Наследование sti L←S (2026-11-25)

- `DefaultImpIpgStiInheritService.evaluate` / `assertReady` — sti листа = `iiParent`→S.`iiStiKey`; `iiStiKey` на L **не пишется** и **не читается**
- Дыры: `NO_PARENT` / `PARENT_MISSING` / `PARENT_NOT_SECTION` / `PARENT_STI_MISSING` → `ready=false`; `assertReady` → `DaoException`
- GraphQL query `impIpgStiInherit(loadKey)` — счётчики + список `holes` (без 398 ready-строк)
- Smoke SQL load**8**: leaf=398, ready=398, hole=0
- Unit: `DefaultImpIpgStiInheritServiceTest`

### §3.2.3 Резолв ipgpSh (2026-11-25)

- `DefaultImpIpgShResolveService.evaluate` / `assertReady` — notes O1 §5.2; **без** записи в `ipgPn`
- 1× код: ровно 1 схема в prev → её (`FROM_PREV`); иначе → **2** (`DEFAULT_4` в API = default, ключ 2; §3.7)
- N>1: N различных схем (prev, затем свободные `ipgSh`); нехватка → `NO_FREE_SCHEMES`
- Ошибки: `MISSING_CSTAGPN`, `UNIQUE_CSTAGPN_SH`
- GraphQL query `impIpgShResolve(loadKey, previousIpgKey)`
- Smoke load**8**: no-prev → 398×4 ready; vs prev **17** → fromPrev≈202 / default4≈196 (дублей кода в sql_0 нет)
- Unit: `DefaultImpIpgShResolveServiceTest`

### §3.2.4 Bulk apply (2026-11-25)

- `DefaultImpIpgPointsApplyService.apply(load, previousIpgKey, dryRun)` — gate → stiInherit → shResolve → `cstAgPn` lookup → TX `ipgPn`+`ipgStPn`
- Без sti / missing code / unique `(ipg,cstAgPn,sh)` / повторный apply на непустую ИП → ERROR
- `IpgLeavesDao.bulkCreatePnsWithSt` — одна транзакция; `CstAgPnDao.findByCodeExact`
- GraphQL mutation `applyImpIpgPoints(loadKey, previousIpgKey, dryRun)`
- Smoke load**8** → ipg**27**: dryRun 398 ready; commit 398 pn + 398 stPn; all `ipgpSh=4`; unique viol=0; pn без sti=0
- Unit: `DefaultImpIpgPointsApplyServiceTest`; smoke main `ImpIpgPointsApplySmokeMain`

### §3.2.5 UI «Загрузить пункты» (2026-11-25)

- Structure: кнопка **Загрузить пункты** + поле prev ИП (`ipgpSh`)
- Поток: dryRun → отчёт → confirm → commit (`applyImpIpgPoints`)
- API/стор: `imp-ipg-load-api.applyImpIpgPoints` · `st-ipg-structure.applySelectedPoints`

### §3.2.6 Smoke A (2026-11-25)

- См. [26-1125-c2-o1-points-smoke-a-326.md](./26-1125-c2-o1-points-smoke-a-326.md): 398/398, unique=0, sh=4, ttl match

### §3.2.7 Partial apply (2026-11-25)

Целевой UX (владелец): кнопка «Загрузить пункты» не валит весь проход из‑за дыр в справочнике/sti/sh.

| Было (§3.2.4 пилот) | Стало (§3.2.7) |
|---------------------|----------------|
| Любая ошибка → 0 записей | Ошибка строки → лог + skip; остальные пишутся |
| Одна TX на все листья | TX на 1 лист: `createPnWithSt` (ipgPn+ipgStPn) |
| Повтор на непустой ИП запрещён | Unique уже есть → `skippedAlreadyCount` (не ошибка) |
| dryRun→confirm обязательно | dryRun опционален; UI один клик — §3.2.7.3 |
| `ready=false` = ничего не сделано | `applied>0` при `errors≠∅` — частичный успех |

#### §3.2.7.1–.2 Сервис (✅ 2026-11-25)

- `DefaultImpIpgPointsApplyService`: soft gate; per-leaf skip+лог; hard fail только нет load/ipg/`ipgStRlSh`
- `IpgLeavesDao.createPnWithSt` + GraphQL/DTO `skippedAlreadyCount`
- Unit: dryRun / commit / idempotent skip / partial CSTAGPN_MISSING / soft-open / hard ipgStRlSh
- Контракт §5.8

#### §3.2.7.3 UI (✅ 2026-11-25)

- Structure: **Загрузить пункты** = один клик commit; **Проверить** = dryRun
- Панель: applied / skippedAlready / полный список errors (scroll)

#### §3.2.7.4 Smoke (✅ 2026-11-25)

- См. [26-1125-c2-o1-points-smoke-3274.md](./26-1125-c2-o1-points-smoke-3274.md): A skipped=398; B applied=576 / errors=45 CSTAGPN

**Next:** §3.4 🔶 — C/D applied; [acceptance-34](./26-1125-c2-o1-acceptance-34.md); ждём отПрод 73 кодов.
