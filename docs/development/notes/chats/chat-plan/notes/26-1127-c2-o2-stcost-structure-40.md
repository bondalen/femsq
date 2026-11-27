# C2 O2 §4.0.0 — prep: структура затрат (процесс A, CRUD)

**Дата:** 2026-11-27 · **Задача:** 0081 · **План:** §4.0  
**Статус:** ✅ §4.0 закрыт · accept [40-accept](./26-1127-c2-o2-stcost-structure-40-accept.md)  
**Контракт UtPl:** [26-1127-c2-o2-utpl-lim-contract.md](./26-1127-c2-o2-utpl-lim-contract.md)  
**Опора O1 Structure:** `InvestmentStructureView` / `JdbcStIpgStructureDao` (`stnType=1|2`)  
**Access:** `Form_stNetCost` + `stCost*` (зеркало `stNetIpg`; отдельный скрин **не** обязателен)

---

## 1. Два процесса (принято)

| | Процесс A — справочник | Процесс B — планы/лимиты |
|--|------------------------|---------------------------|
| Смысл | Что приложение **знает** о структуре затрат | Привязка **сумм** к пункту `stCost` |
| Access | `stNetCost` / `stCost*` | G3 UtPl / LdM на ИП |
| FEMSQ | **§4.0** (этот блок) | **§4.2** / §6 LdM |
| Выбор сетки `stNet` | UI справочника (список сетей `stnType=2`) | **Нет** — в строку UtPl/`LmMn` пишется только `stcKey` |
| Расчёт по сетке | — | `_2606` / `fnStCost*` с `@stNet` (топология свёртки) |

Хранение lim/UtPl: **`iuplpmStCost` / `ipgplStCost` = `stcKey`**, без FK на cost-net.  
Аналога `ipgcStNetIpg` для затрат (**`ipgcStNetCost`**) **нет**; при появлении >1 cost-net — отдельное решение (атрибут цепи/отчёта), не поле загрузки.

---

## 2. Инвентарь noM6 (`FishEye_prod_noM6`, 2026-11-27)

| Объект | Факт |
|--------|------|
| Сети `stnType=2` | **1**: `stnKey=3`, имя «Стандартная», `stnRoot=214` |
| Сети `stnType=1` (ИПГ) | 5 (для сравнения) |
| `stCost` / `stCostNm` / `stNetPn`@3 | **89** / **153** / **79** |
| Обход | `ags.fnSt(3, 214)` |

### Канон оси C (UtPl / ADR 012)

Прямые рёбра в net=3 (фрагмент):

```text
214  Реализация инвестпроекта в форме стройки   (MIN nm)
 └─ 212  Всего                    stpnNum=1
     ├─ 195  СМР                  stpnNum=1
     ├─ 172  оборудование         stpnNum=2
     └─ 187  Прочие               stpnNum=3
```

Также в net=3 есть ветки **вне** канона UtPl-минимума (напр. `212→215`, `214→213`) — полный DAG справочника; для планов O2 обязательны ключи **212/195/172/187**.

**Отображаемое имя:** `stCostNm` — несколько alias на ключ; в UI как у Structure ИПГ: **`MIN(stcnKey)`** (зафиксировано для §4.0/Leaves; Leaves note §4.4).

| `stcKey` | `MIN(stcnKey)` → `stcnNm` |
|----------|---------------------------|
| 214 | Реализация инвестпроекта в форме стройки |
| 212 | Всего |
| 195 | СМР |
| 172 | оборудование |
| 187 | Прочие |

---

## 3. Scope §4.0 — CRUD сразу (принято)

Не read-only: закрыть процесс A одним заходом (не возвращаться перед §4.2 только ради правки справочника).

### В scope

| Операция | Паритет O1 (`stIpg*`) | Для `stnType=2` / `stCost*` |
|----------|----------------------|-----------------------------|
| Список / дерево сетей | `stIpgNetworks`, `stIpgNetworkTree` → `fnSt` | те же query с типом **2** (или обобщённые `stCost*`) |
| Имена узла | `stIpgNodeNames` / rename / addName | `stCostNm` (`stcnCost`) |
| CRUD сеть | create / rename / clone | create/rename; **clone — да**; 2-я сеть — см. ограничения |
| CRUD узел/ребро | createChild, attach, move, detach, delete | те же; писать `st`+`stCost`+`stCostNm`, не `stIpg*` |
| UI | CardStrip + FemsqTreeList | клон Structure; маршрут «Структура затрат» |

`JdbcStIpgStructureDao` (§4.0.1): create/attach/move/delete для `stnType=1|2`; ветка `stCost`/`stCostNm` vs `stIpg`/`stIpgNm`; GraphQL `stCost*` (`StCostStructureGraphqlController`).

### Вне scope §4.0

| Тема | Решение |
|------|---------|
| Выбор cost-net на загрузке/Leaves UtPl | **Нет** (процесс B) |
| Excel-reconcile схемы затрат (как ImpIpg Structure) | **Хвост** ☐ — не блокер §4.2 |
| `ipgcStNetCost` / multi-net mastering | **Backlog** до появления 2-й сети в проде |
| Скрин Access `stNetCost` | **Не обязателен** |
| Разбор G3 UtPl форм | **§4.1** (потребители `stcKey`), не CRUD справочника |

### Ограничения / охрана канона

1. При create/attach/detach/move/delete, затрагивающих **212/195/172/187** или ребро `212→{195,172,187}` — **предупреждение** в UI (и лог); не молча ломать тройку.  
2. **Минимум канона (уточнение 2026-11-27):** 212 присутствует и ≥1 составляющая связана ребром `212→часть`. Сумма «равна общему», даже если состоит из **одной** составляющей при отсутствии двух других. Полная тройка 195+172+187 — желательна, не обязательна для `satisfied`.  
3. Создание **второй** сети `stnType=2` в справочнике (§4.0) — **допустимо** как capability справочника. На расчёт влияет только после **0096** (разведение `@stCostNet`); UtPl по-прежнему пишет только `stcKey`. Продуктовый rollout второй боевой сети — не цель O2.  
4. После опасных правок канона — рекомендация smoke `_2606` `@stCostKey` ∈ {NULL,212,195,172,187} на пилотной цепи (не блокер commit UI).  
5. ~~**C2 §4.0.1+ ⏸** до DoD 0096~~ — **снято** (0096 ✅ 2026-11-27).

---

## 4. DoD §4.0

1. Оператор открывает справочник затрат, видит net=3 от root **214**, канон **212/195/172/187** с именами.  
2. Может CRUD: сеть (в рамках ограничений), узлы, alias-имена, рёбра — паритет Structure ИПГ.  
3. UtPl/load **не** требует выбора сетки.  
4. Excel-reconcile затрат не обязателен для закрытия §4.0.

---

## 5. WBS (после prep)

| # | Шаг | Содержание | Статус |
|---|-----|------------|--------|
| **4.0.0** | Prep | этот note | ✅ |
| **4.0.1** | GraphQL + DAO | `stCost*` query/mutation; Nm → `stCostNm`; снят hard-reject type≠1 | ✅ |
| **4.0.2** | UI | экран «Структура затрат» + баннер/confirm канона (минимум = Σ присутствующих) | ✅ |
| **4.0.3** | Приёмка справочника | CRUD smoke на DEV; дерево = `fnSt(3,214)` | ✅ |
| → | **§4.1** | Access G3 UtPl → migrate | ☐ next |
| → | **§4.2** | запись LmMn / UtPlP + DoD денег | ☐ |

### §4.0.1 — сделано (2026-11-27)

- DAO: `JdbcStIpgStructureDao` — `ST_TYPE_COST=2`; create через `stCost_insert`; Nm/delete ветвятся по `st.stType`.
- GraphQL: `stCostNetworks` / `stCostNetworkTree` / `stCostNodeNames` + mutations CRUD (паритет `stIpg*`).
- Контроллер: `StCostStructureGraphqlController`.

### §4.0.2 — сделано (2026-11-27)

- UI: `CostStructureView` · nav «Структура затрат» · API/store `st-cost-structure*`.
- Канон: `domain/cost-structure-canon.ts` — `satisfied` = 212 + ≥1 из {195,172,187}; confirm при правках, ломающих минимум.
- Без Excel-сверки (процесс A только).

### §4.0.3 — сделано (2026-11-27)

- Accept note: [26-1127-c2-o2-stcost-structure-40-accept.md](./26-1127-c2-o2-stcost-structure-40-accept.md).
- Smoke: `StCostStructureSmokeMain` — net=3/214, канон 3/3, CRUD+cleanup PASS.

---

## 6. Next

**§4.1** — Access G3 UtPl → migrate.
