# §3.2.0 Prep — загрузка пунктов из staging (ИП A / load8)

**Дата:** 2026-11-24  
**lastUpdated:** 2026-11-24  
**Задача:** 0081 · план C2 **§3.2.0**  
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
| `ipgpSh` | ✅ | §3.2.3 (prev-IP / else **4**) |
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
| G2 | Нет проставления/проверки **sti на L** из S (сейчас только join-ready) | §3.2.2 |
| G3 | Нет резолвера **`ipgpSh`** | §3.2.3 |
| G4 | Нет bulk `impIpg`→`ipgPn`+`ipgStPn` | §3.2.4 |
| G5 | **Lookup `cstAgPn` по коду:** exact `cstapIpgPnN` — **306/398** (≈77%); **92** кода из sql_0 **нет** в `ags.cstAgPn` на noM6 (часто агентские `0xx-3…`). Без стратегии apply упрётся в ERROR | §3.2.4 (+ возможно справочник / §3.3) |
| G6 | UI «Загрузить пункты» | §3.2.5 |
| G7 | Поля AgFee/CostAdjust/Reserv не парсятся — ок для этапа 1 (null) | зафиксировать |

Образец отсутствующих кодов (chunk0): `023-3000860`, `057-3002160`, `001-3000010`, `040-2005400`, … — рядом часто есть `051-2…` с тем же хвостом объекта.

---

## 5. Вывод Prep

- Staging + парсер **достаточны** по форме для A: L↔S, JSON полей → почти полный `CreateIpgPnInput`.  
- Leaves CRUD **достаточен как примитив**; нужен оркестратор load→bulk.  
- Критичный пробел данных noM6: **~23% кодов SАК нет в `cstAgPn`** — решить до/в §3.2.4 (ERROR list vs догрузка справочника vs map).  
- Дублей `cstAgPn` в sql_0 нет → ветка «N схем на один код» на smoke A не стреляет (проверить на B/D в §3.4).

**DoD §3.2.0:** ✅ инвентарь и gaps зафиксированы.

### §3.2.1 Gate (2026-11-24)

- `DefaultImpIpgPointsGateService.evaluate` / `assertReady`
- GraphQL query `impIpgPointsGate(loadKey)`
- Smoke: load**8** → `ready=true`, sections=39, open=0, stNet=5
- Unit: `DefaultImpIpgPointsGateServiceTest`

**Next:** §3.2.2 наследование sti L←S.
