# Анализ схемы БД для spMstrg_2606

**Дата:** 2026-06-04  
**Задача:** разработка `spMstrg_2606` — DAG-фильтрация и корректная цепь ИПГ  
**Контекст:** анализ проведён в ходе выполнения этапа 0 плана `chat-plan-26-0604-spMstrg-2606.md`

---

## 1. Семейство ipgSt — устаревшее (изолированное)

| Таблица | Создана | FK наружу |
|---------|---------|-----------|
| `ags.ipgSt` | 2021-05-31 | **нет** |
| `ags.ipgStRl` | 2021-05-31 | **нет** |
| `ags.ipgStRlShP` | 2021-05-31 | **нет** |
| `ags.ipgStRlSh` | 2022-02-09 | **нет** |

Семейство полностью изолировано от `ipgPn`, `ipg`, `ipgCh`, `ipgStPn`. Функция `ags.fnIpgStNum` использует это устаревшее семейство — **не использовать в `_2606`**.

---

## 2. Семейство st — актуальное (2022-04)

| Таблица | Создана | Роль |
|---------|---------|------|
| `ags.stIpg` | 2022-04-07 | Узлы DAG-структуры ИПГ; `stiKey = st.stKey` (один keyspace) |
| `ags.stIpgNm` | 2022-04-07 | Имена узлов: `stinIpg → stIpg.stiKey` |
| `ags.st` | 2022-04-07 | Элементы структуры (универсальный) |
| `ags.stRel` | 2022-04-08 | Рёбра DAG: `strChild`, `strParent` |
| `ags.stNet` | 2022-04-08 | Схемы структуры: `stnKey`, `stnName`, `stnType` |
| `ags.stNetPn` | 2022-04-08 | Связь ребро → схема: `stnpStRel`, `stnpStNet`, `stnpNum` |
| `ags.ipgStPn` | 2022-05-26 | Связь пункт ИПГ ↔ узел stIpg: `ipgspPn → ipgPn`, `ipgspSt → stIpg.stiKey` |

### Связи с ИПГ-объектами

```
ipgPn.ipgpKey  ←──  ipgStPn.ipgspPn
                    ipgStPn.ipgspSt  ──→  stIpg.stiKey  =  st.stKey

ipg.ipgStRlSh  ──→  stNet.stnKey      (схема для ipg-обхода)
ipgCh.ipgcStNetIpg  ──→  stNet.stnKey (каноничный источник по цепи)
```

### Ключевые данные цепи 15

```sql
SELECT * FROM ags.ipgCh WHERE ipgcKey = 15
-- ipgcStNetIpg = 2  (схема «2021-12, декабрь. Утв. 2022 года»)
-- ipgcIpgLate  = 26 (последняя ИПГ в цепи)
```

```sql
SELECT i.ipgKey, i.ipgNm, i.ipgStRlSh FROM ags.ipg WHERE ipgKey IN (25, 26)
-- ipg=25 «Одобренная»:   ipgStRlSh = 2
-- ipg=26 «Письмо Д644»:  ipgStRlSh = 2
-- оба ссылаются на ту же схему stNet
```

---

## 3. Функции DAG-обхода st-семейства

### `ags.fnSt(@stNet int, @stRoot int)` — нисходящий обход, **включает корень**

Recursive CTE: от `@stRoot` вниз по `stRel`/`stNetPn`. Возвращает: `strChild, strParent, stpnNum, pnLevel, stNum, Nm`.  
Использует фильтр `st.stType = max(stNet.stnType)`.

### `ags.fnStDownAll(@stNet int, @stRoot int)` — нисходящий обход, **исключает корень**

```sql
SELECT strChild FROM ags.fnSt(@stNet, @stRoot) WHERE strChild <> @stRoot GROUP BY strChild
```

**Намеренно исключает корень.** Все вызывающие функции, которым нужен корень, добавляют его явно через `UNION SELECT @root`.

### `ags.fnStUpAll(@stNet int, @stLeaf int)` — восходящий обход, **исключает лист**

Используется в `fnMasteringCstAgPnShIpgSt` для проверки «входит ли узел в поддерево корня» (bottom-up).

---

## 4. Устоявшийся паттерн использования fnStDownAll

Все вызывающие функции используют один из двух паттернов:

**Паттерн A — нужен корень (фильтр по структуре ИПГ):**
```sql
-- fnMasteringStIpgStCost, fnStCostRsStIpg
SELECT @ipgRoot AS strIpgPn          -- корень явно
UNION
SELECT f.strChild
FROM ags.fnStDownAll(
    (SELECT max(c.ipgcStNetIpg) FROM ags.ipgCh c WHERE c.ipgcKey = @ipgCh),
    @ipgRoot) f
```

**Паттерн B — корень не нужен (лимиты по структуре затрат):**
```sql
-- fnStCostIpgPn, fnStCostRa, fnStCostRaCh
SELECT * FROM ags.fnStDownAll(@stNet, @StCostKey)
-- корень обрабатывается отдельно через прямой поиск в ipgPnLim
```

---

## 5. Дерево узлов stIpg (stNet=2) — фрагмент для цепи 15

```
fnSt(2, 1) — корень всего дерева, всего N узлов

Фрагмент вокруг узла 16:
16 — Обеспечение пикового баланса  (parent=3)
  ├ 17 — Обустройство Бованенковского НГКМ и МГ Бованенково-Ухта
  ├ 18 — Объекты ПХГ
  ├ 19 — Увеличение подачи газа в юго-западные районы Краснодарского края
  ├ 20 — Ачимовские участки Уренгойского НГКМ (2 участок)
  ├ 21 — Объекты добычи газа      ← ЛИСТ (используется как тестовый @ipgStKey)
  └ 22 — Объекты транспорта газа
```

### ipgStPn-покрытие для цепи 15

```sql
-- Уникальные узлы stIpg, встречающиеся в ipgStPn для ipg=25 и 26
-- Всего 33 различных узла (ipgspSt), включая: 4,5,6,8,9,12-15,17-22,24,26-28,30-33,35-37,40,41,43,44,46,47,49

-- Для @ipgStKey=21 (лист):
--   ipg=25: 25 пунктов ipgPn с ipgspSt=21
--   ipg=26: 32 пункта ipgPn с ipgspSt=21
--   Уникальных cstAgPnCode: 34 стройки
```

---

## 6. Таблица ipgUtPlGr — группы планов

```sql
SELECT * FROM ags.ipgUtPlGr ORDER BY iuplgKey
-- Всего 17 записей (ключи 1–17)
-- Последняя: key=17, iuplgIpg=25, «Группа планов на 2025 год от декабря 2024 года (Инвестпрограмма одобренная)»
-- Для ipg=26 («Письмо Д644») — записи нет → ipgcrvUtPlGr = NULL
```

---

*Файл создан: 2026-06-04. Обновлять по мере новых находок в рамках задачи 26-0604.*
