# Диагностика: 07h stIpg=61 FAIL — ровно в 2 раза меньше строк

**Дата:** 2026-06-11  
**Контекст:** После Stage 8.3 (замена LEGACY UDF на fnMasteringFact*_2606 + 27 новых колонок)  
**Симптом:** `n_2408=72, n_2606=36, miss=36, extra=0, vdiff=0`

---

## Что означает «ровно ×2»

`extra=0, vdiff=0` — лишних строк нет, совпавшие строки верны.  
Это **структурное отсутствие одной категории строк**, а не расхождение данных.

Ровно ×2 означает: для контракта stIpg=61 существуют два независимых классификационных
источника по 36 строк каждый — один теперь молча возвращает 0.

### Гипотезы

| # | Что исчезло | Где сломано |
|---|------------|-------------|
| А | Схема `ipgpSh=1` перестала давать строки — изменился блок `@masteringTrue` в `fnMasteringCstAgPn_2606` | Шаг 3 |
| Б | Один из трёх `INSERT` в `fnMasteringCstAgPnSh_2606` даёт 0 строк — несоответствие списков столбцов или изменённое условие | Шаг 3 |
| В | `extraBase` / `masExtraBase` в `fn2_2606` потерял строки из-за изменившегося `schemeRows` | Шаг 4 |

---

## Шаг 1 — Найти контракт и его схемы в цепи 5

```sql
USE FishEye;
DECLARE @ipgCh int = 5, @stIpg int = 61;

SELECT pp.ipgpKey, pp.ipgpSh, pp.ipgpCstAgPn,
       ip.ipgKey AS ipgKey, pp.ipgpUtPlGr
FROM ags.ipgPn pp
JOIN ags.ipg ip ON ip.ipgKey = pp.ipgpIpg
JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgCh
WHERE EXISTS (SELECT 1 FROM ags.ipgStPn sp
              WHERE sp.ipgspSt = @stIpg AND sp.ipgspPn = pp.ipgpKey);
```

**Интерпретация:**
- Если 2 строки с `ipgpSh=1` и `ipgpSh=2` → Гипотеза А или Б (один из двух вызовов `fnMasteringCstAgPn_2606` теперь даёт 0)
- Если 1 строка → Гипотеза В (fn2_2606 теряет строки в `extraBase`/`masExtraBase`)

---

## Шаг 2 — Найти какую typeGr/iShKey группу недостаёт

```sql
USE FishEye;
SET NOCOUNT ON;
DECLARE @ipgCh int = 5, @stIpg int = 61;

IF OBJECT_ID('tempdb..#f08') IS NOT NULL DROP TABLE #f08;
IF OBJECT_ID('tempdb..#f06') IS NOT NULL DROP TABLE #f06;
IF OBJECT_ID('tempdb..#stc') IS NOT NULL DROP TABLE #stc;

SELECT DISTINCT pp.ipgpCstAgPn AS cstAgPnKey
INTO #stc
FROM ags.ipgStPn sp
JOIN ags.ipgPn pp ON sp.ipgspPn = pp.ipgpKey
JOIN ags.ipgChRl cr ON cr.ipgcrIpg = pp.ipgpIpg AND cr.ipgcrChain = @ipgCh
WHERE sp.ipgspSt = @stIpg;

SELECT typeGr, iShKey, COUNT(*) n
INTO #f08
FROM ags.fnIpgChRsltCstUtl_2408(@ipgCh) f
WHERE f.cstAgPnKey IN (SELECT cstAgPnKey FROM #stc) AND f.ipgKey IS NOT NULL
GROUP BY typeGr, iShKey;

SELECT typeGr, iShKey, COUNT(*) n
INTO #f06
FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, @stIpg, NULL) f
WHERE f.cstAgPnKey IN (SELECT cstAgPnKey FROM #stc) AND f.ipgKey IS NOT NULL
GROUP BY typeGr, iShKey;

SELECT
    COALESCE(a.typeGr, b.typeGr)              AS typeGr,
    COALESCE(a.iShKey, b.iShKey)              AS iShKey,
    ISNULL(a.n, 0)                            AS n_2408,
    ISNULL(b.n, 0)                            AS n_2606,
    CASE WHEN ISNULL(a.n,0) = ISNULL(b.n,0)
         THEN 'OK' ELSE 'DIFF' END            AS status
FROM #f08 a
FULL JOIN #f06 b
    ON a.typeGr = b.typeGr
   AND ISNULL(a.iShKey, -1) = ISNULL(b.iShKey, -1)
ORDER BY typeGr, iShKey;
```

Строки со `status='DIFF'` укажут конкретную группу и помогут понять, из какого CTE
(`ipgBase`, `extraBase`, `masExtraBase`) они должны были прийти.

---

## Шаг 3 — Проверить mastering стек напрямую (Гипотезы А и Б)

```sql
USE FishEye;
-- Точка входа mastering стека — breakdown по typeGr и ipgpSh
SELECT typeGr, ipgpSh, COUNT(*) n
FROM ags.fnMasteringStIpgStCost_2606(21, 5, 61, NULL)
GROUP BY typeGr, ipgpSh
ORDER BY typeGr, ipgpSh;
```

- Если результат тоже показывает ×2 меньше — проблема **внутри mastering стека**
  (`fnMasteringCstAgPnSh_2606` или `fnMasteringCstAgPn_2606`)
- Если mastering стек вернул правильное количество — проблема в CTE `fn2_2606` (Гипотеза В)

---

## Шаг 4 — Проверить extraBase/masExtraBase (Гипотеза В)

```sql
USE FishEye;
SELECT
    CASE WHEN iShKey IS NULL
         THEN 'extraBase / masExtraBase'
         ELSE 'schemeRows (ipgBase)'
    END AS src,
    COUNT(*) n
FROM ags.fnIpgChRsltCstUtl2_2606(5, 61, NULL) f
WHERE f.cstAgPnKey IN (
    SELECT DISTINCT pp.ipgpCstAgPn
    FROM ags.ipgStPn sp
    JOIN ags.ipgPn pp ON sp.ipgspPn = pp.ipgpKey
    JOIN ags.ipgChRl cr ON cr.ipgcrIpg = pp.ipgpIpg AND cr.ipgcrChain = 5
    WHERE sp.ipgspSt = 61
)
  AND f.ipgKey IS NOT NULL
GROUP BY CASE WHEN iShKey IS NULL
              THEN 'extraBase / masExtraBase'
              ELSE 'schemeRows (ipgBase)' END;
```

---

## Шаг 5 — Проверить код Stage 8.3 (если Шаг 3 подтвердил mastering)

### 5а. Блок `@masteringTrue` в `fnMasteringCstAgPn_2606`

Убедиться, что условие для `@ipgSh=1` **не изменилось**:

```sql
-- ПРАВИЛЬНО (было в v7):
WHERE v.ipgcrvChain = @ipgCh AND p.ipgpCstAgPn = @cstAgPn AND p.ipgpSh = 2

-- ОШИБКА (если случайно расширили):
WHERE v.ipgcrvChain = @ipgCh AND p.ipgpCstAgPn = @cstAgPn AND p.ipgpSh IN (1, 2)
```

Второй вариант сделал бы `@masteringTrue='false'` для `@ipgSh=1` даже когда `@ipgSh=1` единственный
в цепи — и этот вызов перестал бы вставлять строки.

### 5б. Три `INSERT` в `fnMasteringCstAgPnSh_2606`

Проверить каждый из трёх INSERT: количество столбцов в `INSERT INTO @TablRslt (...)`
должно точно совпадать с количеством столбцов в `SELECT ... FROM fnMasteringCstAgPn_2606(...)`.

Если один INSERT имеет неправильный список столбцов — SQL Server выдаст ошибку.
Если в одном INSERT WHERE-условие или JOIN изменился и фильтрует все строки — INSERT тихо даст 0.

### 5в. Быстрая проверка через git

```bash
git diff HEAD -- docs/development/notes/sql/26-0604/03c_CREATE_FUNCTION_fnMasteringCstAgPnSh_2606.sql
```

Сравнить блок `@masteringTrue` и все три INSERT до/после Stage 8.3.

---

## Ожидаемый порядок действий

```
Шаг 1 → сколько ipgpSh записей у контракта stIpg=61?
    ↓
Шаг 2 → какой typeGr/iShKey исчез?
    ↓
Шаг 3 → mastering стек даёт ×2 меньше?
    ├─ ДА → Шаг 5а и 5б (проверить код @masteringTrue и 3 INSERT)
    └─ НЕТ → Шаг 4 (проблема в fn2_2606 CTE)
```

---

---

## Результат (2026-06-11, v7.1)

**Эталон:** `fn_2408` (приоритет над `fn_2605`, который фильтрует пустые строки).

**Корневая причина:** в `fn_2408` subquery `lim` содержит:
```sql
SELECT p.ipgpIpg, p.ipgpCstAgPn, p.ipgpSh FROM ags.ipgPn p
UNION
SELECT p.ipgpIpg, p.ipgpCstAgPn, 2 FROM ags.ipgPn p WHERE p.ipgpSh = 1
```
При `ipgpSh=1` синтетически добавляется агентская схема (`iShKey=2`) — 12 мес × 3 ИПГ = 36 строк с `lim=NULL`.

`fn2_2606` строил `ipgSchemeCombo` только из непустых `schemeRows` → агентская схема выпадала.

**Исправление** (`04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql` v7.1):
1. CTE `ipgPnSchemePts` + `ipgMasteringCombos` → `ipgSchemeCombo` (как `lim` в fn_2408).
2. Финальный фильтр: строки с `ipgKey IS NOT NULL AND iShKey IS NOT NULL` сохраняются даже при всех финансовых NULL (паритет fn_2408, не fn_2605).

**Проверка:**
```
07h stIpg=61: M.1=72/72 OK, miss=0, extra=0, vdiff=0 → PASS
fn2_2606 time: ~45 сек (1 контракт, stIpg=61)
```

*Документ создан: 2026-06-11. Источник: анализ чата 3a4f7a43. Исправление: v7.1.*
