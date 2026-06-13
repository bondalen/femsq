# План работы чата: spMstrg_2606 — DAG-фильтрация и корректная цепь ИПГ (v2)

**Дата:** 2026-06-04  
**Версия плана:** v2.5 от 2026-06-13 (этапы 11–12 ✅; **этап 13** — stCost 195 ✅ К-11)  
**Предыдущая:** v2.3 от 2026-06-12 (этапы 11–12 ✅, К-9/К-10 ✅)  
**Предыдущая версия:** `chat-plan-26-0604-spMstrg-2606.md` (архив, сохранена)  
**Автор:** Александр  
**Предшествующий план:** `chat-plan-26-0508-spMstrg-2605.md`

---

## Цель чата

Разработать и верифицировать SQL-объекты серии `_2606` на тестовой БД **FishEye** и сформировать пакет для продуктивного сервера (SQL Server 2012 SP4) с документом `db-upgrade-spMstrg-2606.md`.

---

## Ключевые архитектурные решения

| # | Решение |
|---|---------|
| 1 | `ags.ipgChRlV` — `ipgcrvEnd` как вычисляемый столбец через `fnIpgChRlVEnd` |
| 2 | DAG-фильтрация: параметр `@ipgStKey int` + `fnStDownAll` + `ipgStPn` |
| 3 | Новая цепочка `_2606`; `_2605`/`_2408` и их клиенты не затрагиваются |
| 4 | Тестовая цепь — **5** (680 контрактов, 17 дат); цепь 15 — только `ipgChRlV` |
| 5 | `factDoc`/`factDocCost` — суперкласс документов факта (политика B+F); 6 типов |
| 6 | `_2606` пишет только в `spMstrg_2606_ResultSet1..7`; `*_2408_ResultSet*` не трогаем |
| **7** | **LEGACY scalar UDF → `fnMasteringFact*_2606` через `factDocCost`** *(Решение 2026-06-11)* — устраняет узкое место ×70–140; одновременно реализует Вариант 6А (Ret/InProc/NotArr) |

Детали: `docs/development/notes/sql/26-0604/docs/03-design-decisions.md`  
Анализ производительности: `docs/development/notes/sql/26-0604/docs/07-performance-analysis.md`

---

## Тестовые параметры (цепь 5)

| Параметр | Значение |
|----------|----------|
| `@ipgCh` | 5 («Газпром, 2022») |
| `@MounthEndDate` | `'2022-09-30'` |
| Контрактов | 680 (stIpg=46: 164; stIpg=61: ~N) |
| Дат расчёта | 17 (2022-01-01 + 12 концов мес. + 4 перехода) |

---

## Итоги сессии 2026-06-11

### Достигнуто

| Область | Результат |
|---------|-----------|
| Этап 7 | Индексы `00-perf-indexes.sql` применены; **К-5** ✅ |
| Этап 8.1–8.2 | `03b1`: **46** `fnMastering*_2606` через `factDocCost` в БД ✅ |
| Этап 8.3 | `03c`: `fnMasteringCstAgPn_2606` + Sh; повторно применён (~418 ms) ✅ |
| Корректность | **К-4** сохранена: `07h stIpg=61` 72/72 после **v7.1** (синтет. агентская схема) |
| Документация | `09-scheme-cascade-mastering.md`; каскад ag→inv→dr→вне ИПГ; `4. Прочие` вне Mstrg |
| Диагностика | `07h1_perf_elements_chain5.sql`, `run_07h1_step.sh`; правило **60 сек** в `08-testing-strategy` |

### Проблемы

| # | Проблема | Статус |
|---|----------|--------|
| П-1 | **К-6 не достигнута**: `07h stIpg=46` >15 мин; `07h1-B/C/D` >60 сек | → Этап 9 |
| П-2 | Регрессия `07h stIpg=61` (72→36) после Этапа 8 | ✅ v7.1 |
| П-3 | `fnMasteringStIpgStCost_2606(46)` сам по себе >60 сек (164 контракта) | Этап 9 + возможно П6 |
| П-4 | ITVF `fn2`: CTE `schemeRows`/`mastering` re-eval ×4–5 (**УМ-2**) | → Этап 9 MSTVF |
| П-5 | Зависшие сессии `CREATE FUNCTION` / долгий `fn2` | `KILL` + `run_07h1_step.sh` |

**Следующий шаг:** Этап 9б — итерации **по одной стройке** с целевым временем (см. ниже).

**Замеры 07h2 (2026-06-11, `fnMasteringCstAgPnSh_2606`):**

| Группа | Контрактов | Пример | ms (Sh) | fn2 (07h1) |
|--------|------------|--------|---------|------------|
| stIpg=61 | 1 | cac=2102 | **2365** | **~9 с** (было ~41 с) |
| stIpg=46 | 164 | cac=371 | 6897 max / **~4200 ср.** (10 из 164) | **>90 с** |

---

## Этап 1 — Подготовка и вводные ✅

- [x] **1.1** Q1–Q4 отвечены (схема `stNet`, интерфейс `@ipgStKey int`, fallback, `ipgcrvUtPlGr`) ✅
- [x] **1.2** Проверка `fnStDownAll`; анализ стека `fnMasteringStIpgStCost`; цепь 5 выбрана ✅
- [x] **1.3** Эталонные COUNT зафиксированы; дефект Б на цепи 15 подтверждён ✅
- [x] **1.4** *(2026-06-11)* Анализ производительности завершён; оптимальный порядок этапов зафиксирован ✅  
  → `docs/development/notes/sql/26-0604/docs/07-performance-analysis.md`

---

## Этап 2 — Инфраструктурные таблицы ✅

- [x] **2.1** `ags.ipgChRlV` + `ags.fnIpgChRlVEnd`; цепи 5 и 15 заполнены; перекрытий нет ✅
- [x] **2.2** `ags.factDoc` + `ags.factDocCost`; 6 типов подклассов; `*_fdKey` в 6 таблицах ✅
- [x] **2.3** 6 триггеров синхронизации `factDocCost`; smoke-test OK ✅
- [x] **2.4** Бэкфилл: 79 755 factDoc; 112 142 factDocCost; 0 orphan ✅

---

## Этап 3 — Генератор дат ✅

- [x] **3.1** `fnIpgChDatsV(5)` → 17 дат; цепь 15: точка разрыва 2025-07-16 ✅

---

## Этап 4 — Функции лимитов и структуры затрат ✅

- [x] **4.1** `fnStCostIpgPn_2606`: точность decimal(23,8) вместо потери в `money` ✅
- [x] **4.2** `fnStCostRsIpgPn_2606`: фикс Деф.Б (actuality через `ipgChRlV`) + fallback `iuplpLim` ✅
- [x] **4.3** `fnStCostRa/RaCh/AgFee/Ralp/PrDoc/Mnrl_2606`: источник `factDocCost` (политика B+F) ✅  
  `07b_VERIFY`: RA 19 123 / 0 расх.; RaCh 772 / 0; AgFee/Ralp/PrDoc/Mnrl — 0 ✅
- [x] **4.4** `fnStCostRsCstAgPn_2606`: лимиты по строй-агент-кодам через `_2606`-подфункции ✅

---

## Этап 5 — Функции освоения: базовая версия ✅

> Базовые функции работоспособны и верифицированы. Используют LEGACY `fnMasteringPresRa` и др. —
> производительность неприемлема (42 мин для 164 контрактов). Замена — в Этапе 8.

- [x] **5.1** `fnMasteringCstAgPnSh_2606` + `fnMasteringCstAgPn_2606`: освоение по стройке; лимиты через `_2606` ✅
- [x] **5.2** `fnMasteringStIpgStCost_2606`: фикс Деф.А; `@ipgStKey`/`@stCostKey` nullable ✅
- [x] **5.3** Тест: `fnMasteringStIpgStCost_2606(21, 5, NULL, NULL)` — COUNT 799=799 ✅

---

## Этап 6 — fn2_2606: базовая версия (ITVF v1 → v7.1) ✅

- [x] **6.1** `fnIpgChRsltCstUtl2_2606` ITVF v1: метаданные, совместимость с `_2605` ✅
- [x] **6.2** `fnIpgChRsltCstUtlPercentBrn_2606`: адаптация из `_2605` ✅
- [x] **6.3** `07h stIpg=61` — **PASS** (после v7.1) ✅
- [x] **6.4** `07h stIpg=46` корректность (v7: raFactRalp + raFactStorage) — **PASS** ✅  
  `miss=0, extra=0, vdiff=0` (на момент v7, до регрессии/фикса v7.1)
- [x] **6.5** `07e` baseline (presented=0, lim=0) — **PASS** ✅
- [x] **6.7** v7.1: `ipgPnSchemePts` — синтетическая агентская схема как `fn_2408` ✅  
  Регрессия после Этапа 8: `07h stIpg=61` 72→36 строк; исправлено, **PASS 72/72**
- [ ] **6.6** `07f` полный PercentBrn — **отложен**; требует Этапов 9–10

---

## Этап 7 — Индексы производительности ✅

> Нулевой риск, без изменений кода. Применять перед Этапом 8.

- [x] **7.1** `CREATE INDEX IX_ipgStPn_St_Pn ON ags.ipgStPn (ipgspSt, ipgspPn);` ✅
- [x] **7.2** `CREATE INDEX IX_cstAgPnBranch_Cst ON ags.cstAgPnBranch (cstapbCstAgPn) INCLUDE (cstapbBranch, cstapbStart, cstapbEnd);` ✅

---

## Этап 8 — fnMasteringFact*_2606: функции факта через factDocCost ✅ (8.4 ❌)

> **Критический приоритет. Главный рычаг: ×70–140 (теория).**  
> Файлы: `03b1_CREATE_FUNCTION_fnMasteringFact_2606.sql`, `03c_*` + `MSSQL2012/`.

### 8.1 — Pres/Accp функции (~18 штук): замена LEGACY ✅

Структура каждой функции: аналог прототипа, но источник `factDocCost` через соответствующий `fnStCost*_2606`.

| Новая функция | Прототип (LEGACY) |
|---------------|-------------------|
| `fnMasteringPresRa_2606(dAll, cac, stCost, stNet, subAg)` | `fnMasteringPresRa` |
| `fnMasteringAccpRa_2606` | `fnMasteringAccpRa` |
| `fnMasteringPresRaMn_2606` | `fnMasteringPresRaMn` |
| `fnMasteringAccpRaMn_2606` | `fnMasteringAccpRaMn` |
| `fnMasteringPresAgFee_2606` | `fnMasteringPresAgFee` |
| `fnMasteringAccpAgFee_2606` | `fnMasteringAccpAgFee` |
| `fnMasteringPresAgFeeMn_2606` | `fnMasteringPresAgFeeMn` |
| `fnMasteringAccpAgFeeMn_2606` | `fnMasteringAccpAgFeeMn` |
| `fnMasteringPresRalp_2606` | `fnMasteringPresRalp` |
| `fnMasteringAccpRalp_2606` | `fnMasteringAccpRalp` |
| `fnMasteringPresRalpMn_2606` | `fnMasteringPresRalpMn` |
| `fnMasteringAccpRalpMn_2606` | `fnMasteringAccpRalpMn` |
| `fnMasteringAccpStor_2606` | `fnMasteringAccpStor` |
| `fnMasteringAccpStorMn_2606` | `fnMasteringAccpStorMn` |
| `fnMasteringAccpControl_2606` | `fnMasteringAccpControl` |
| `fnMasteringAccpControlMn_2606` | `fnMasteringAccpControlMn` |
| `fnMasteringAccpMnrl_2606` | `fnMasteringAccpMnrl` |
| `fnMasteringAccpMnrlMn_2606` | `fnMasteringAccpMnrlMn` |

### 8.2 — Ret/InProc/NotArr/PresAll функции (~25 штук): новые (Вариант 6А) ✅

Применено в БД: **46** объектов `fnMastering*_2606` (включая Pres/Accp/Ret/…).

| Группа | Функции | Фильтр `rsltOfConsider` |
|--------|---------|------------------------|
| RA returned | `fnMasteringRetRa_2606`, `fnMasteringRetRaMn_2606` | `'returned'` |
| RA inProcess | `fnMasteringInProcRa_2606`, `fnMasteringInProcRaMn_2606` | `'in process'` |
| RA notArrived | `fnMasteringNotArrRa_2606`, `fnMasteringNotArrRaMn_2606` | `'not arrived'` |
| RA PresAll | `fnMasteringPresAllRa_2606`, `fnMasteringPresAllRaMn_2606` | все строки |
| RA PrevYears | `fnMasteringPrevYr*_2606` (5 шт.) | `complianceY` |
| АВ returned | `fnMasteringRetAgFee_2606`, `fnMasteringRetAgFeeMn_2606` | `'returned'` |
| АВ inProcess | `fnMasteringInProcAgFee_2606`, `fnMasteringInProcAgFeeMn_2606` | `'in process'` |
| АВ notArrived | `fnMasteringNotArrAgFee_2606`, `fnMasteringNotArrAgFeeMn_2606` | `'not arrived'` |
| РАЛП returned | `fnMasteringRetRalp_2606`, `fnMasteringRetRalpMn_2606` | `'returned'` |
| РАЛП inProcess | `fnMasteringInProcRalp_2606`, `fnMasteringInProcRalpMn_2606` | `'in process'` |
| РАЛП notArrived | `fnMasteringNotArrRalp_2606`, `fnMasteringNotArrRalpMn_2606` | `'not arrived'` |

### 8.3 — Обновить `fnMasteringCstAgPnSh_2606` + `fnMasteringCstAgPn_2606` ✅

- [x] `fnMasteringCstAgPn_2606`: `fnMasteringPresRa_2606`, `RetRa_2606`, … (Вариант 6А) ✅
- [x] `fnMasteringCstAgPnSh_2606`: вызывает `fnMasteringCstAgPn_2606` (PresRa **внутри** CstAgPn, не в Sh) ✅
- [x] Повторное применение `03c` в БД 2026-06-11 — подтверждено ✅
- Один вызов `fnMasteringCstAgPn_2606(5,2102,…)` ≈ **12 ms** / 17 строк

### 8.4 — Приёмка производительности ❌ (К-6 не достигнута)

| Тест | Результат | Цель |
|------|-----------|------|
| `07h` stIpg=46 (полный) | **1576 с (~26,3 мин)**, 26434 строк ✅ завершён | < 60 сек |
| `07h1-A` fn_2408 вся цепь | **3,8 сек** ✅ | эталон |
| `07h1-B` `fnMasteringStIpgStCost_2606(46,…)` | **>60 сек** ❌ | < 60 сек |
| `07h1-C` `fn2_2606` stIpg=61 (1 контракт) | **~41 сек** ❌ | < 60 сек |
| `07h1-D` `fn2_2606` stIpg=46 | **>60 сек** ❌ | < 60 сек |

**Вывод:** замена LEGACY scalar на `_2606` **недостаточна** для К-6. Узкое место — **объём**
(`fnMasteringStIpgStCost` × 164 контракта + **×4–5 re-evaluation** CTE `schemeRows` в ITVF `fn2`).
Следующий рычаг — **Этап 9 (MSTVF v8)**.

**Инструменты диагностики (сессия 2026-06-11):**
- `07h1_perf_elements_chain5.sql` + `run_07h1_step.sh` (шаги V/A/B/C/D, лимит 60 сек, `KILL` при таймауте)
- Правило 60 сек → `08-testing-strategy.md §0`
- Документация каскада схем → `docs/09-scheme-cascade-mastering.md`

**Операционные замечания:**
- Долгие прогоны: `RAISERROR … WITH NOWAIT`; не ждать >1 мин без причины
- Зависшие сессии `CREATE FUNCTION` / `fn2` — `KILL` перед новым прогоном
- Метрика `sh_pres2606=0` **норма**: PresRa в `fnMasteringCstAgPn_2606`, Sh только делегирует

---

## Этап 9 — fn2_2606: MSTVF v8 ✅ / ⬜

> ITVF → MSTVF; материализация `@schemeRows`, `@raFact*`, `@branchCache` (в UDF только table variables, не `#temp`).  
> Файл: `04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql` v8 + `MSSQL2012/` (отложено).

- [x] **9.1** MSTVF + `@schemeRows` (один проход `mastering` → `@schemeRows`) ✅
- [x] **9.2** `@raFact2408`, `@raFactRalp`, `@raFactMnrl`, `@raFactStorage` ✅
- [x] **9.3** `@branchCache` вместо `fnCstAgPnBranch` ✅
- [ ] **9.4** `07h1-C` stIpg=61: **~9 с** ✅ (было ~41 с); **К-6** stIpg=46: fn2 полный **1576 с / 26434 строк** ❌ (цель <60 с)
- [ ] **9.5** `07h` stIpg=NULL **< 2 мин** — после 9б

**Вывод 9.4:** ускорение `fn2` за счёт MSTVF реально (×4–5 на малых группах), но **К-6 упирается в сумму `fnMasteringCstAgPnSh` × 164** (~4 с/стройка). Нужен Этап **9б**.

---

## Этап 9б — Производительность: одна стройка → группа 🔄

> **Текущий этап.** Смена стратегии: не ждать полный `stIpg=46`, а зафиксировать **целевое время на стройку**, добиваться его итерациями в `_2606`, затем масштабировать на группы.  
> Инструменты: `07h2_perf_contracts_stIpg46.sql`, `run_07h2_contract.sh`; корректность — `07h` по затронутым `stIpg`.

### Целевые времена (цепь 5, `MounthEndDate` 2022-09-30)

| Метрика | Формула / обоснование | **T0** (сейчас) | **T1** | **T2** | **T★** (К-6) |
|---------|----------------------|-----------------|--------|--------|--------------|
| `fnMasteringCstAgPnSh_2606` на стройку | `07h2`, 17 дат | 0,6–7 с | **≤1,5 с** | **≤0,5 с** | **≤0,3 с** |
| `fn2_2606` stIpg=61 (1 стр.) | `07h1-C` | ~9 с | **≤5 с** | **≤3 с** | **≤2 с** |
| `fn2_2606` stIpg=46 (164 стр.) | К-6 | **51 с** (v8.1) | ≤120 с ✅ | ≤60 с ✅ | **<60 с** ✅ |

`T★` для Sh: (60 с − ~7 с накладных fn2) / 164 ≈ **320 ms** на стройку (с запасом **300 ms**).

### Цикл итерации (одна стройка)

```
1. run_07h2_contract.sh <stIpg> [from] [to]  → ms по cac
2. Выбрать стройку: медленнее T1 (или эталон 2102 для stIpg=61)
3. Доработка _2606 (03b1 / 03c / 03d — не fn2, пока Sh не в цели)
4. Повтор 07h2 на той же стройке: 3 прогона подряд, разброс ≤20% → «устойчиво»
5. 07h stIpg затронутой группы → корректность PASS
6. Следующая стройка
```

### Критерий перехода к группам

| Уровень | Условие | Тест |
|---------|---------|------|
| **G0** | Эталон cac=2102 (stIpg=61): Sh ≤ **T1**, 3 устойчивых прогона | `07h2` + `07h` 61 |
| **G1** | Все стройки stIpg=46: Sh ≤ **T1**, ≥90% строек | `07h2` 46 ✅ **2026-06-11** (100% ≤607 ms) |
| **G2** | stIpg=46: Sh ≤ **T★** в среднем, p95 ≤ 2×T★ | `07h1-D` **<60 с** → **К-6** ✅ |
| **G3** | Крупные группы 27, 71, 31 | `07h` по таблице stIpg | ✅ vdiff=0, extra=0 (M.1 ожидаемый diff) |
| **G4** | Полная цепь | `07h` NULL **<2 мин** → **К-7** | ❌ **279,8 с** (v9.0); **К-7-прагматик** ✅ |

### Порядок групп после G0

`61` → `46` (по одной стройке, 07h2) → `46` (целиком) → `5,4,14` (по 5) → `30,21` → `27,71` → `NULL`.

### Очередь строек stIpg=46 (TOP по 07h2, после 9б.3, 2026-06-11)

| Приоритет | cac | код | ms (Sh) | Статус |
|-----------|-----|-----|---------|--------|
| 1 | **1574** | 051-2002394 | **607** | max |
| 2 | 2463 | 051-2000791 | 518 | |
| 3 | 1147 | 051-2001505 | 488 | |
| 4 | 4 | 022-2000815 | 485 | |
| 5 | 1473 | 051-2004672 | 476 | |
| … | **371** | 051-2002246 | **360** | было **7136** (#1) |

**07h2 stIpg=46 (164 стр.):** sum **35 616 ms**, avg **217 ms**, max **607 ms**, slow≥1 с = **0** → **G1 ✅**

Эталон «быстрой»: cac=**338** — в топе не фигурирует (≪360 ms).

### Диагностика cac=371 vs 338 (`07h3`, 2026-06-11)

| Показатель | 371 (slow) | 338 (fast) |
|------------|------------|------------|
| `ags.ra` | **83** | **1** |
| `ra_summ`+factDocCost | **62** | **0** |
| `fnMasteringCstAgPn` sh=2 | **6556 ms** | **4 ms** |
| `fnMasteringCstAgPnSh` | **7136 ms** | **632 ms** |

**Причина:** `masteringTrue=true` → ~44 scalar × 17 дат; RA-функции всё ещё **построчно** по `ags.ra` + `fnStCostRa_2606(ra_key)` — **П1 не доведён до set-based**.

**Резерв:** **П1+** (set-based `factDocCost` в RA-группе `fnMastering*Ra*_2606`), не П5/П6 на первом шаге.

- [x] **9б.1** Пилот: `fnMasteringPresRa_2606` set-based → 07h3 на cac=371 ✅ **2026-06-11**
  - Добавлен `ags.fnStCostFromFd_2606` (`03b0`); `fnStCostRa/RaCh_2606` рефакторинг
  - Set-based `fnMasteringPresRa_2606`: `@docs` → `@withFd` → distinct `fnStCostFromFd` → SUM
  - **Корректность:** `PresRa_2606(371, 2022-09-30) = 2669364.72` — **OK**
  - **07h3:** `PresRa` slow **25 ms** (было ~сотни ms внутри scalar-цикла); `CstAgPn sh=2` **6645 ms** (было 6556) — **без эффекта на итог**
  - **Вывод:** узкое место — остальные **11 RA-функций** + AgFee/Ralp/… (всё ещё scalar × 17 дат); → **9б.2**
- [x] **9б.2** RA-группа целиком (17 fn) → `fnMasteringRaCostSet_2606` ✅ **2026-06-11**
  - Ядро: `@dateMode` 0–4, `@statusMode` 0–4; все Pres/Accp/Ret/InProc/NotArr/PresAll/PrvY×5 — thin wrappers
  - **Корректность:** `PresRa=AccpRa=2669364.72`, `PresAllRa=17424719.58` на cac=371 — OK
  - **07h3 cac=371:** `CstAgPn sh=2` **7294 ms** (было 6556), `CstAgPnSh` **7094–7794 ms** (было 7136) — **без существенного выигрыша**
  - **Причина:** 12 RA × 17 дат = 204 независимых вызова; `PresAllRa` ~208 ms/дата (83 ra); узкое место сместилось на **AgFee/RRc** и дублирование fdKey-rollup
  - **Следующий резерв:** P6 (batch RA за дату) или set-based AgFee
- [x] **9б.2а** `fnMasteringRaBundle_2606` + внутренние резервы ✅ **2026-06-11**
  - **17 RA-колонок** за 1 вызов: 1× scan `ra`/`ra_change`, batch `ROW_NUMBER` fdKey, batch direct cost, short-circuit empty fdKey
  - `fnMasteringCstAgPn_2606` → `OUTER APPLY fnMasteringRaBundle_2606` (вместо 17 scalar × дату)
  - **Корректность:** все 17 колонок vs scalar — **OK** (cac=371, 2022-09-30)
  - **07h3 cac=371:** `CstAgPn sh=2` **4996 ms** (было 7294), `CstAgPnSh` **4875 ms** (было 7794); bundle **~265 ms**/дата
  - **07h3 cac=338:** CstAgPnSh **342 ms** (было 864)
- [x] **9б.3** Bundle AgFee/Ralp/PrDoc+Mnrl + cost-base кэш ✅ **2026-06-11**
  - `fnMasteringAgFeeBundle_2606` (10 col), `fnMasteringRalpBundle_2606` (8), `fnMasteringPrDocMnrlBundle_2606` (6)
  - DAG-hit: один `fnStUpAll` + batch `factDocCost` вместо scalar `fnStCostAgFee/Ralp/...` на строку
  - **`fnMasteringRaCostBase_2606` / `fnMasteringAgFeeCostBase_2606`** — CostSm 1× на вызов `CstAgPn`; агрегация по 17 дат из `@raCostBase`/`@afCostBase`
  - **Корректность:** RA Pres OK, AgFee/Ralp/PrDoc OK vs scalar
  - **07h3 cac=371:** `CstAgPn sh=2` **483 ms** (было 4996), `CstAgPnSh` **363 ms** (было 4755) — **T1 ≤1.5 с ✅**
  - **07h3 cac=338:** CstAgPnSh **79 ms**
  - **07h1-D fn2 stIpg=46:** **114 638 ms** (~115 с), 24 023 строк, 164 стройки (было **~1576 с** → **×13,7**)
  - **К-6 <60 с:** ещё не достигнут; среднее ~**700 ms**/стройка в fn2 (накладные + «лёгкие» стройки + RRc)
- **Вывод 9б.3 (целесообразность bundle + cost-base):**
  - **Bundle** (как `fnMasteringRaBundle_2606`) для AgFee/Ralp/PrDoc — **оправдан**: один scan + batch fdKey + один `fnStUpAll` вместо N×scalar `fnStCost*`
  - **Критический резерв** — не bundle колонок, а **`RaCostBase`/`AgFeeCostBase`**: CostSm 1× на вызов `CstAgPn`, 17 дат — фильтр из `@table` (~×10 на cac=371)
  - Ralp/PrDoc bundle — достаточно на 371 (мало строк); cost-base для них — только если 07h2 покажет узкие стройки с большим ralp/prDoc
  - **07h2 stIpg=46 (полный):** 164 стр., sum **35,6 с**, avg **217 ms**, max **607 ms** (cac=1574), **0** строек ≥1 с → **G1 ✅**
  - **Разрыв fn2 vs Sh:** fn2 **115 с** − Sh **36 с** ≈ **79 с** накладных (joins, RRc, прочие колонки fn2) — узкое место для **К-6**
  - Следующий шаг: **G2/К-6** — профиль fn2 (см. **07h4**), не Sh
- **07h4 fn2 profile** ✅ **2026-06-11**
  - **cac=1574:** RRc=**154**, factDoc=**223**, CstAgPnSh=**1007 ms** (новый max Sh)
  - **cac=371:** RRc=83, Sh=**370 ms**; **cac=338:** Sh=**75 ms**
  - **raFact2408** (RRc full year): **105 ms** — **не узкое место**
  - **StIpgStCost** stIpg=46: **36 410 ms** (≈ сумма 07h2)
  - **fn2** stIpg=46: **115 381 ms** → накладные fn2 **~79 с** (не RRc: ralp/mnrl/storage <15 ms)
  - **P5** `RRcTimeListBase`: **0** — приоритет низкий для К-6
  - **Следующий резерв:** CTE `withAccum` / раздувание строк (27 888→24 023), не P5
- **07h5 CTE profile** ✅ **2026-06-11**
  - **Корень ~79 с:** CTE `mastering` **3× re-eval** (UNION ALL ag/in/dr) → StIpgStCost **37 с × 3 ≈ 110 с**
  - `withAccum` / `ipgChContracts` / RRc — **<200 ms** суммарно
- **fn2 v8.1** — schemeRows через **CROSS APPLY** (1× mastering) ✅ **2026-06-11**
  - **07h1-D stIpg=46:** **51 022 ms** (было 115 381) → **К-6 <60 с ✅**
  - **_2605 presDiff=0, limDiff=0** stIpg=46 ✅
- **Верификация vs _2605 после 9б.3** (2026-06-11):
  - `07h stIpg=61` vs fn_2408: **PASS** (72/72, vdiff=0)
  - `07h stIpg=46` vs fn_2408: **FAIL** (6396 vs 5858 строк; 46 NULL↔0 presentedAccum) — ожидаемое отличие от _2605 (лишние «пустые» строки fn_2408)
  - **`fn2_2605` ↔ `fn2_2606` (правило 07e):** stIpg=**46** presDiff=**0**, limDiff=**0**; stIpg=**61** presDiff=**0**, limDiff=**0** ✅
  - cac=**371** m3/m9: совпадающие строки идентичны; _2606 даёт доп. месяцы (паритет fn_2408)
  - **Вывод:** по **presented/lim** (то, что потребляет _2605) — **соответствие есть**; 07f PercentBrn — ещё не прогонялся

---

## Этап 10 — fn2_2606 + PercentBrn: полная верификация ⬜

- [ ] **10.1** Тесты на цепи 5: `@ipgStKey=NULL/21`, `@stCostKey=NULL/212`; без задвоений
- [ ] **10.2** `07e` baseline после MSTVF: presented=0, lim=0
- [x] **10.3** `07f_COMPARE_PercentBrn_full_chain5.sql` — **v8.9** **PASS** (14447=14447, F.3 dedup **0**); пилот cac=371 **PASS** ✅
- **Разбор полного 07f (2026-06-12):**
  - **F.3 raw завышен:** GROUPING SETS даёт дубли `(dateRslt, ipgKey, cstapKey)` на агрегатах (63–65 строк/дата) → ложные 50k+ diff
  - **По дедуп-ключам (07f3):** only_06=2184, only_05=210, field_diff=218 (до v8.7); **v8.7** починил `ag_percentDev` (cac=849: 0.4602=0.4602)
  - **v8.7:** fn_2408 — все ИПГ цепи × 12 мес, RA без окна, `PARTITION BY ipgKey`; `ipgMasteringCombos` из ipgPn×ipgChRlV
  - **v8.8:** убрано безусловное сохранение all-NULL null-ipg «4. Прочие» (v8.4); NOT all-NULL дополнен agFee*; fn2 контракты **908=908**
  - **v8.9 (218 pctDev):** `storageSum`/`cctSum` в `ipgBase` из `cn_PrDocP` при `shShow` (fn_2408 stg/cct), не только mastering → **field_diff=0**; док: `docs/10-percentDev-218-diff-root-cause.md`
- **Диагностика PercentBrn cac=371 (2026-06-11):**
  - **Корень (лишние ИПГ):** fn2_2606 размножал RRc на **все ИПГ × 12 мес.**; _2605 — только **активная ИПГ** в окне `ipgActStr`–`ipgActEnd`
  - **v8.2:** RRc/Ralp/Mnrl JOIN + `allMonthsForIpg` ограничены окном ИПГ → **35→14** строк
  - **v8.3:** accum PARTITION **без ipgKey** (накопление через границу ИПГ) → **ag_percentDev совпал**
  - **v8.4:** сохранять null-ipg `4. Прочие`; **v8.5:** `@agFeeFact` в `nullIpgBase`
  - **v8.6 (EOMONTH @dt):** `extraBase`/`masExtraBase` давали **все 12 мес × ИПГ** (напр. ipg11 в апреле) → глобальный `MAX(dateRslt)` сдвигался на EOMONTH; **MONTH-окно ИПГ** как в fn2_2605 (стр. 296–307) → `07f1` @dt совпал, **07f пилот PASS**
- [x] **07h** stIpg=**61** vs fn_2408 — **PASS** ✅ **2026-06-11** (v8.1)
- [x] **07h** stIpg=**46** vs fn_2408 — **FAIL** (538 пустых строк iShKey=NULL; 46 NULL↔0) — **ожидаемо**; vs **_2605 pres/lim=0** ✅
- [ ] **10.4** `05_PercentBrn_2606`: тест COUNT на цепи 5 после `07f PASS`

---

## Этап 10.5 — К-7: профиль и оптимизация полной цепи 🔄

> **Старт 2026-06-11.** К-6 и К-8 достигнуты; К-7 — разрыв **×2,3** (272,6 с vs цель 120 с).

### Свежие замеры (v8.9, dev-БД)

| Тест | Цель | Факт |
|------|------|------|
| `07h1-D` fn2 stIpg=46 | < 60 с | **49,9 с**, 9 350 строк ✅ |
| `07h1-C` fn2 stIpg=61 | ≤ 2 с | **2,6 с**, 8 763 строк ✅ |
| `07h1-B` StIpgStCost stIpg=46 | — | **37,5 с**, 2 788 строк |
| `fn2` stIpg=NULL (К-7) | < 2 мин | **272,6 с**, 11 587 строк ❌ |
| `07f` PercentBrn | < 10 мин, PASS | **~5 мин**, PASS ✅ |

### Резервы П1–П6 (итог)

| Резерв | Статус |
|--------|--------|
| П1 + bundles + CostBase | ✅ |
| П2 MSTVF + schemeRows | ✅ |
| П3 @branchCache | ✅ |
| П4 индексы | ✅ |
| v8.1 1× mastering | ✅ |
| П5 RRcTimeListBase | ❌ (RRc ~105 мс — не узкое место) |
| П6 set-based CstAgPnSh | ⬜ (bundles закрыли G1/G2) |

### Приоритет 1 — закрыть К-7 (≈2,3× ускорение)

- [x] **10.5.1** `07h6_fn2_profile_stIpgNULL.sql` ✅ **2026-06-11**
  - StIpgStCost NULL: **197,9 с** / 11 560 строк — **~73%** времени fn2
  - `@raFact*`: **117 мс**; `ipgChContracts`: **25 мс**; `allMonths` 12×combo: **23 688** строк
  - fn2 NULL: **271,4 с** (v8.9) → **279,8 с** (v9.0 PrDoc)
- [x] **10.5.2** **G3** ✅ **2026-06-11** — `07h` stIpg=27/71/31:
  - M.4 extra=**0**, M.5 vdiff=**0** на совпавших; M.1/M.3 **меньше строк** fn2 vs fn_2408 — **ожидаемо** (как stIpg=46)
  - stIpg=27: 1783 vs 4716 (−2933); 71: 1400 vs 3600; 31: 742 vs 1908
- [x] **10.5.3** **fn2 v9.0** ✅ **2026-06-11**
  - `@raFactPrDoc` — 1× scan `cn_PrDocP` (storage + cct); `ipgChContracts` из fact
  - ❌ ранний MONTH-фильтр в CTE — **сломал 07f** (5723 diff); **откатан**
- [x] **10.5.4** Перепроверка v9.0:
  - К-6: **49,3 с**, 9 350 строк ✅
  - К-7: **279,8 с** ❌ (цель 120 с)
  - К-8: **07f PASS**, F.3 dedup **0** ✅ (~5,3 мин)

**Вывод 10.5:** узкое место К-7 — **`fnMasteringStIpgStCost_2606(NULL)` ~198 с** (680× Sh). Оптимизация fn2-CTE даёт **<5%**. Для К-7 <120 с нужен **П6** или кэш mastering — вне scope v9.0.

### Приоритет 2 — средний (параллельно / после 10.5)

- [x] **10.5.5** **Решение по К-7** ✅ **2026-06-11**
  - **К-7 строгая** (<120 с): ❌ не достигнута
  - **К-7-прагматик** (пакетный spMstrg): fn2 NULL **<5 мин** ✅ (**279,8 с**); fn2+PercentBrn **~10,5 мин** ✅ (<12 мин)
  - **Рекомендация:** переходить к **Этапу 11** (spMstrg_2606); К-7 строгая — backlog (П6 / materialized mastering)
- [x] **10.5.6** **П5** — не трогать ✅ (RRc **117 мс** в 07h6)
- [x] **10.5.7** **П6** — **отложен** ✅: 07h6 подтвердил доминирование **StIpgStCost**, не Sh per-contract
- [x] **10.5.8** **MSSQL2012/** — `04` v9.0 MSTVF + `05b`/`06` spMstrg ✅ **2026-06-12**
- [x] **10.5.9** Запись в `project-journal.json` ✅

---

## Этап 11 — spMstrg_2606 и таблицы ResultSet ✅

- [x] **11.1** `05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql` — `ags.spMstrg_2606_ResultSet1..7` ✅
- [x] **11.2** `06_CREATE_PROCEDURE_spMstrg_2606.sql` — шаблон `spMstrg_2605` → `_2606` + `PercentBrn_2606` ✅
- [x] **11.3** `@saveToTables=1` цепь 5: RS1=**14447**, RS4=**904**, ~**275 с** ✅
- [x] **11.4** `@saveToTables=0` — 7 рекордсетов, ~**262 с** ✅
- **Параметры:** `@ipgStKey int`, `@stCostKey int` (NULL = без фильтра); таблицы **только** `*_2606_ResultSet*`

---

## Этап 12 — Документация и приёмка ✅

- [x] **12.1** `docs/deployment/db-upgrade-spMstrg-2606.md` ✅
- [x] **12.2** `docs/deployment/db-upgrade-spMstrg-2606-deploy-day-checklist.md` ✅
- [x] **12.3** `MSSQL2012/` — полное зеркало 00–08 + `03b1` (50 fn, DROP+CREATE) ✅ **2026-06-12**
- [x] **12.4** `docs/solutions/spMstrg_2408_execution.md` — раздел `_2606` ✅
- [x] **12.5** `07_VERIFY_after.sql` PASS; journal `log-2026-06-12-001` ✅

**07_VERIFY_after (dev):** все объекты OK; fn2=11587; PercentBrn_2606=2605=14447; RS1=14447, RS4=904.

---

## Этап 13 — Исправление `ras_work` → stCost **195** (не 182) ✅

> **Контекст (2026-06-13):** в `01c`/`01d` плоское поле `ras_work` (Excel «СМР») ошибочно маппилось на **182**; канон RA: **212=172+187+195**. Регрессия `_2606`: **8 674** RA с `_2606(182)>0` при `legacy(182)=0`.  
> **План:** `docs/development/notes/sql/26-0604/docs/11-ra-work-stCost195-fix-plan.md`  
> **Применено на dev:** 2026-06-13 — `01c` + `01d1`; `01d1`: DELETE 3664, UPDATE 6117; `flat_work_at_182=0`.

### 13.0 — Анализ и фиксация (read-only) ✅

- [x] **13.0.1** Подтверждено: `ra_summCt` 7050/7051 → 212=172+187+**195**; `ras_work`=Ct@195 (3350/3350)
- [x] **13.0.2** Объём миграции `factDocCost`: RaSumm@182 **8775**, дубли 182+195 **3350**; RaChange@182 **1006**
- [x] **13.0.3** `07i` lim additive stIpg=46 — **PASS** (лимиты не затронуты)
- [x] **13.0.4** Документ плана: `docs/11-ra-work-stCost195-fix-plan.md` ✅

### 13.1 — SQL: триггеры и бэкфилл ✅

- [x] **13.1.1** `01c_CREATE_TRIGGER_factDoc_sync.sql`: `ras_work`/`raсs_work` → **195**; набор ключей **212/195/172/187**
- [x] **13.1.2** `01d_BACKFILL_factDoc.sql`: шаг 3 — то же (для чистой установки)
- [x] **13.1.3** `01d1_FIX_factDocCost_ra_work_stCost.sql` — миграция (DELETE 3664, UPDATE 6117; backup `ags._backup_fdco_182_2606`)
- [x] **13.1.4** `MSSQL2012/01c`, `01d`, `01d1` — зеркало
- [x] **13.1.5** Smoke: INSERT `ra_summ` с work>0 → `factDocCost@195`, не @182

### 13.2 — Тесты и приёмка ✅

- [x] **13.2.1** `07j_COMPARE_stCost_fact_additive_chain5.sql` — FACT: `pres/accp@212 = @172+@187+@195`
- [x] **13.2.2** `07j` gate: `regression_182` = 0 (stIpg=61, 46)
- [x] **13.2.3** `07i` повтор stIpg=46 — LIM additive **PASS**
- [x] **13.2.4** `07b_VERIFY_fnStCost_2606.sql` — G-stCost195 + исключение Ct@182 flat
- [ ] **13.2.5** `07h` stIpg=61, 46 — регрессия pres/lim
- [ ] **13.2.6** `07_VERIFY_after.sql` на dev после 01d1

### 13.3 — Документация и деплой ✅

- [x] **13.3.1** `05-fact-stcost-map.md`, `03-design-decisions.md` §9/§12 — целевой маппинг
- [x] **13.3.2** `db-upgrade-spMstrg-2606.md` + deploy checklist — шаг `01d1`
- [x] **13.3.3** `08-testing-strategy.md` — порядок 07j→07i→07b

### 13.4 — Excel / Java (Type 5), чтобы ошибка не вернулась ✅

- [x] **13.4.1** `type5-post-apply-ra-sanity.sql` §D — gate `factDocCost@195`, не @182 для новых RA
- [x] **13.4.2** `audit-log-vba-to-java-mapping.md` — семантика work=СМР=195
- [x] **13.4.3** `type5-manual-verification-report-template.md` — чеклист post-apply
- [ ] **13.4.4** *(рекоменд.)* Java: интеграционный тест reconcile → `factDocCost` @195
- [ ] **13.4.5** *(этап 2)* синхронизация `ra_summCt` из flat при reconcile

---

## Контрольные точки

| Точка | Условие | Статус |
|-------|---------|--------|
| К-1 | Подготовка, Q1–Q4, анализ производительности завершён | ✅ |
| К-2 | `ipgChRlV` + `factDoc`/`factDocCost` заполнены; `fnStCost*_2606` верифицированы | ✅ |
| К-3 | `fnMasteringStIpgStCost_2606(21,5,NULL,NULL)` — COUNT 799=799 | ✅ |
| К-4 | `fn2_2606` v1: 07h stIpg=46,61 PASS; 07e PASS | 🔄 **перепроверка 2026-06-11** |
| К-5 | Индексы `IX_ipgStPn_St_Pn`, `IX_cstAgPnBranch_Cst` добавлены | ✅ |
| К-6 | 07h stIpg=46 **< 60 сек** | ✅ fn2 **49,3 с** (v9.0); Sh **37,5 с** (v8.9) |
| К-7 | 07h NULL **< 2 мин** | ❌ **279,8 с**; **К-7-прагматик** <5 мин ✅ |
| К-8 | 07f PASS, < 10 мин | ✅ v9.0 **PASS** (F.3 dedup=0); ~5,3 мин |
| К-9 | `spMstrg_2606`: RS1 полный; RS4–RS7 при `'2022-09-30'` | ✅ RS1=14447; RS4=904 |
| К-10 | Пакет передан: `db-upgrade.md` + чеклист + `MSSQL2012/` | ✅ |
| **К-11** | stCost RA: `ras_work`→**195**; `01d1` + `07j` PASS; `regression_182=0` | ✅ этап 13 **2026-06-13** |

---

## Состав SQL-пакета (`docs/development/notes/sql/26-0604/`)

| Файл | Этап | Статус |
|------|------|--------|
| `00_VERIFY_before.sql` | 1 | ✅ |
| `01_CREATE_TABLE_ipgChRlV.sql` | 2 | ✅ |
| `01b_CREATE_TABLE_factDoc.sql` | 2 | ✅ |
| `01c_CREATE_TRIGGER_factDoc_sync.sql` | 2 | ✅ work→195 |
| `01d_BACKFILL_factDoc.sql` | 2 | ✅ work→195 |
| `01d1_FIX_factDocCost_ra_work_stCost.sql` | **13** | ✅ dev 2026-06-13 |
| `07i_COMPARE_stCost_additive_chain5.sql` | **13** | ✅ lim PASS stIpg=46 |
| `07j_COMPARE_stCost_fact_additive_chain5.sql` | **13** | ✅ fact PASS stIpg=46 |
| `02_CREATE_FUNCTION_fnIpgChDatsV.sql` | 3 | ✅ |
| `03a0_CREATE_FUNCTION_fnStCostIpgPn_2606.sql` | 4 | ✅ |
| `03a_CREATE_FUNCTION_fnStCostRsIpgPn_2606.sql` | 4 | ✅ |
| `03b0_CREATE_FUNCTION_fnStCost_2606.sql` | 4, **9б.1** | ✅ + `fnStCostFromFd_2606` |
| `03b_CREATE_FUNCTION_fnStCostRsCstAgPn_2606.sql` | 4 | ✅ |
| `03c_CREATE_FUNCTION_fnMasteringCstAgPnSh_2606.sql` | 8.3 | ✅ в БД |
| `03d_CREATE_FUNCTION_fnMasteringStIpgStCost_2606.sql` | 5 | ✅ |
| `00-perf-indexes.sql` | **7** | ✅ |
| `03b1_CREATE_FUNCTION_fnMasteringFact_2606.sql` | **8.1–8.2** | ✅ в БД |
| `07h1_perf_elements_chain5.sql`, `run_07h1_step.sh` | 8.4 | ✅ |
| `07h2_perf_contracts_stIpg46.sql`, `run_07h2_contract.sh` | **9б** | ✅ |
| `07h3_diag_contract_profile.sql` | **9б** | ✅ |
| `07h4_fn2_profile_stIpg46.sql` | **G2/К-6** | ✅ |
| `07h5_fn2_cte_profile.sql` | **G2/К-6** | ✅ |
| `07h6_fn2_profile_stIpgNULL.sql` | **10.5/К-7** | ✅ |
| `docs/09-scheme-cascade-mastering.md` | док | ✅ |
| `04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql` | **9, 10.5** | ✅ v9.0; MSSQL2012 — ✅ |
| `07f3_analyze_pb_diff_chain5.sql` | **10** | ✅ дедуп-анализ ключей |
| `docs/10-percentDev-218-diff-root-cause.md` | **10** | ✅ корневая причина 218 pctDev |
| `07f1_diagnose_dt_cac371.sql` | **10** | ✅ диагностика @dt/EOMONTH |
| `05_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2606.sql` | 6 | ✅ |
| `05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql` | 11 | ✅ |
| `06_CREATE_PROCEDURE_spMstrg_2606.sql` | 11 | ✅ |
| `07_VERIFY_spMstrg_2606_chain5.sql` | 11 | ✅ |
| `MSSQL2012/04` … `06` | 11–12 | ✅ v9.0 + spMstrg |
| `07_VERIFY_after.sql` | 12 | ✅ |
| `08_ROLLBACK.sql` | 1–12 | ✅ (дополнять) |
| `MSSQL2012/` | все | ✅ / ⬜ зеркалить |

---

## Справочные документы

| Документ | Содержание |
|----------|-----------|
| `docs/.../docs/07-performance-analysis.md` | Анализ производительности; предложения П1–П6 |
| `docs/.../docs/08-testing-strategy.md` | **Стратегия тестирования: порядок stIpg, скрипты, правила безопасности** |
| `docs/.../docs/04-computation-map.md` | Карта вычислений (§Шаг 5 пересмотрен: LEGACY → `_2606`) |
| `docs/.../docs/05-fact-stcost-map.md` | Соответствие полей и stcKey для факт-функций |
| `docs/.../docs/03-design-decisions.md` | Архитектурные решения 1–7 |
| `docs/.../docs/09-scheme-cascade-mastering.md` | Каскад схем, `4. Прочие` вне Mstrg |
| `docs/.../docs/10-percentDev-218-diff-root-cause.md` | Корневая причина 218 расхождений `ag_percentDev` (v8.9) |
| `docs/.../docs/diag-07h-stIpg61-half-rows.md` | Диагностика v7.1 (синтет. агентская схема) |
| `docs/.../docs/11-ra-work-stCost195-fix-plan.md` | **План исправления ras_work→195, миграция factDocCost, Excel/Java** |
