# Решение 012: денежный квант и оси агрегации при вводе (R-MONEY-AGG)

**Дата:** 2026-11-26  
**Статус:** ✅ Принято  
**Участники:** Александр, Cursor AI  
**Код нормы:** `R-MONEY-AGG`  
**Задача:** **0095**  
**Спин-офф:** диагностика lim δ≈0.01 на цепи 507 (cstapKey=3555) в плане fn2/0094

---

## Проблема

Excel (лимиты, планы, освоение) часто содержит доли **мельче копейки**. Поля БД хранят квант копейки в двух моделях:

| Контур | Единица | Тип | 1 копейка |
|--------|---------|-----|-----------|
| Sm / `ipgPnLim` / UtPl | млн ₽ | `decimal(23,8)` | **1e−8** млн |
| RA / `factDocCost` | ₽ | `money` | **0.01** ₽ |

Плюс авторы Excel допускают **арифметические ошибки** по осям (`Ttl ≠ Wrk+Equ+Oth`, `212 ≠ 195+172+187`).  
Без round + проверки осей при записи: δ ulp в Sm → после ×1e6 в RS `ag_lim` δ=0.01; крупные δ портят срезы stCost.

Импорт ImpIpg/RA писал `BigDecimal.valueOf(double)` без `setScale` и без rebalance; VBA UtPl уже делает `Round(,8)`.

---

## Принято (владелец 2026-11-26)

### Классы расхождений

| Класс | Смысл | Действие |
|-------|--------|----------|
| **Q** (квант) | `0 < \|δ\| ≤ ε_q` | Автоfix: round → остаток в Oth/187; авторитет **Ttl/212**; лог `AGG_QUANTUM_FIX` |
| **A** (автор) | `ε_q < \|δ\| ≤ ε_block` | **Обнаружить и исправить**: канон **части → пересчёт Ttl**; лог `AGG_AUTHOR_FIX` + before/after |
| **A-hard** | `\|δ\| > ε_block` | **Block** строки (partial apply); `AGG_BLOCK`; правка файла или override |
| **S** (структура) | нет разбивки при ненулевом Ttl (или наоборот) | Не выдумывать части; `AGG_STRUCT` (D6) |

### Пороги (млн ₽; для ₽ — аналоги в копейках/рублях)

- `ε_q = 1e−8` (= 0.01 ₽ после ×1e6)
- `ε_fix` ориентир `1e−6` (= 1 ₽) — внутри зоны A
- `ε_block = max(1 млн ₽ в ед. контура, 1% \|Ttl\|)` (**D7**)

### Каноны fix

- **D1 / Q:** авторитет Ttl, δ → Oth/187  
- **D2' / A:** авторитет **сумма частей → Ttl**  
- **D2'' / A-hard:** block до правки Excel или явного override сессии  
- **D3:** ₽ → scale **4** (`money`)  
- **D6 / S:** не авто-разбивать пустые части  

### Обязательный поток на любой ввод денег с осями

```text
Excel/UI → round(квант) → AggCheck → Q/A fix или BLOCK/STRUCT → write → (ImpIpg) seed ipgPnLim из согласованных Sm*
```

Единый util (например `FemsqMoney` / `AggAxis`): ImpIpg, GraphQL leaves, RA reconcile, будущий UtPl O2. Обход util запрещён.

### Лог ImpIpg

Коды: `AGG_OK` · `AGG_QUANTUM_FIX` · `AGG_AUTHOR_FIX` · `AGG_STRUCT` · `AGG_BLOCK` (scopes GATE/APPLY).

---

## Реализация (порядок — задача 0095)

0. Этот ADR + ссылка в `.cursorrules` / docs  
1. Util + unit-тесты Q/A/S/block  
2. ImpIpg parser + apply + seed lim  
3. GraphQL leaves  
4. One-shot ремонт данных (Q авто; A по канону; A-hard — отчёт)  
5. RA reader + reconcile  
6. UtPl O2 — с первого дня  
7. Gate: после fix `COUNT(δ≠0)=0` на целевом контуре (07k1-класс)

---

## Последствия

- ✅ Срезы 195/172/187 и RS lim/факт не ломаются из‑за ulp и ошибок сложения в Excel  
- ✅ Паритет с VBA Round(8) на млн-контуре  
- ⚠️ A-hard потребует правок файлов оператором или override  
- ⚠️ One-shot на уже залитых данных — отдельный прогон на стенде/проде  

---

## Связанные материалы

- `docs/development/notes/chats/chat-plan/notes/26-1126-fn2-stcost-fact-rs-accept-23.md` — природа δ=0.01 @3555  
- `docs/development/notes/chats/chat-plan/chat-plan-26-1126-money-agg-axes.md` — план 0095  
- sql `03-design-decisions.md` Решение 12 (212=195+172+187), Решение 23 (fn2 agency×stCost)  
- Хвост C2 O1: apply → `ipgPnLim`  
