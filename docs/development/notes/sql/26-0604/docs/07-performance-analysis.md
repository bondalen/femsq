# Анализ производительности стека `_2606`

**Дата:** 2026-06-11  
**Автор:** Александр  
**Контекст:** Запрос на комплексный анализ резервов повышения быстродействия перед продолжением разработки.  
**Наблюдение-триггер:** `stIpg=46` (164 контракта) — время выполнения `fn2_2606` = **2 553 сек (~42 мин)**; полная цепь 5 (680 контрактов) — ожидаемо ~3 часа.

---

## 1. Архитектура стека: цепочка вызовов

```
fn2_2606  (fnIpgChRsltCstUtl2_2606) — ITVF
  │
  ├── raFact2408 CTE ─────────────────────→ VIEW ags.RRcTimeList  ⚠️ (VIEW, нет индексов)
  │                                              UNION ALL: ags.ra (49K) + ags.ra_summ (36K)
  │
  ├── mastering CTE ──→ fnMasteringStIpgStCost_2606  (ITVF)
  │                        │
  │                        └── CROSS APPLY fnMasteringCstAgPnSh_2606  (MSTVF)  × 680 контрактов
  │                                   │
  │                                   ├── 3× INSERT (схемы ag=2 / in=1 / dr=3)
  │                                   └── каждый → fnMasteringCstAgPn_2606  (MSTVF)
  │                                                   │
  │                                                   ├── fnIpgChDatsV(5) → 17 дат
  │                                                   ├── fnStCostRsCstAgPn_2606 → лимиты  ✅ factDocCost
  │                                                   │
  │                                                   └── 22 LEGACY scalar UDF за каждую дату:
  │                                                         fnMasteringPresRa    × 4  → ags.ra + fnStCostRa (LEGACY DAG)
  │                                                         fnMasteringAccpRa    × 4  → ags.ra + fnStCostRa (LEGACY DAG)
  │                                                         fnMasteringPresAgFee × 2  → ags.ogAgFeeP
  │                                                         fnMasteringAccpAgFee × 2  → ags.ogAgFeeP
  │                                                         fnMasteringPresRalp  × 2  → ags.ralp
  │                                                         fnMasteringAccpRalp  × 2  → ags.ralp
  │                                                         fnMasteringAccpStor  × 2  → ags.cn_PrDocP
  │                                                         fnMasteringAccpControl × 2 → ags.cn_PrDocP (acnt=30)
  │                                                         fnMasteringAccpMnrl  × 2  → ags.cstAgPnMnrl
  │
  ├── schemeRows CTE  ←──── ссылается на mastering → RE-EVALUATED ×4–5 раз (ITVF не материализует)
  │     ├── ipgSchemeLim   ← GROUP BY schemeRows
  │     ├── allMonthsForIpg ← CROSS JOIN ← ipgSchemeCombo ← schemeRows
  │     ├── extraBase       ← EXISTS (schemeRows)
  │     └── masExtraBase    ← EXISTS + NOT EXISTS (schemeRows)
  │
  └── fnCstAgPnBranch(scalar) × N строк в выводе  ⚠️ (нет индекса на cstApbCstAgPn)
```

---

## 2. Ключевые параметры БД

| Объект | Тип | Строк | Индексы |
|--------|-----|------:|---------|
| `ags.RRcTimeList` | **VIEW** (UNION ALL) | 52 526 | **Нет** |
| `ags.ra` | Таблица | 49 479 | PK + НомерОтчётаОдинЗаПериод |
| `ags.ra_summ` | Таблица | 35 851 | PK (ras_fdKey заполнен) |
| `ags.factDocCost` | Таблица | 112 142 | PK + UQ(fdcoFd, fdcoStCost) ✅ |
| `ags.cstAgPnBranch` | Таблица | 1 015 | **PK только по суррогатному ключу** |
| `ags.ipgStPn` | Таблица | 8 719 | **PK только по ipgspKey** |
| Контрактов в цепи 5 | — | 680 | — |
| Дат в fnIpgChDatsV(5) | — | 17 | — |

---

## 3. Узкие места (ранжированы по вкладу)

### 🔴 УМ-1 — 22 LEGACY scalar UDF за каждую дату-строку (≈80–90% времени)

**Масштаб:**

| Фактор | Значение |
|--------|----------|
| Контрактов × схем × дат | 680 × 3 × 17 = 34 680 итераций |
| Scalar UDF вызовов на итерацию | 22 |
| **Итого UDF вызовов (полная цепь 5)** | **762 960** |
| Каждый вызов: сканирует `ags.ra` (49K) | + вызывает `fnStCostRa` (DAG обход `ra_summ` 36K) |
| Наблюдаемое время: stIpg=46 (164 контр.) | 2 553 сек |
| Расчётное время полной цепи 5 | ~10 000–12 000 сек (2.8–3.3 часа) |

**Причина:** `fnMasteringCstAgPn_2606` вызывает LEGACY-функции (`fnMasteringPresRa`, `fnMasteringAccpRa` и др.),
которые:
1. Сканируют `ags.ra` (49K строк) по `ra_cac` + `year(ra_datePeriod)`
2. Для каждой найденной строки вызывают `fnStCostRa(ra_key, stCost, stNet)` — рекурсивный обход DAG-дерева `stCost` через `ra_summ`

**Критический факт:** `factDocCost` (112K строк) **уже заполнен** бэкфиллом (шаг 1b.3 ✅).
Новая функция `fnStCostRa_2606` **уже создана и протестирована** (шаг 1b.4 ✅).  
В `04-computation-map.md §Шаг 5` было записано: «существующие скалярные функции — **не меняются**».  
**Это решение необходимо пересмотреть.** Для производительности функции должны быть заменены.

### 🔴 УМ-2 — CTE re-evaluation в `fn2_2606` ITVF (×4–5 множитель)

SQL Server не материализует CTEs в ITVF. `schemeRows` (→ `mastering` → `fnMasteringStIpgStCost_2606`)
вычисляется несколько раз:

| CTE | Причина re-evaluation |
|-----|-----------------------|
| `ipgSchemeLim` | GROUP BY schemeRows |
| `allMonthsForIpg` | CROSS JOIN ← ipgSchemeCombo ← schemeRows |
| `extraBase` | EXISTS (SELECT 1 FROM schemeRows) |
| `masExtraBase` | EXISTS + NOT EXISTS (schemeRows) |

**Итого: 4–5 вызовов `fnMasteringStIpgStCost_2606`** вместо одного.

### 🟡 УМ-3 — `RRcTimeList` — VIEW без индексов

`RRcTimeList` — это VIEW (UNION ALL `ags.ra` + `ags.raCs` + JOIN `ra_summ` + `cstAgPn`),
у которого **не может быть индексов** в текущем виде (не индексируемый VIEW из-за UNION ALL).  
Каждый доступ к нему → полное пересоздание результата.

Используется в fn2_2606 CTE `raFact2408` → умножается на CTE re-evaluation.

### 🟡 УМ-4 — `fnCstAgPnBranch` scalar UDF per row

Вызывается per-row в `nullIpgBase`, `ipgBase`, `extraBase`, `masExtraBase`.  
Таблица `cstAgPnBranch` (1015 строк) имеет только PK по суррогатному ключу —
нет индекса на `(cstapbCstAgPn)`.

### 🟢 УМ-5 — Отсутствующие индексы

| Таблица | Отсутствующий индекс | Где нужен |
|---------|----------------------|-----------|
| `ipgStPn` | `(ipgspSt, ipgspPn)` | EXISTS в fnMasteringStIpgStCost_2606 |
| `cstAgPnBranch` | `(cstapbCstAgPn)` INCLUDE(...) | fnCstAgPnBranch + CTE-замена |

---

## 4. Предложения по оптимизации

### П1 — `03b1`: Новые `fnMasteringFact*_2606` через `factDocCost` (**главный рычаг, ×70–140**)

**Суть:** создать версии `_2606` для всех legacy scalar UDF:

| Функция новая | Прототип (legacy) | Источник данных |
|---------------|-------------------|-----------------|
| `fnMasteringPresRa_2606` | `fnMasteringPresRa` | `factDocCost` (через `fnStCostRa_2606`) |
| `fnMasteringAccpRa_2606` | `fnMasteringAccpRa` | то же |
| ... (× 22 функции для Pres/Accp) | | |
| `fnMasteringRetRa_2606` | — (новая) | `factDocCost` + `rsltOfConsider='returned'` |
| `fnMasteringInProcRa_2606` | — (новая) | `factDocCost` + `rsltOfConsider='in process'` |
| ... (× 25 функций для Ret/InProc/NotArr = Вариант 6А) | | |

**Все эти функции объединяются в `03b1_CREATE_FUNCTION_fnMasteringFact_2606.sql`.**

После создания — обновить `fnMasteringCstAgPnSh_2606` / `fnMasteringCstAgPn_2606`
для вызова новых функций вместо legacy.

**Ожидаемый выигрыш:**

| | До | После П1 |
|--|----|----|
| Стоимость одного scalar UDF | ~14 мс (скан `ags.ra` 49K + DAG `ra_summ` 36K) | ~0.1–0.2 мс (UQ-индекс `factDocCost`) |
| stIpg=46 (164 контракта) | ~2 553 сек | **~18–36 сек** |
| Полная цепь 5 (×5 re-eval) | ~10 000–12 000 сек | **~75–150 сек** |
| **Ускорение** | | **×70–140** |

**Зависимости:** `ras_fdKey` в `ra_summ` заполнен (35 851 / 35 851 ✅), `factDocCost` заполнен (112 142 ✅).

**Важно:** П1 одновременно реализует **Вариант 6А** из `04-computation-map.md` (новые функции `Ret*`, `InProc*`, `NotArr*`), ранее запланированный как отдельный этап. Это позволяет совместить функциональную и производительностную доработку.

---

### П2 — MSTVF-конверсия `fn2_2606` (**×4–5 дополнительно**, уже в плане)

**Суть:** конвертировать `fnIpgChRsltCstUtl2_2606` из ITVF в MSTVF,
материализовать `schemeRows` в `#temp`-таблицу → устранить re-evaluation.

**Дополнительно совместить с:**
- П3 (CTE-кэш вместо `fnCstAgPnBranch`)
- Добавление `#raFact2408` как #temp для устранения повторного пересчёта VIEW

**Ожидаемый выигрыш (в сочетании с П1):**

| | После П1 | После П1 + П2 |
|--|----------|----------------|
| stIpg=46 | ~18–36 сек | **~4–8 сек** |
| Полная цепь 5 | ~75–150 сек | **~15–30 сек** |

---

### П3 — CTE-кэш вместо `fnCstAgPnBranch` scalar UDF (**быстрый выигрыш**)

**Суть:** в начало `fn2_2606` добавить CTE:

```sql
branchCache AS (
    SELECT b.cstapbCstAgPn, MAX(b.cstapbBranch) AS branch
    FROM ags.cstAgPnBranch b
    WHERE (b.cstapbEnd IS NULL OR b.cstapbEnd >= CAST(GETDATE() AS date))
      AND (b.cstapbStart IS NULL OR b.cstapbStart <= CAST(GETDATE() AS date))
    GROUP BY b.cstapbCstAgPn
)
```

Заменить все вызовы `ags.fnCstAgPnBranch(GETDATE(), x.cstAgPnKey)` на LEFT JOIN к `branchCache`.  
Выигрыш: однократный хэш-join 1015 строк вместо row-by-row scalar UDF.  
Можно совместить с П2 (в рамках MSTVF-конверсии).

---

### П4 — Индексы на горячих таблицах (**нулевой риск, немедленный эффект**)

```sql
-- Для DAG-фильтрации по stIpg в fnMasteringStIpgStCost_2606
CREATE INDEX IX_ipgStPn_St_Pn ON ags.ipgStPn (ipgspSt, ipgspPn);

-- Для fnCstAgPnBranch (и будущего CTE-кэша)
CREATE INDEX IX_cstAgPnBranch_Cst ON ags.cstAgPnBranch
    (cstapbCstAgPn) INCLUDE (cstapbBranch, cstapbStart, cstapbEnd);
```

Применять в первую очередь — нет зависимостей, не требуют изменений кода.

---

### П5 — Материализация `RRcTimeList` → реальная таблица (среднесрочная перспектива)

Создать `ags.RRcTimeListBase` как реальную таблицу с индексами:

```sql
CREATE TABLE ags.RRcTimeListBase (
    ra_period int, ra_cac int, typeGr varchar(19),
    rsltOfConsider varchar(11), raKey int, ra_org_sender int,
    ras_key int, ras_total money, ras_work money, ras_equip money, ras_others money,
    -- ... другие колонки как в VIEW
    INDEX IX_RLBmat_cac_period (ra_cac, ra_period) INCLUDE (typeGr, rsltOfConsider, ras_total, ...)
);
```

Поддерживается триггерами на `ags.ra`, `ags.ra_summ`, `ags.raCs`.  
Устраняет полное пересоздание VIEW при каждом обращении.

**Когда актуально:** после П1+П2, если время всё ещё не устраивает.  
Триггеры на транзакционные таблицы требуют тщательного тестирования.

---

### П6 — Set-based рефакторинг `fnMasteringCstAgPnSh_2606` (стратегический горизонт)

Заменить паттерн «CROSS APPLY MSTVF × 680 контрактов» на единый set-based запрос:
- Вместо 680 последовательных вызовов MSTVF — один JOIN всех контрактов к `factDocCost`
- Позволяет SQL Server использовать параллелизм
- После П1 это реализуемо: все источники данных — таблицы с индексами

**Оценка:** дополнительно ×5–20. **Усилие:** высокое (~35KB кода на переписку).  
**Когда рассматривать:** после П1+П2, при необходимости дальнейшего ускорения.

---

## 5. Сводная таблица приоритетов

| № | Предложение | Выигрыш | Усилие | Риск | Файл |
|---|-------------|---------|--------|------|------|
| П4 | Индексы ipgStPn, cstAgPnBranch | ×1.1–1.3 | Минимальное | Нулевой | `00-perf-indexes.sql` |
| П1 | `fnMasteringFact*_2606` через factDocCost | **×70–140** | Среднее | Низкий | `03b1_CREATE_FUNCTION_fnMasteringFact_2606.sql` |
| П2 | MSTVF fn2_2606 + #temp schemeRows | ×4–5 (к П1) | Среднее | Низкий | `04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql` (v8) |
| П3 | CTE-кэш вместо fnCstAgPnBranch | ×1.1–1.2 | Низкое | Мин. | (совместить с П2) |
| П5 | Материализация RRcTimeList | ×2–5 (к П1+П2) | Среднее | Средний | `00-perf-rrcmat.sql` |
| П6 | Set-based fnMasteringCstAgPnSh_2606 | ×5–20 (к П1+П2) | Высокое | Средний | (будущий релиз) |

---

## 6. Ожидаемая производительность после П1+П2+П3+П4

| Сценарий | Сейчас | После П1+П2+П3+П4 |
|----------|--------|---------------------|
| stIpg=46 (164 контракта) | ~42 мин | **~10–30 сек** |
| Полная цепь 5 (680 контр.) | ~2.8–3.3 часа | **~40–90 сек** |
| Совокупный коэффициент | — | **~100–200×** |

---

## 7. Влияние на план разработки

### Пересмотр `04-computation-map.md §Шаг 5`

Строка «существующие скалярные функции — **не меняются**» была корректна функционально,
но **приводит к неприемлемой производительности**.  
**Принятое решение:** заменить LEGACY scalar UDF на `_2606`-версии, читающие `factDocCost`.  
Это одновременно реализует Вариант 6А (Ret/InProc/NotArr) и решает проблему производительности.

### Новый оптимальный порядок этапов

```
0.perf  → П4 (индексы) — немедленно
03b1    → fnMasteringFact*_2606 — ГЛАВНЫЙ рычаг ×70–140
03c-upd → обновить fnMasteringCstAgPnSh_2606 для вызова _2606 функций
04.perf → П2+П3: MSTVF fn2_2606 + CTE-кэш fnCstAgPnBranch
bench   → 07h stIpg=46: цель <30 сек; 07h NULL: оценить полное время
...     → затем 4.2–07f, Этапы 5–7
```

---

---

## 8. Актуальное состояние после П1–П4 и этапа 10.5 (2026-06-15)

### 8.1. Замеры v9.0 (dev FishEye, цепь 5)

| Сценарий | Цель | Факт | Статус |
|----------|------|------|--------|
| fn2 stIpg=46 (164 контракта) | < 60 с | **49,3 с** | ✅ К-6 |
| fn2 stIpg=61 | ≤ 2 с | **2,6 с** | ✅ |
| fn2 stIpg=NULL (полная цепь) | **< 120 с** | **279,8 с** | ❌ К-7 строгая |
| spMstrg_2606 (fn2 + PercentBrn) | < 12 мин | **~10,5 мин** | ✅ пакетный режим |
| `07f` PercentBrn | PASS | PASS (~5,3 мин) | ✅ К-8 |

### 8.2. Профиль fn2 stIpg=NULL (`07h6`, v9.0)

| Компонент | Время | Доля |
|-----------|------:|-----:|
| `fnMasteringStIpgStCost_2606(NULL)` | **197,9 с** | **~71%** |
| fn2 overhead (accum, `allMonthsForIpg`, joins) | **~82 с** | **~29%** |
| `@raFact*` (RRc, ralp, mnrl, PrDoc) | **117 мс** | <1% |
| `ipgChContracts` | **25 мс** | <1% |
| **Итого fn2 NULL** | **279,8 с** | 100% |

**Вывод:** резервы П1–П4 и v8.1/v9.0 исчерпаны для сценария stIpg=46; для stIpg=NULL остаётся разрыв **×2,3** до К-7.

### 8.3. Ограничения приёмки (2026-06-15)

| Ограничение | Следствие |
|-------------|-----------|
| Клиент **MS Access** | app-level parallelism (N параллельных вызовов fn2 по stIpg) **недоступен** |
| Многократный пересчёт в течение дня после Excel | persistent cache mastering **неприемлем** (устаревание данных) |
| Продуктив **SQL Server 2012 SP4** | индексы на table variables в UDF **недоступны**; оптимизация — через SP + `#temp` |

**Принято:** все усилия по К-7 строгой — **только в стеке `_2606`** (функции, процедуры, индексы). См. Решение 13 в `03-design-decisions.md`.

---

## 9. Оставшиеся узкие места (анализ кода, 2026-06-15)

### УМ-6 — `fnMasteringRalpBundle_2606` / `fnMasteringPrDocMnrlBundle_2606`: 17× на контракт

В `fnMasteringCstAgPn_2606` RA и AgFee оптимизированы (этап 9б): `@raCostBase` / `@afCostBase` строятся **1×**, даты применяются inline.

**Ralp и PrDocMnrl не оптимизированы** — `OUTER APPLY` на каждую из 17 дат:

```sql
OUTER APPLY ags.fnMasteringRalpBundle_2606(d.dAll, @cstAgPn, ...) rl
OUTER APPLY ags.fnMasteringPrDocMnrlBundle_2606(d.dAll, @cstAgPn, ...) pm
```

Каждый вызов bundle сканирует `ags.ralp` / `ags.cn_PrDocP` / `ags.cstAgPnMnrl` с нуля (дата фильтруется только в финальной агрегации).

**Масштаб:** 17 дат × 680 контрактов = **11 560 вызовов** `fnMasteringRalpBundle_2606` на полную цепь.

### УМ-7 — отсутствие индексов на горячих FK-полях

| Таблица | Поле | Где используется | Строк |
|---------|------|------------------|------:|
| `ags.ra` | `ra_cac` | `fnMasteringRaCostBase_2606` | 49 479 |
| `ags.ra_change` | `raс_ra` | JOIN к `ra` | — |
| `ags.ra_summ` | `ras_ra` | batch lookup `ras_fdKey` | 35 851 |
| `ags.ralp` | `ralpCstAgPn` | `fnMasteringRalpBundle_2606` | — |
| `ags.cn_PrDocP` | `pdpCstAgPn` | `fnMasteringPrDocMnrlBundle_2606` | — |
| `ags.cstAgPnMnrl` | `amCstAgPn` | то же | — |

Без индекса по `ra_cac`: **49K scan × 680 вызовов** ≈ 33,5M обходов строк только для RA CostBase.

### УМ-8 — fn2 overhead: `@schemeRows` без индекса

`fn2_2606` (MSTVF) материализует `@schemeRows` в table variable **без индексов**.
CTE `allMonthsForIpg` = `ipgSchemeCombo × mmmm(12)` (**23 688** строк) LEFT JOIN `@schemeRows` (**11 560** строк) — hash join без seek.

**Доля:** ~82 с (29% fn2 NULL). Устраняется конверсией fn2 в SP с `#schemeRows` + составным индексом.

### УМ-9 — ITVF `fnMasteringStIpgStCost_2606` + CROSS APPLY × 680

`fnMasteringStIpgStCost_2606` — ITVF с `CROSS APPLY fnMasteringCstAgPnSh_2606` по каждому контракту.
680 последовательных вызовов MSTVF; параллельный план внутри одного запроса **невозможен** (MSTVF serializes).

Полный set-based рефакторинг (исторический П6) — высокое усилие; **Ступень 2** (CostBase для Ralp/PrDoc) закрывает основной остаток без полной переписки.

---

## 10. План закрытия К-7 строгой: Ступени 1–3

> **Цель:** fn2 stIpg=NULL **< 120 с** при каждом вызове из MS Access / `spMstrg_2606`, без кэша и без app-parallelism.

### Ступень 1 — Индексы горячих FK (П4b)

**Суть:** шесть индексов на полях, по которым идут повторяющиеся сканы в CostBase/bundle.

| Индекс | Таблица | Назначение |
|--------|---------|------------|
| `IX_ra_cac` | `ags.ra(ra_cac)` | CostBase RA: устранить 49K scan |
| `IX_ra_change_rac_ra` | `ags.ra_change(raс_ra)` | JOIN ra_change → ra |
| `IX_ra_summ_ras_ra` | `ags.ra_summ(ras_ra) INCLUDE (...)` | batch lookup ras_fdKey |
| `IX_ralpRa_cac` | `ags.ralpRa(ralprCstAgPn)` | Ralp bundle (`ags.ralp` — VIEW) |
| `IX_cn_PrDocP_cac` | `ags.cn_PrDocP(pdpCstAgPn)` | PrDoc bundle |
| `IX_cstAgPnMnrl_cac` | `ags.cstAgPnMnrl(amCstAgPn)` | Mnrl bundle |

**Файл:** `00-perf-indexes-k7.sql` (дополнение к `00-perf-indexes.sql`).  
**Зеркало:** `MSSQL2012/00-perf-indexes-k7.sql`.  
**Усилие:** минимальное. **Риск:** нулевой. **Совместимость:** SQL 2012 SP4 ✅.

**Ожидаемый эффект:** StIpgStCost NULL **198 с → ~80–120 с**.

**Факт (dev, 2026-06-15):** StIpgStCost NULL **45,7 с** (×4,3); fn2 NULL **127,7 с** (×2,2). К-7: FAIL на 7,7 с.

**Факт после Ступени 2 (2026-06-15):** StIpgStCost **31,5 с**; fn2 NULL **111,5 с** — **К-7 PASS** ✅.

**Приёмка:** `07h6` (К-7 gate); `07h` stIpg=46 pres/lim без регрессии.

---

### Ступень 2 — `@ralpCostBase` + `@prDocMnrlCostBase` (P6-lite)

**Суть:** применить паттерн этапа 9б (RA/AgFee) к Ralp и PrDocMnrl.

| Артефакт | Действие |
|----------|----------|
| `fnMasteringRalpCostBase_2606` | новая MSTVF в `03b1` (по образцу `fnMasteringAgFeeCostBase_2606`) |
| `fnMasteringPrDocMnrlCostBase_2606` | новая MSTVF в `03b1` |
| `fnMasteringCstAgPn_2606` (`03c`) | `@ralpCostBase` + `@prDocMnrlCostBase`; заменить OUTER APPLY bundle на inline-агрегацию |
| `MSSQL2012/03b1`, `03c` | зеркало |

**Устраняет:** 11 560 повторных сканов `ralp` / PrDoc / Mnrl.

**Ожидаемый эффект** (после Ступени 1): StIpgStCost NULL **~80–120 с → ~20–50 с**.

**Приёмка:** `07b` (fnStCost parity); `07h` stIpg=46/61 (pres/lim); `07h6` (К-7).

---

### Ступень 3 — fn2 MSTVF → Stored Procedure

**Суть:** конвертировать `fnIpgChRsltCstUtl2_2606` в `ags.spIpgChRsltCstUtl2_2606` (или inline в `spMstrg_2606`).

| Изменение | Эффект |
|-----------|--------|
| `@schemeRows` → `#schemeRows` + `INDEX (ipgKey, ipgpCstAgPn, iShKey, mNum)` | seek вместо hash join в `allMonthsForIpg` |
| `@mastMonthEnd`, `@branchCache` → `#temp` с индексами | аналогично |
| `spMstrg_2606` вызывает SP вместо `SELECT FROM fn2` | единая точка входа для Access |

**Ожидаемый эффект:** fn2 overhead **~82 с → ~5–15 с**.

**Приёмка:** `07h6` D2 (spFn2); `07f` PercentBrn PASS; `07_VERIFY_after`; `07h` stIpg=46/61.

**Замер dev (2026-06-15):** fn2 NULL **111 с**; spFn2 **~144 с** (SQL 2022, INSERT-EXEC overhead). На **SQL 2012 prod** ожидается выигрыш от `INDEX #schemeRows` (нет статистики у table variables). Access остаётся на `fn2` + `fnPercentBrn` до подтверждения на prod; переключение — `MSSQL2012/06b`.

---

### 10.1. Сводная таблица Ступеней 1–3

| Ступень | Артефакты | StIpgStCost | fn2 overhead | fn2 NULL (оценка) | Усилие | Риск |
|---------|-----------|------------|--------------|-------------------|--------|------|
| **1** | `00-perf-indexes-k7.sql` | 198→**46 с** | 82 с | **~128 с** ❌ | Мин. | Нулевой |
| **2** | `03b1` CostBase + `03c` inline | 46→**31,5 с** | ~80 с | **~111,5 с** ✅ | Средн. | Низкий |
| **2** | `03b1` + `03c` CostBase Ralp/PrDoc | 80–120→20–50 с | 82 с | **~100–130 с** | Средн. | Низкий |
| **3** | `04`→SP, `06` spMstrg | — | 82→5–15 с | **~25–65 с** ✅ | Средн. | Средний |
| **1+2+3** | все | — | — | **~25–65 с** | — | — |

**К-7 строгая (<120 с):** достижима после **Ступени 2** (на грани) или **Ступени 3** (с запасом ×2–4).

### 10.2. Исключённые из плана пути

| Путь | Причина исключения |
|------|-------------------|
| App-level parallelism | MS Access — один поток вызова |
| Persistent mastering cache | данные меняются многократно в день |
| П5 RRcTimeListBase | RRc **117 мс** — не узкое место (`07h6`) |
| Полный set-based П6 (680→1 JOIN) | высокое усилие; Ступень 2 закрывает основной остаток |

### 10.3. Рекомендуемый порядок реализации

```
14.1  → Ступень 1: 00-perf-indexes-k7.sql → 07h6 (замер)
14.2  → Ступень 2: fnMasteringRalpCostBase_2606 + PrDocMnrlCostBase → 03c → 07h6 + 07h + 07b
14.3  → Ступень 3 (если 14.2 > 90 с): fn2→SP → 06 → 07h6 + 07f + 07_VERIFY_after
14.4  → MSSQL2012/ зеркало + db-upgrade + journal
```

---

*Файл создан: 2026-06-11. Разделы 8–10: 2026-06-15. Автор: Александр.*
