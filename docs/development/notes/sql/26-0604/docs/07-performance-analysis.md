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

*Файл создан: 2026-06-11. Автор: Александр.*
