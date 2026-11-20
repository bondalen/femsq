# §2.2 VBA / классы / таблицы — G4 Structure + G1 Leaves (узкий проход A)

**Дата:** 2026-11-20  
**План:** [chat-plan-26-1120-c2-d11-ipg-plans.md](../chat-plan-26-1120-c2-d11-ipg-plans.md) §2.2  
**Задача:** 0081  
**Метод:** сначала Structure (`stNetIpg` / `stIpg*` / `fnSt`), затем кратко Leaves (`ipg*` / цепи).  
**Связано:** [UI 2.1](./26-1120-c2-access-ui-g1-g4-stipg.md) · [§2.0b в плане](../chat-plan-26-1120-c2-d11-ipg-plans.md) · [01-schema-analysis](../../../sql/26-0604/docs/01-schema-analysis.md)

---

## 1. Structure — как Access пишет и читает

### 1.1 Слои записи (нет VBA CRUD)

Формы `stIpg`, `stIpg>Nm_t`, `stIpg>stRelParent_t`, `stIpg>stRelChild_t`, `stIpg>…>stNetPn`, `stIpgNm` — **без Form-модулей**. Запись идёт **bound ODBC** → linked `ags_*`.

Единственный VBA структуры ИПГ на хабе:

| Форма | Событие | Действие |
|-------|---------|----------|
| `stNetIpg` | `Activate` / `Current` | Подмена SQL `QueryDefs("ags_fnSt")` → `SELECT * FROM ags.fnSt(stnKey, stnRoot) … ORDER BY stNum`; `Requery` `stNet>fnSt_t` |
| `stNet>fnSt_t` | `Current` | Пытается фильтровать `stNetCost>stCost` (для затрат); на `stNetIpg` — noop (`On Error Resume Next`) |

Access QueryDef `ags_fnSt` в выгрузке — заглушка `fnSt(4,1)`; живой SQL каждый раз пишет форма.

### 1.2 Таблицы и ключи (noM6 / prod-совместимо)

| Таблица | PK | Identity | Смысл |
|--------|-----|----------|--------|
| `st` | `stKey` | **да** | универсальный узел; `stType`→`stType` (1=ИПГ, 2=затраты) |
| `stIpg` | `stiKey` | **нет** | расширение узла ИПГ; **`stiKey` = `st.stKey`**, `stiType` = `st.stType` (FK составной) |
| `stIpgNm` | `stinKey` | да | имя: `stinIpg`→`stiKey` (**не** `ipg.ipgKey`) |
| `stRel` | `strKey` | да | ребро; unique `IX_stRel(strParent,strChild)` |
| `stNet` | `stnKey` | да | схема: `stnType`, `stnName`, `stnRoot` |
| `stNetPn` | `stnpKey` | да | ребро∈схема: `stnpStRel`, `stpnStNet`, `stpnNum` |

Опционально: `stIpg.stiLim`→`stiLim` (legacy OUT; для `_2606` источник истины — `stIpgOutLimPn_2606`, не UI 1.1).

**Факт:** один `strChild` бывает в **нескольких** `stNet` (узлы/рёбра переиспользуются; «копия схемы» ≠ обязательно deep-copy всех вершин).

### 1.3 Атомарные операции записи (то, что делает оператор через bound-формы)

```text
Новый узел в схеме:
  1) INSERT st (stType=1)           → stKey
  2) INSERT stIpg (stiKey=stKey, stiType=1, …)
  3) INSERT stIpgNm (stinIpg=stiKey, stinNm=…)
  4) INSERT stRel (strParent, strChild=stKey)   -- если ещё нет пары
  5) INSERT stNetPn (stnpStRel, stpnStNet, stpnNum)

Новое ребро между существующими узлами в схеме:
  4–5 только (или только 5, если stRel уже есть и нужен другой net)

Новая схема (копия — гипотеза по словам владельца):
  INSERT stNet (stnType=1, stnName, stnRoot=…)
  + набор INSERT stNetPn на существующие (или новые) stRel
  ± новые узлы 1–5 при расширении DAG
```

Порядок важен из‑за FK: `st` → `stIpg` → `stIpgNm`; `st`×2 → `stRel` → `stNetPn`; `stNet` → `stNetPn`.

### 1.4 Чтение дерева

`ags.fnSt(@stNet, @stRoot)` — recursive CTE по `stRel`∩`stNetPn`, включает корень; колонки: `strChild`, `strParent`, `stpnNum`, `pnLevel`, `stNum`, `Nm`.  
`Nm` в теле функции = `stIpgCs` / `stCostCs` (не прямой JOIN к `stIpgNm` в UI-запросе Access).  
Фильтр типа: `st.stType = max(stNet.stnType)` (схема ИПГ не тянет узлы затрат).  
Автор функции: ANB, 2022-04-11 (`OBJECT_DEFINITION` на noM6).

Производные: `fnStDownAll` (без корня), `fnStUpAll` — для mastering/`_2606`, не для CRUD UI.

### 1.5 Следствие для FEMSQ Structure

Один экран должен закрыть то, что Access размазал по `stNetIpg` + `stIpg*`:

1. Список/CRUD `stNet` (type=1).  
2. Дерево = вызов `fnSt` (не плоский SELECT `stIpg`).  
3. CRUD узла = транзакция `st`+`stIpg`+`stIpgNm`.  
4. CRUD ребра-в-схеме = `stRel` (если нужно) + `stNetPn` + порядок `stpnNum`.  
5. Операция **«копия схемы»** — отдельная серверная процедура/сервис (не UI из 10 ручных INSERT); точный алгоритм копирования лета 2025 — восстановить на приёмке (сейчас: клон `stNet`+`stNetPn`, узлы shared).

---

## 2. Leaves — классы и таблицы (кратко)

### 2.1 Классы VBA (тонкие обёртки, не оркестраторы INSERT)

| Класс | Таблица | API | Роль |
|-------|--------|-----|------|
| `ipg` | `ags_ipg` | Get `ipgNm`, `ipgYy`, `ipgYyYear`; `ReinitialiseByKey`; edit через `ClassFunc.varEdit*` | чтение/правка полей существующей ИП |
| `ipgPn` | `ags_ipgPn` | Get `ipgpCstAgPn`, `ipgpIpg`, `ipgpTskCms` (+ Let); связи на `cstAgPn`, `ipg` | то же для пункта |
| `ipgCh` | `ags_ipgCh` | Get `ipgcIpgLate`, `ipgcStNetIpg`, `ipgcName` | то же для цепи; **нет** API членства `ipgChRl` |

Создание строк ИП/пунктов/связей в Access — в основном **bound-формы** (`ipg`, `ipg>Pn_*`, `ipgCh>Rl_t`), не эти классы.

### 2.2 Таблицы Leaves

| Таблица | Identity PK | Важные поля / ограничения |
|--------|-------------|---------------------------|
| `ipg` | `ipgKey` | `ipgStRlSh`→`stNet`; `ipgYy`→`yyyy`; `ipgOg`→`og` |
| `ipgPn` | `ipgpKey` | **unique** `(ipgpIpg, ipgpCstAgPn, ipgpSh)`; FK `cstAgPn`, `ipgSh` |
| `ipgStPn` | `ipgspKey` | `ipgspPn`→`ipgPn`, `ipgspSt`→`stIpg` (узел раздела) |
| `ipgCh` | `ipgcKey` | `ipgcStNetIpg`→`stNet`, `ipgcIpgLate`→актуальная ИП |
| `ipgChRl` | `ipgcrKey` | `ipgcrChain`, `ipgcrIpg`, `ipgcrUtPlGr` (nullable)→`ipgUtPlGr` |

`ipgChRl_2606` (даты актуальности) — **не** UI ввода 1.1; контур `_2606`/C3.

### 2.3 Инвентарь «тяжёлых проверок UtPl» на полной `ipg` (не перенос G3)

В `Form_ipg.cls` **нет** SQL проверки планов — только sync `Pn_t`→`Pn_f`. Медленный Load полной формы vs `ipgMin` объясняется **набором подформ**, которые тянут UtPl/лимиты при открытии/Current:

| Подформа на полной `ipg` (G3) | Замечание |
|-------------------------------|-----------|
| `ipg>Pn_t>UtPlP_t` | VBA: при Current фильтрует Ye/Qu/Mn лимиты по `iuplpKey` |
| `ipg>Pn_f>UtPlPnLmYe` / `…Qu` / `…Mn` | bound к `ipgUtPlPnLm*` |
| `ipg>Pn_f>Lim_t` | лимиты пункта |
| `ipg>UtPl_t`, `ipg>UtPlGr_t`, `…>P_t` | группы/планы |

**Для FEMSQ (эталон = полная `ipg`):** функционал проверок/просмотра UtPl **сохранить**, но:

- не грузить LmMn/UtPlP на каждый open карточки ИП;  
- lazy / по вкладке / по действию «проверить планы»;  
- тяжёлые запросы — на SQL Server с нормальными планами, не Access QueryDef-цепочки.

Детальный разбор тел запросов UtPl — этап **1.3 / G3**, не блокер Structure CRUD.

---

## 3. Кандидаты GraphQL (вход в §2.3 / §2.4)

Уже есть (read): `stNetworks`, `investmentPrograms`, `investmentChains`, `investmentChainRelations`, plan-group lookups.

### 3.1 Structure — приоритет 1

| Операция | Тип | Примечание |
|----------|-----|------------|
| `stNetworkTree(stNetKey, rootKey)` | Query | Обёртка `fnSt`; колонки как грид Access |
| `createStNetwork` / `updateStNetwork` | Mutation | `stnType=1`, имя, root |
| `cloneStNetwork(sourceKey, newName)` | Mutation | серверный клон `stNet`+`stNetPn` (± опция deep); алгоритм уточнить на приёмке |
| `createStIpgNode` / `updateStIpgNode` / `renameStIpgNode` | Mutation | транзакция `st`+`stIpg`+`stIpgNm` |
| `attachStEdgeToNetwork` / `detachStEdgeFromNetwork` / `setStNetPnNum` | Mutation | `stRel`+`stNetPn` / только `stNetPn` |
| `deleteStIpgNode` | Mutation | осторожно: FK от `ipgStPn`, рёбра, multi-net — политика cascade/forbid в 2.3 |

### 3.2 Leaves — приоритет 2 (после/параллельно UI Structure)

| Операция | Тип | Примечание |
|----------|-----|------------|
| `createInvestmentProgram` / `updateInvestmentProgram` | Mutation | поля шапки `ipg`; `ipgStRlSh` обязателен |
| `createIpgPn` / `updateIpgPn` / `deleteIpgPn` | Mutation | unique `(ipg,cstAgPn,sh)`; default `ipgSh=4` при загрузке |
| `setIpgPnStructure` (`ipgStPn`) | Mutation | привязка пункта к `stiKey` (Leaves) |
| `createInvestmentChain` / `updateInvestmentChain` | Mutation | `ipgCh` |
| `addIpgToChain` / `updateChainRelation` / `removeIpgFromChain` | Mutation | `ipgChRl` — заменить ручной SSMS |

Загрузка Excel → staging → bulk `ipgPn`+`ipgStPn` — отдельный трек (§2.0a / этап 1.2), не смешивать с точечным CRUD.

---

## 4. Открытые хвосты (не блокируют закрытие 2.2A)

1. Точный рецепт **clone** схемы (лето 2025) — приёмка / один прогон на noM6 с владельцем.  
2. Скрин полной `ipg` (какие вкладки UtPl видны при Load).  
3. Тела Access-запросов UtPl (если выгрузят Query SQL) — для оптимизации, этап G3.  
4. Политика delete узла при `ipgStPn` и shared multi-net.

---

## 5. Готовность к §2.3

✅ Закрыто документом [26-1120-c2-migrate-1-1.md](./26-1120-c2-migrate-1-1.md) (принцип: Access — семантика, не качество; оптимизация обязательна).
