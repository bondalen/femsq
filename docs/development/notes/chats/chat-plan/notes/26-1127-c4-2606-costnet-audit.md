# §0: аудит P-2026-11-27-002 — cost-net ≠ IPG-net

**Дата:** 2026-11-27  
**План:** [chat-plan-26-1127-c4-2606-costnet-correctness.md](../chat-plan-26-1127-c4-2606-costnet-correctness.md) · задача **0096**  
**Стенд:** `FishEye_prod_noM6`  
**Дефект:** `P-2026-11-27-002`

---

## 1. Repro (подтверждено на noM6)

| Проверка | Результат |
|----------|-----------|
| `stNet` inventory | `stnType=1` → 1,2,4,5,6 (IPG); **`stnType=2` → только 3 «Стандартная»** |
| `fnStDownAll(2, 212)` | **0** детей |
| `fnStDownAll(3, 212)` | **72** детей |
| `ipgUtPlPnLmMn` для `iuplpmPlPn=7226` | нет строк `stcKey=212`; есть части (в т.ч. mn=4: 148+187) |
| `fnStCostUtPlPMn(7226, 212, **2**, 4)` | **0** |
| `fnStCostUtPlPMn(7226, 212, **3**, 4)` | **225000** ₽ (= 0.225 млн; второй ребёнок перекрыт предком в DAG) |

Прямая строка на `stcKey` маскирует баг (ветка `max(iuplpmLim)*1e6` без `fnStDownAll`).

---

## 2. Корень дефекта

В `fnMasteringStIpgStCost_2606` **один** `@stNet`:

1. **IPG-net** — `fnStDownAll(@stNet, @ipgStKey)` для отбора строек по разделам (`ipgStPn`).  
   Default: `ipgCh.ipgcStNetIpg` (часто **2**).
2. **Cost-net** — тот же `@stNet` уходит в `fnMasteringCstAgPnSh_2606` → `fnStCost*` / UtPl rollup.  
   Канон 212→195/172/187 живёт только в сети **`stnType=2`** (сейчас `stnKey=3`).

Исторически Решение 1 в `03-design-decisions.md` зафиксировало `ipgcStNetIpg` как источник `@stNet` для DAG разделов — без разведения с cost-rollup.

---

## 3. Карта проводки (где кормится IPG-net в cost-path)

### Главный choke-point (патч H1+H2)

| Объект | Роль `@stNet` | Действие |
|--------|---------------|----------|
| `fnMasteringStIpgStCost_2606` | 4-й param → и DAG разделов, и `CstAgPnSh` | **Развести:** `@stNetIpg` + `@stCostNet`; default cost = `stnType=2` |
| `fnIpgChRsltCstUtl2_2606` / `spIpgChRsltCstUtl2_2606` | `StIpgStCost(..., NULL)` | Протянуть optional `@stCostNet` |
| `spMstrg_2606` | нет `@stNet` / `@stCostNet` | Добавить optional `@stCostNet` (capability T3–T5) |

### Уже разделены по имени (но значение может быть IPG)

| Объект | Параметр | Заметка |
|--------|----------|---------|
| `fnStCostRsCstAgPn_2606` | `@stCostNet` | Имя верное; `ipgcStNetIpg` используется **только** для `fnStUpAll` по **разделам** `ipgStPn` — это корректно |
| `fnStCostRsIpgPn_2606` | `@stNet` | Семантика = cost-net; получает то, что передали сверху |
| `fnStCostUtPlPMn` / `fnStCostUtPlP` / `fnStCost*_2606` | `@stNet` | Leaf rollup; правильная сеть должна прийти с mastering |

### Корректно оставляем на IPG-net (не трогать)

| Объект | Зачем `ipgcStNetIpg` |
|--------|----------------------|
| `fnIpgChContractsForStIpg_2606` | отбор контрактов по дереву **разделов** ИП |
| DAG-фильтр в `fnMasteringStIpgStCost` (часть 1) | то же |
| `fnStCostRsCstAgPn` → `fnStUpAll(ipgcStNetIpg, ipgspSt)` | принадлежность пункта к разделу |

### Скрипты приёмки (хардкод `@stNet = ipgcStNetIpg` в cost-вызовах)

Требуют смены default на cost-net (или явный `stnKey=3` / lookup `stnType=2`):

- `07m_plan_limit_conformance_chain5.sql`, `07m_plan_additive_chain5.sql`
- `07n_plan_strict_cst_chain5.sql`, `07o_plan_17dates*.sql`, `07p_plan_aggregate_chain5.sql`
- `07i_COMPARE_stCost_additive_chain5.sql`, `07j_COMPARE_stCost_fact_additive_chain5.sql`
- профили `07h3` / `07h4` / `07h6`, `07e1` (факт через cost-net)

### Java / GraphQL

Вызовов `spMstrg_2606` / mastering с `@stNet` в коде FEMSQ **нет**. `ipgcStNetIpg` в DAO — атрибут цепи (IPG-net), не cost-rollup.

---

## 4. Целевая семантика (H1+H2)

```text
@stNet     ← ISNULL(param, ipgCh.ipgcStNetIpg)   -- только разделы ИП (имя param сохранено)
cost-net   ← (SELECT TOP 1 stnKey FROM stNet WHERE stnType=2
              ORDER BY CASE WHEN stnName=N'Стандартная' THEN 0 ELSE 1 END, stnKey)
              -- сейчас 3; передаётся в fnMasteringCstAgPnSh_2606
```

**Сигнатура:** 4 param (как было). TVF в `FROM` **не** принимает omit default → 5-й `@stCostNet` ломал бы `fn2`/`sp` без полной перепрошивки PercentBrn.  
Явный `@stCostNet` для capability (§3): `fnMasteringCstAgPnSh_2606` / `fnStCostUtPlPMn` / leaf `fnStCost*`.

- UtPl пишет только `stcKey`; выбора сетки в UI нет.

---

## 5. Статус apply (2026-11-27)

| БД | `03d` H1+H2 (body, 4 param) |
|----|------------------------------|
| `FishEye_prod_noM6` | ✅ |
| `FishEye` (СУДЗ) | ✅ (тот же объект; откат 5-param → 4-param body) |

---

## 6. Следующий шаг

§1 хвост: правка 07* defaults (`@stNet=ipgcStNetIpg` → cost-net для cost-вызовов); §2 приёмка 7226 + smoke @507.
