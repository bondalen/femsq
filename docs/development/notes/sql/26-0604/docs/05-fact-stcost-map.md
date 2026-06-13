# Карта «поля документов факта → stCost.stcKey»

**Дата:** 2026-06-04  
**lastUpdated:** 2026-06-13  
**Задача:** `spMstrg_2606` — определение соответствий для реализации Варианта 6А  
**Контекст:** Необходимо перед созданием скалярных функций `fnMasteringRet*`, `fnMasteringInProc*`, `fnMasteringNotArr*`

> ⚠️ **Исправление 2026-06-13:** до применения `01d1` в БД плоское поле `ras_work` ошибочно синхронизировалось в `factDocCost` как **182**. Семантика Excel-колонки «СМР» и `ra_summCt` — **195**. Целевой маппинг и план миграции: **`11-ra-work-stCost195-fix-plan.md`**.

---

## Справочник stCost (задействованные stcKey)

| stcKey | stcNote | Назначение |
|--------|---------|-----------|
| 148 | Агентское вознаграждение | Суммы по актам АВ |
| 150 | Аренда земельных участков | Суммы по отчётам РАЛП |
| 169 | Материалы, ОПИ | Суммы проводок ОПИ |
| 172 | Оборудование | Подстатья ОА: оборудование |
| 182 | Подрядные работы | **Дочерний узел 195**; в `ra_summCt`, не в плоском `ras_work` |
| 187 | Прочие | Подстатья ОА: прочие |
| 195 | СМР | Подстатья ОА: подрядные работы и материалы (верхний уровень) |
| 197 | Строительный контроль | Суммы проводок ССК |
| 205 | Хранение | Суммы проводок хранения |
| 212 | Всего | Итого по ОА (корень дерева ОА) |

---

## 1. Отчёты агента (RA)

### Источники сумм

| Поле таблицы | stcKey | Название | Примечание |
|---|---|---|---|
| `ra_summ.ras_total` | **212** | Всего | Итоговая сумма ОА (все статьи) |
| `ra_summ.ras_work` | **195** | **СМР** | Колонка Excel `rainWork`; **не** 182 |
| `ra_summ.ras_equip` | **172** | Оборудование | Подстатья ОА |
| `ra_summ.ras_others` | **187** | Прочие | Подстатья ОА |
| `ra_summCt.rscSumm` (at `rscStCost=X`) | **X** (динамически) | Любой узел stCost | Нормализованная версия; используется в `fnStCostRa` |

**Инвариант верхнего уровня ОА:** `212 = 172 + 187 + 195` (в `ra_summCt` — 7050/7051 документов на dev).

**182** в `factDocCost` — только из детализирующих строк `ra_summCt` (@182), не из `ras_work`.

**Для Варианта 6А:** новые скалярные функции вызывают `fnStCostRa(ra_key, @StCostKey, @stNet)` — как в `fnMasteringPresRa`/`fnMasteringAccpRa`. Плоские поля `ras_total/ras_work/ras_equip/ras_others` не нужны.

### Статусные поля таблицы `ra`

| Поле | Тип | Смысл |
|------|-----|-------|
| `ra_arrived` | nvarchar | Признак поступления (IS NOT NULL → поступил) |
| `ra_arrived_date` | date | Дата поступления |
| `ra_returned` | nvarchar | Признак возврата (IS NOT NULL → был возврат) |
| `ra_returned_date` | date | Дата возврата |
| `ra_sent` | nvarchar | Признак согласования (IS NOT NULL → принят) |
| `ra_sent_date` | date | Дата согласования |

### Логика вычисления `rsltOfConsider` для RA

```sql
rsltOfConsider =
  CASE
    WHEN ra_returned IS NULL
      THEN CASE
        WHEN ra_sent IS NULL
          THEN CASE WHEN ra_arrived IS NULL THEN 'not arrived' ELSE 'in process' END
        ELSE 'sended'
      END
    ELSE
      CASE WHEN ra_sent_date >= ra_returned_date THEN 'sended' ELSE 'returned' END
  END
```

То же применяется к `ra_change` (через поля `rac_sent`, `rac_returned`, `rac_arrived`).

### Соответствие категорий `_2408` → скалярные функции _2606

| Категория в `_2408` | Условие | Скалярная функция в `_2606` | Статус реализации |
|---|---|---|---|
| `presented` | `rsltOfConsider` любой, `complianceY` текущий год | `fnMasteringPresRa` | ✅ существует |
| `accepted` | `rsltOfConsider = 'sended'`, текущий год | `fnMasteringAccpRa` | ✅ существует |
| `returned` | `rsltOfConsider = 'returned'`, текущий год | **`fnMasteringRetRa`** | ❌ новая |
| `inProcess` | `rsltOfConsider = 'in process'`, текущий год | **`fnMasteringInProcRa`** | ❌ новая |
| `notArrived` | `rsltOfConsider = 'not arrived'`, текущий год | **`fnMasteringNotArrRa`** | ❌ новая |
| `presentedAll` | все RA любого года ≤ dAll | **`fnMasteringPresAllRa`** | ❌ новая |
| `presentedAllModul` | ABS сумм всех RA | **`fnMasteringPresAllModulRa`** | ❌ новая |
| `presentedPrevYears` | прошлые годы, текущий год | **`fnMasteringPresPrevYRa`** | ❌ новая |
| `acceptedPrevYears` | прошлые годы, принято | **`fnMasteringAccpPrevYRa`** | ❌ новая |
| `returnedPrevYears` | прошлые годы, возвращено | **`fnMasteringRetPrevYRa`** | ❌ новая |
| `inProcessPrevYears` | прошлые годы, на рассмотрении | **`fnMasteringInProcPrevYRa`** | ❌ новая |
| `notArrivedPrevYears` | прошлые годы, не поступало | **`fnMasteringNotArrPrevYRa`** | ❌ новая |

**Месячные (`*Mn`) варианты:** для каждой из вышеуказанных + `Mn`-суффикс (фильтр по `month(r.ra_datePeriod) = month(@dAll)`). Итого для RA: ~24 новые функции.

---

## 2. Агентское вознаграждение (АВ / AgFee)

### Источники сумм

| Поле таблицы | stcKey | Название | Примечание |
|---|---|---|---|
| `ogAgFeeP.oafpTotal` | **148** | Агентское вознаграждение | Хардкод в `fnStCostAgFee`: `@stCostOgAgFee = 148` |

Одна стоимостная строка на пункт Акта АВ. `fnStCostAgFee` применяет восходящий обход DAG от stcKey=148 — если `@StCostKey` = 148 или любой вышестоящий (например, корень дерева затрат), сумма включается.

### Статусные поля таблицы `ogAgFee`

| Поле | Тип | Смысл |
|------|-----|-------|
| `oafArrived` | nvarchar | Признак поступления |
| `oafArrivedDate` | date | Дата поступления |
| `oafReturned` | nvarchar | Признак возврата |
| `oafReturnedDate` | date | Дата возврата |
| `oafSent` | nvarchar | Признак согласования (принят) |
| `oafSentDate` | date | Дата согласования |

### Логика `rsltOfConsider` для АВ

```sql
rsltOfConsider =
  CASE
    WHEN oafReturned IS NULL
      THEN CASE
        WHEN oafSent IS NULL
          THEN CASE WHEN oafArrived IS NULL THEN 'not arrived' ELSE 'in process' END
        ELSE 'sended'
      END
    ELSE
      CASE WHEN oafSentDate >= oafReturnedDate THEN 'sended' ELSE 'returned' END
  END
```

### Категории АВ

| Категория | Скалярная функция _2606 | Статус |
|---|---|---|
| `agFeePresented` | `fnMasteringPresAgFee` | ✅ существует |
| `agFeeAccepted` | `fnMasteringAccpAgFee` | ✅ существует |
| `agFeeReturned` | **`fnMasteringRetAgFee`** | ❌ новая |
| `agFeeInProcess` | **`fnMasteringInProcAgFee`** | ❌ новая |
| `agFeeNotArrived` | **`fnMasteringNotArrAgFee`** | ❌ новая |

**Месячные варианты:** +5 (`*Mn`). Итого для АВ: ~10 новых функций.

---

## 3. Аренда земельных участков (РАЛП)

### Источники сумм

| Поле таблицы | stcKey | Название | Примечание |
|---|---|---|---|
| `ralpRaAu.ralpraCostAndVat` | **150** | Аренда земельных участков | Хардкод в `fnStCostRalp`: `@stCostRalp = 150` |

### Статусные поля таблицы `ralp`

| Поле | Тип | Смысл |
|------|-----|-------|
| `ralpArrived` | nvarchar | Признак поступления |
| `ralpArrivedDate` | date | Дата поступления |
| `ralpReturned` | nvarchar | Признак возврата |
| `ralpReturnedDate` | date | Дата возврата |
| `ralpSent` | nvarchar | Признак согласования (принят) |
| `ralpSentDate` | date | Дата согласования |

### Логика `rsltOfConsider` для РАЛП

```sql
rsltOfConsider =
  CASE
    WHEN ralpReturned IS NULL
      THEN CASE
        WHEN ralpSent IS NULL
          THEN CASE WHEN ralpArrived IS NULL THEN 'not arrived' ELSE 'in process' END
        ELSE 'sended'
      END
    ELSE
      CASE WHEN ralpSentDate >= ralpReturnedDate THEN 'sended' ELSE 'returned' END
  END
```

### Категории РАЛП

| Категория | Скалярная функция _2606 | Статус |
|---|---|---|
| `presentedRalp` | `fnMasteringPresRalp` | ✅ существует |
| `acceptedRalp` | `fnMasteringAccpRalp` | ✅ существует |
| `returnedRalp` | **`fnMasteringRetRalp`** | ❌ новая |
| `inProcessRalp` | **`fnMasteringInProcRalp`** | ❌ новая |
| `notArrivedRalp` | **`fnMasteringNotArrRalp`** | ❌ новая |

**Месячные варианты:** +5 (`*Mn`). Итого для РАЛП: ~10 новых функций.

---

## 4. Хранение (Storage)

### Источники сумм

| Поле таблицы | stcKey | Название | Примечание |
|---|---|---|---|
| `cn_PrDocP.costVAT` (pdtoCode='ZPTG'/'ZKTG') | **205** | Хранение | Хардкод в `fnStCostPrDoc` |

**Статус: только «принято» (проведено).** Нет workflow согласования. `returned/inProcess/notArrived` не применимы.

| Категория | Скалярная функция _2606 | Статус |
|---|---|---|
| `storageSum` | `fnMasteringAccpStor` | ✅ существует |
| `storageSumAccum` | через накопитель в `fnMasteringCstAgPnSh_2606` | ✅ |

---

## 5. Строительный контроль (ССК / Control)

### Источники сумм

| Поле таблицы | stcKey | Название | Примечание |
|---|---|---|---|
| `cn_PrDocP.costVAT` (pdtoCode='ZUGH', account=350252) | **197** | Строительный контроль | Хардкод в `fnStCostPrDoc` |

**Статус: только «принято».** Аналогично хранению.

| Категория | Скалярная функция _2606 | Статус |
|---|---|---|
| `cctSum` | `fnMasteringAccpControl` | ✅ существует |

---

## 6. ОПИ / Минералы (Minerals)

### Источники сумм

| Поле таблицы | stcKey | Название | Примечание |
|---|---|---|---|
| `cstAgPnMnrl.amSum` | **169** | Материалы, ОПИ | Хардкод в `fnStCostMnrl`: `@stCostMnr = 169` |

**Статус: только «принято».** Прямые проводки, нет workflow.

| Категория | Скалярная функция _2606 | Статус |
|---|---|---|
| `MnrlSum` | `fnMasteringAccpMnrl` | ✅ существует |

---

## Итоговый перечень новых скалярных функций (Вариант 6А)

### Новые функции с workflow-статусами

| Группа | Функция | Статус | Таблица-источник | stcKey |
|--------|---------|--------|-----------------|--------|
| RA returned | `fnMasteringRetRa` | returned | `ra` / `ra_change` | 212* |
| RA returned Mn | `fnMasteringRetRaMn` | returned | `ra` / `ra_change` | 212* |
| RA in process | `fnMasteringInProcRa` | in process | `ra` / `ra_change` | 212* |
| RA in process Mn | `fnMasteringInProcRaMn` | in process | `ra` / `ra_change` | 212* |
| RA not arrived | `fnMasteringNotArrRa` | not arrived | `ra` / `ra_change` | 212* |
| RA not arrived Mn | `fnMasteringNotArrRaMn` | not arrived | `ra` / `ra_change` | 212* |
| АВ returned | `fnMasteringRetAgFee` | returned | `ogAgFeeP/ogAgFee` | 148 |
| АВ returned Mn | `fnMasteringRetAgFeeMn` | returned | `ogAgFeeP/ogAgFee` | 148 |
| АВ in process | `fnMasteringInProcAgFee` | in process | `ogAgFeeP/ogAgFee` | 148 |
| АВ in process Mn | `fnMasteringInProcAgFeeMn` | in process | `ogAgFeeP/ogAgFee` | 148 |
| АВ not arrived | `fnMasteringNotArrAgFee` | not arrived | `ogAgFeeP/ogAgFee` | 148 |
| АВ not arrived Mn | `fnMasteringNotArrAgFeeMn` | not arrived | `ogAgFeeP/ogAgFee` | 148 |
| РАЛП returned | `fnMasteringRetRalp` | returned | `ralpRaAu/ralp` | 150 |
| РАЛП returned Mn | `fnMasteringRetRalpMn` | returned | `ralpRaAu/ralp` | 150 |
| РАЛП in process | `fnMasteringInProcRalp` | in process | `ralpRaAu/ralp` | 150 |
| РАЛП in process Mn | `fnMasteringInProcRalpMn` | in process | `ralpRaAu/ralp` | 150 |
| РАЛП not arrived | `fnMasteringNotArrRalp` | not arrived | `ralpRaAu/ralp` | 150 |
| РАЛП not arrived Mn | `fnMasteringNotArrRalpMn` | not arrived | `ralpRaAu/ralp` | 150 |

*RA: stcKey передаётся как `@StCostKey`, функция вызывает `fnStCostRa` — обходит DAG автоматически.

### Дополнительные функции (PresentedAll / PrevYears) — решение отдельно

| Функция | Описание | Доп. сложность |
|---------|---------|---------------|
| `fnMasteringPresAllRa` | Все RA ≤ dAll (без фильтра по году) | Убрать `year(@dAll) = year(r.ra_datePeriod)` |
| `fnMasteringPresAllModulRa` | ABS от всех RA | ABS(`fnStCostRa`) |
| `fnMasteringPresPrevYRa` | RA прошлых лет текущего периода | `year(r.ra_datePeriod) != year(@dAll)` |
| `fnMasteringAccpPrevYRa` | Принято из прошлых лет | + `ra_sent IS NOT NULL` |
| `fnMasteringRetPrevYRa` | Возвращено из прошлых лет | + `rsltOfConsider = 'returned'` |
| `fnMasteringInProcPrevYRa` | На рассмотрении из прошлых лет | + `rsltOfConsider = 'in process'` |
| `fnMasteringNotArrPrevYRa` | Не поступало из прошлых лет | + `rsltOfConsider = 'not arrived'` |

Аналогично для РАЛП (если `_2408` содержит `prevYearsRalp`).

### Итого: ~25 новых скалярных функций

Все функции короткие (~15–25 строк), копия структуры `fnMasteringPresRa` / `fnMasteringAccpRa` с изменением одного условия (`rsltOfConsider`).

---

## Ключевые выводы

1. **Все типы документов (шаг 1, Решение 9):** разбивка по `stCost` хранится в `factDocCost`; подклассы (`ra_summ`, `ogAgFeeP`, `ralpRaAu`, `cn_PrDocP`, `cstAgPnMnrl`, …) сохраняют плоские поля для VBA/Java; триггеры синхронизируют `factDocCost`.
2. **Функции `_2606`** вызывают `fnStCost*_2606`, читающие `factDocCost`; legacy `fnStCost*` и `ra_summCt` не изменяются (`_2605`).
3. **АВ, РАЛП** — по одному `stcKey` (148, 150); фильтрация по `@StCostKey` — восходящий DAG (`fnStUpAll`).
4. **Хранение, ССК, ОПИ** — только статус «принято»; `returned/inProcess/notArrived` не нужны; в `factDocCost` одна строка на документ.
5. **Статусная логика** одинакова для RA, АВ, РАЛП: `arrived/returned/sent` + даты → `rsltOfConsider`.
6. **PrevYears** — в основном RA; для РАЛП уточнить по `_2408`.

---

*Файл создан: 2026-06-04. Уточнять по мере верификации на данных.*
