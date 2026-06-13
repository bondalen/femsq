# Карта вычислений spMstrg_2606: источник каждого шага

**Дата:** 2026-06-04  
**Задача:** `spMstrg_2606` — архитектурный анализ перед началом разработки  
**Контекст:** Ответ на вопрос «из какого стека берётся каждый из трёх шагов (лимит / план / факт)?»

---

## Два анализируемых стека

### Стек А: `fnIpgChRsltCstUtl_2408` (основа `_2605`)

```
fnIpgChRsltCstUtl_2408(@ipgChKey)
    ├── fnIpgChRsltCst(@ipgChKey, @lsYyKey)  ← строй + даты + типы (typeGr)
    ├── ipgPn.ipgpSmTtl × 1 000 000          ← лимиты
    ├── smm/smmTtl                            ← планы
    ├── JOIN RRcTimeList                      ← факт RA (все статусы)
    ├── JOIN ogAgFeeP / ogAgFee               ← факт агентского вознаграждения
    ├── JOIN ralp                             ← факт аренды земли
    ├── JOIN cn_PrDocP (tpOrd=1,2,4)         ← факт хранения
    ├── JOIN cn_PrDocP (tpOrd=3, acnt=30)    ← факт стройконтроля
    └── JOIN cstAgPnMnrl                     ← факт ОПИ
```

Параметры: `@ipgChKey` (без фильтров по структуре ИПГ/затрат).  
Актуальность ИПГ: по `ipg.ipgStr/ipgEnd` на уровне **месяца** (`MONTH(ipgStr)`).

### Каскад схем реализации (освоение не теряется)

При приёмке документов «не по той» схеме суммы распределяются по приоритету:
**агентская → инвестиционная → иная → неплан** (капзатраты, per ИПГ). Тип **`4. Прочие`**
(некапитальные) — **отдельный контур**: не влияет на освоение ИПГ, **не входит в Mstrg**,
колонки `oh_*` в `PercentBrn` — справочно.

Реализация: `fnMasteringShShow`, `ipgPnSchemePts`, `@masteringTrue` / `@ShType`;
`nullIpgBase` только для `typeGr='2. ОА, прочие и Изм'`.

Подробно: **`09-scheme-cascade-mastering.md`**.

### Стек Б: `fnMasteringStIpgStCost` (DAG-фильтрация)

```
fnMasteringStIpgStCost(@ipgRoot, @ipgCh, @stCostKey, @stNet)
    └── fnMasteringCstAgPnSh(@ipgCh, @cstAgPn, @stCostKey, @stNet, @ipgRoot)
            └── fnMasteringCstAgPn(@ipgCh, @cstAgPn, @ipgSh, @stCostKey, @stNet, @ipgRoot)
                    ├── fnIpgChDats(@ipgCh)              ← даты
                    ├── fnStCostRsCstAgPn(...)            ← лимиты + планы
                    │       └── fnStCostRsIpgPn(...)      ← лимиты по пунктам ИПГ
                    ├── fnMasteringPresRa / AccpRa       ← факт RA: представлено/принято
                    ├── fnMasteringPresAgFee / AccpAgFee ← факт АВ: представлено/принято
                    ├── fnMasteringPresRalp / AccpRalp   ← факт РАЛП: представлено/принято
                    ├── fnMasteringAccpStor              ← факт хранения: только принято
                    ├── fnMasteringAccpControl           ← факт стройконтроля: только принято
                    └── fnMasteringAccpMnrl              ← факт ОПИ: только принято
```

Параметры: `@ipgRoot`, `@stCostKey` — обязательные.  
Актуальность ИПГ: та же ошибка — через `ipg.ipgStr/ipgEnd` + `ipgCh.ipgcStNetIpg` (Дефект А).

---

## Полная карта шагов `_2606`

### Шаг 0. Генерация дат

| Аспект | Стек А `_2408` | Стек Б `fnMstrg` | `_2606` |
|--------|---------------|-----------------|---------|
| Функция | `fnIpgChDats(@ipgCh)` | `fnIpgChDats(@ipgCh)` | **`fnIpgChDatsV(@ipgCh)`** (новая) |
| Источник дат переходов | `ipg.ipgStr` (глобальный) | `ipg.ipgStr` (глобальный) | **`ipgChRlV.ipgcrvStr`** (per-chain) |
| Начальная точка | первый месяц ИПГ | первый месяц ИПГ | **01.01 расчётного года** |
| Точки перехода ИПГ | только конец года | только конец года | **день перехода ± 1 день** |

Источник: **новый объект** (не берётся из существующих стеков).

---

### Шаг 1. Актуальность ИПГ на дату (фильтрация строк)

| Аспект | Стек А `_2408` | Стек Б `fnMstrg` | `_2606` |
|--------|---------------|-----------------|---------|
| Критерий | `MONTH(ipgStr) ≤ mNum ≤ MONTH(ipgEnd)` | то же (Дефект А) | **`ipgcrvStr ≤ dateRslt ≤ ipgcrvEnd`** |
| Гранулярность | месяц (→ задвоение при переходе внутри мес.) | месяц | **день** (нет задвоений) |
| Источник | `ipg.ipgStr/ipgEnd` (глобальный) | то же | **`ipgChRlV`** (per-chain, Дефект Б исправлен) |

Источник для `_2606`: **`ipgChRlV` + `fnIpgChDatsV`** (исправляет Дефект Б).

---

### Шаг 2. Отбор строек по структуре ИПГ (DAG-фильтр @ipgStKey)

| Аспект | Стек А `_2408` | Стек Б `fnMstrg` | `_2606` |
|--------|---------------|-----------------|---------|
| Фильтр | **нет** (`@ipgSt` = legacy table) | DAG: `fnStDownAll + ipgStPn` | DAG: **`fnMasteringStIpgStCost_2606`** |
| Схема | — | берёт `ipgcStNetIpg` от последней ИПГ | берёт схему от **актуальной ИПГ** на дату |
| Параметр | `@ipgSt nvarchar` | `@ipgRoot int` | **`@ipgStKey int` (nullable)** |

Источник для `_2606`: **стек Б** (`fnMasteringStIpgStCost`) с исправлением Дефекта А.

---

### Шаг 3. Лимиты (`lim`)

| Аспект | Стек А `_2408` | Стек Б `fnMstrg` | `_2606` |
|--------|---------------|-----------------|---------|
| Источник | `ipgPn.ipgpSmTtl × 1M` прямым JOIN | `fnStCostRsIpgPn → ipgUtPlPnLmMn` | **`fnStCostRsIpgPn_2606`** |
| Актуальность | через `ipg.ipgKey` (Дефект Б) | через `ipg.ipgKey` (Дефект Б) | **через `ipgChRlV.ipgcrvIpg`** |
| Fallback при NULL | — | — | **`ipgUtPlP.iuplpLim`** (для цепи 15) |
| Фильтр по `@stCostKey` | нет | да (`fnStCostRs*`) | **да** (nullable) |

Источник для `_2606`: **стек Б** + исправление Дефекта Б в `fnStCostRsIpgPn_2606`.

---

### Шаг 4. Планы (`smm`, `smmTtl`)

| Аспект | Стек А `_2408` | Стек Б `fnMstrg` | `_2606` |
|--------|---------------|-----------------|---------|
| Источник | `fnIpgChRsltCst → ipgUtPlP.*` | `fnStCostRsCstAgPn → fnStCostRsIpgPn → ipgUtPlPnLmMn` | **`fnStCostRsCstAgPn_2606`** |
| Фильтр по `@stCostKey` | нет | да | **да** (nullable) |

Источник для `_2606`: **стек Б** (`fnStCostRsCstAgPn` клон).

---

### Шаг 5. Факт: Представлено / Принято (RA, АВ, РАЛП, Хранение, ССК, ОПИ)

| Категория | Стек А `_2408` | Стек Б `fnMstrg` | `_2606` |
|-----------|---------------|-----------------|---------|
| RA presented/accepted | JOIN `RRcTimeList` | `fnMasteringPresRa / AccpRa` | **стек Б** (существующие функции) |
| АВ presented/accepted | JOIN `ogAgFeeP` | `fnMasteringPresAgFee / AccpAgFee` | **стек Б** |
| РАЛП presented/accepted | JOIN `ralp` | `fnMasteringPresRalp / AccpRalp` | **стек Б** |
| Хранение | JOIN `cn_PrDocP` (1,2,4) | `fnMasteringAccpStor` | **стек Б** |
| ССК | JOIN `cn_PrDocP` (3, acnt=30) | `fnMasteringAccpControl` | **стек Б** |
| ОПИ | JOIN `cstAgPnMnrl` | `fnMasteringAccpMnrl` | **стек Б** |

Источник: **стек Б** (существующие скалярные функции — не меняются, принимают `@StCostKey`).

---

### Шаг 6. Факт: Возвращено / На рассмотрении / Не поступало — ⚠️ РАЗРЫВ

| Категория | Стек А `_2408` | Стек Б `fnMstrg` | `_2606` |
|-----------|---------------|-----------------|---------|
| RA returned/inProcess/notArrived | ✅ JOIN `RRcTimeList` (фильтр `rsltOfConsider`) | **❌ не реализовано** | см. варианты ниже |
| АВ returned/inProcess/notArrived | ✅ JOIN `ogAgFeeP/ogAgFee` | **❌ не реализовано** | см. варианты ниже |
| РАЛП returned/inProcess/notArrived | ✅ JOIN `ralp` | **❌ не реализовано** | см. варианты ниже |
| PresentedAll / PresentedAllModul | ✅ все строки `RRcTimeList` | **❌ не реализовано** | см. варианты ниже |
| PrevYears (прошлые годы) | ✅ фильтр `complianceY` | **❌ не реализовано** | см. варианты ниже |

**Это главный архитектурный разрыв**: стек Б охватывает только `presented` и `accepted`.  
Все подтатегории дифференциации факта (`returned`, `inProcess`, `notArrived`, `prevYears`) — **только в стеке А**.

---

## Варианты заполнения разрыва (Шаг 6)

### Вариант 6А: Новые скалярные функции по образцу стека Б

Добавить `fnMasteringRetRa`, `fnMasteringInProcRa`, `fnMasteringNotArrRa`,  
`fnMasteringRetAgFee`, `fnMasteringInProcAgFee`, ...  

- ✅ Единая архитектура (все факты через скалярные функции с `@StCostKey`)
- ✅ Полная поддержка фильтрации по `@stCostKey` во всех категориях
- ⚠️ Нужно ~10 новых скалярных функций (аналог существующих, другой статус)
- ⚠️ Производительность: per-row scalar вызовы (приемлемо для справочного объёма)

### Вариант 6Б: Inline-JOIN по образцу стека А внутри `fnMasteringCstAgPnSh_2606`

Скопировать JOIN-логику из `fnIpgChRsltCstUtl_2408` для каждой категории факта,  
передавая `@cstAgPn` как фильтр, добавив `@StCostKey` в условия JOIN.

- ✅ Полное покрытие всех категорий без новых объектов
- ✅ Логика уже проверена в `_2408`
- ⚠️ Нужно адаптировать JOIN-условия (добавить `@StCostKey` в `RRcTimeList` и др. — требует изучения схемы)
- ⚠️ Функция `fnMasteringCstAgPnSh_2606` вырастает в объёме

### Вариант 6В: Сокращённый первый релиз (только Pres/Accp)

Для v1 `_2606` оставить только `presented` + `accepted` (по образцу стека Б),  
`returned/inProcess/notArrived` — в следующей версии `_2607`.

- ✅ Минимальный scope для первого выпуска
- ⚠️ Неполный ResultSet по сравнению с `_2605`; клиент (MS Access, FEMSQ) не сможет полностью заменить `_2605`

---

## Итоговая таблица источников для `_2606`

| Шаг | Объект `_2606` | Источник-прототип | Изменения относительно прототипа |
|-----|---------------|-------------------|----------------------------------|
| 0. Даты | `fnIpgChDatsV` | `fnIpgChDats` (стек Б) | Точки перехода из `ipgChRlV`, дата 01.01 |
| 1. Актуальность ИПГ | внутри `fnIpgChDatsV` + `fnStCostRsIpgPn_2606` | `ipg.ipgStr/ipgEnd` (стек А/Б) | `ipgChRlV.ipgcrvStr/ipgcrvEnd`, день |
| 2. DAG-отбор строек | `fnMasteringStIpgStCost_2606` | стек Б | Актуальная ИПГ на дату (не последняя) |
| 3. Лимиты | `fnStCostRsIpgPn_2606` | стек Б | Дефект Б исправлен; fallback к `iuplpLim` |
| 4. Планы | `fnStCostRsCstAgPn_2606` | стек Б | Использует `_2606`-подфункции |
| 5a. Факт Pres/Accp | `fnMasteringCstAgPnSh_2606` | стек Б | Существующие `fnMasteringPres/Accp*` |
| 5b. Факт Ret/InProc/NotArr | `fnMasteringCstAgPnSh_2606` | **разрыв — выбрать вариант 6А/6Б/6В** | |
| 5c. Факт PrevYears | `fnMasteringCstAgPnSh_2606` | **разрыв — выбрать вариант 6А/6Б/6В** | |
| 6. Агрегация схем | `fnMasteringStIpgStCost_2606` | стек Б | Параметры `@ipgStKey`/`@stCostKey` nullable |
| 7. Метаданные + вывод | `fnIpgChRsltCstUtl2_2606` | стек Б / стек А | Совместимый формат |
| 8. Итог + % | `fnIpgChRsltCstUtlPercentBrn_2606` | стек А/Б | Использует `_2606`-функции |
| 9. Процедура | `spMstrg_2606` | стек А | `@ipgStKey`, `@stCostKey` nullable |

---

## Принятое решение по разрыву (Шаг 6)

Приоритетный **Вариант 6А** (новые скалярные функции):

**Обоснование:**
1. Скалярные функции `fnMasteringPresRa`, `fnMasteringAccpRa` уже принимают `@StCostKey` и применяют его к фактическим данным. Новые функции (`Ret*`, `InProc*`, `NotArr*`) будут точными аналогами — менять один фильтр в одном месте.
2. Inline-JOIN (Вариант 6Б) потребует изучить и адаптировать `@StCostKey` для каждой таблицы фактов — неочевидная задача без знания схемы таблиц `RRcTimeList`, `ralp` и др.
3. Сокращённый первый релиз (Вариант 6В) не является полноценной заменой `_2605`.

**Количество новых скалярных функций для Варианта 6А (уточнено после анализа 2026-06-04):**

| Группа | Статусы | Функций (+ Mn) | Итого |
|--------|---------|---------------|-------|
| RA | returned / inProcess / notArrived | 3 + 3 = 6 | 6 |
| RA PrevYears | returned / inProcess / notArrived / presented / accepted | 5 (без Mn) | 5 |
| RA PresentedAll | presentedAll / presentedAllModul | 2 (без Mn) | 2 |
| АВ | returned / inProcess / notArrived | 3 + 3 = 6 | 6 |
| РАЛП | returned / inProcess / notArrived | 3 + 3 = 6 | 6 |
| **Итого** | | | **~25 функций** |

- Хранение, ССК, ОПИ — статусные функции **не нужны** (нет workflow).
- Функции короткие (~15–25 строк), структура как у `fnMasteringPresRa` с изменением условия `rsltOfConsider`.
- Детальное соответствие полей и stcKey: см. `05-fact-stcost-map.md`.

**Как это влияет на план:** добавляется 1 под-этап к Этапу 3b («новые скалярные функции факта») перед `fnMasteringCstAgPnSh_2606`. Уточнённый объём — ~25 функций (было ~20).

---

*Файл создан: 2026-06-04. Обновлён 2026-06-04 (уточнение количества функций + ссылка на 05-fact-stcost-map.md).*
