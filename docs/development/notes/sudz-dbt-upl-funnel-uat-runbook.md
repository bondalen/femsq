# Runbook UAT: воронка загрузки общего свода (0069)

**Создан:** 2026-09-02  
**Последнее обновление:** 2026-09-08  
**Задача:** 0069 · **План:** [chat-plan-26-0802-sudz.md](chats/chat-plan/chat-plan-26-0802-sudz.md) §5.6 **S76-C.10**  
**Связь:** [04-data-model §2.7](../domain/sudz/04-data-model.md#27-полный-алгоритм-btncidufload_click--цепочка-сопоставления-подтверждено-s29), сегмент 17 (S66e)

---

## Назначение

Порядок **пошагового** UAT воронки `runSudzDbtUplFunnel` — **предпочтительно в UI** (S76-C.10) и при необходимости без UI (GraphQL/curl, CI, агент).  
Access-оркестратор между Sub-шагами **останавливается на ручных gate'ах**; одноразовый прогон «все enabled-шаги + `flLoad=true`» **не эквивалентен** полной загрузке upl.

**Текущий канон UAT (2026-09-08):** upl **901** = Excel **X**; C.10.1 на **G4** (КСДД open=2: ciud **2807/2808**, СФ `А45-19974/2024`, `iKey=85166`, 2×18 000, `reason=multi`). Split как в песочнице A на живом `sudz` **не делать**. Link одной 18 000 на исторический слот 36 000 — нет (`UNIQUE(dvInvDbt,dvUpl)`). Хвост «добить G2 на старом 902» **не** продолжать.

---

## Казус S76-C / upl 902 (2026-09-02)

### Что произошло

При Variant B (clean reset @902) выполнен **один** GraphQL-прогон: enabled-шаги **1–9**, `flLoad=true`, `flTbl=false` (Tbl=1746 уже был).  
Шаг **`CnExistCtptNotLoad`** зафиксировал **5 договоров** с расхождением исполнителя (только лог, без apply), но прогон **не остановили** — шаги 4–9 отработали с «дырами».

### Последствия

| Метрика | Ожидание после полной загрузки | Факт после «полного» прогона |
|---------|-------------------------------|------------------------------|
| Tbl | 1746 | 1746 ✅ |
| DbtValue @902 | ≈1746 (минус осознанные исключения) | **1725** ❌ |
| КСДД (open) | 0 после ручного разбора | **10** (не разобраны) |
| КСДСФ | 0 после ручного разбора | не пройден |
| Rslt @902 vs эталон | gate после полного цикла | Δ вероятно из‑за пропущенных gate'ов |

### Корневая причина

Ручные шаги воронки (**лог-only** или **очередь + экран оператора**) **не имеют** автоматического блокера в `runSudzDbtUplFunnel`: mutation выполняет **весь** переданный префикс `steps[]` подряд.  
Без UI оператор не видит стоп-сигнал; без явной проверки gate'ов скрипт идёт дальше.

### Исправление процесса (не кода оркестратора)

1. Прогон **только до gate'а** → проверка → ручная работа → повтор проверки.  
2. Следующий прогон — **следующий сегмент** префикса, не «full apply» сразу.  
3. Перед gate Rslt — скрипт `verify-funnel-manual-gates.sh` (см. ниже).

**Код:** параллельно исправлен duplicate key в `CnInvUplInvDbtDouble` (JAR **0.1.0.252**) — отдельная ошибка INSERT, не отменяет необходимость gate'ов.

---

## Ручные gate'ы (обязательные стоп-точки)

| Gate | stepId | Тип | Критерий «можно дальше» | Где править |
|------|--------|-----|-------------------------|-------------|
| **G0** | `orgNotInBuirg` | лог | в логе: *«новые организации **отсутствуют**»* | справочник org (редко) |
| **G1** | `CnNotLoad` | apply при `flLoad` | *«новые договора **отсутствуют**»* или apply + откат по `cnMark` | — |
| **G2** | **`CnExistCtptNotLoad`** | **только лог** | *«договора … **отсутствуют**»* (нет «**имеются** договора … **не соответствует**») | **Договоры / 0071** (S62, S65c) |
| **G3** | `CnCtptExistInvNotLoad` | apply + prelude КСДСФ | очередь **КСДСФ** `open` = **0** | экран **КСДСФ** (create / link) |
| **G4** | `invDbtLoad` | apply + очередь КСДД | очередь **КСДД** `open` = **0** | экран **КСДД** (create / link / ensure var) |
| **G5** | `dbtValueLoad` | apply | DbtValue ≈ Tbl (± документированные исключения) | — |

**G2 — критичный:** без датированной `cn_s_org` (№ + БУиРГ + **дата** Excel) строки не попадают в `invDbtVar` / `invDbt` / `DbtValue` (сегмент 17, S61n).

---

## upl 902 @ G2 (эталонный список на 2026-09-02)

После excelToTbl (Tbl=1746), префикс 1–3 — **5 договоров**, **7 строк Tbl**:

| # | БУиРГ | Контрагент | № договора | Дата Excel |
|---|-------|------------|------------|------------|
| 1 | 1052783 | ДРСК, АО | НВ-У 719/25 | 14.03.2026 |
| 2 | 1057325 | Россети Центр и Приволжье | 711140430 | 14.04.2025 |
| 3 | 1060645 | Россети Волга | 2540-000899 | 27.02.2025 |
| 4 | 1074001 | Росприроднадзор (МО/Смол) | 16 | 17.03.2026 |
| 5 | 1226124 | Донэнерго ЗМЭС | 158 | 08.12.2011 |

**Действие оператора (S65c):** вариант 1 «+ Договор» (новый `cn` + сторона) или вариант 2 «+ smpl» (сторона на существующий `cn`).  
После правок — **повтор префикса 1–3** до G2=PASS.

---

## Анти-паттерн (запрещено для gate-UAT)

```text
❌ runSudzDbtUplFunnel(steps = все 9 enabled, flLoad=true)
   сразу после excelToTbl, без проверки G2/G3/G4
```

```text
❌ Считать DbtValue > 0 доказательством «upl загружен полностью»
```

```text
❌ Сравнивать Rslt с эталоном Excel до закрытия G2–G4
```

---

## Правильный пошаговый прогон (без UI)

### Предусловия

- Backend: `http://127.0.0.1:8080/graphql`
- `cidufPath` и FileSh для upl заданы (seed / UI)
- Для excelToTbl: `cidufFlTbl=true` в БД **или** шаг не в `steps[]` при уже загруженном Tbl

### Фаза A — буфер

| # | steps (префикс) | flLoad | flTbl | Проверка |
|---|-----------------|--------|-------|----------|
| A1 | `[]` (пусто) | — | **true** | `COUNT(CnInvDbtUplTbl)=N` |

GraphQL: excelToTbl выполняется **до** панели, если `cidufFlTbl=true` (см. `SudzDbtUplFunnelRunner`).

### Фаза B — префикс до G2

| # | steps | flLoad |
|---|-------|--------|
| B1 | `orgNotInBuirg`, `CnNotLoad`, `CnExistCtptNotLoad` | `true` для CnNotLoad при необходимости |

**Стоп.** `./code/scripts/verify-funnel-manual-gates.sh 902` → G2 must PASS.  
Иначе — **Договоры**, повтор B1.

### Фаза C — СФ (G3)

| # | steps | flLoad |
|---|-------|--------|
| C1 | … + `CnCtptExistInvNotLoad` | `true` |

**Стоп.** КСДСФ `open`=0 (UI или SQL). Затем C2 при необходимости.

### Фаза D — invDbt (G4)

| # | steps | flLoad |
|---|-------|--------|
| D1 | … + `invDbtVarEnsure`, `invDbtLoad` | `true` |

Шаги 5–7 в batch при `flLoad=true` (AccSmpl + Var + InvDbt).  
**Стоп.** КСДД `open`=0.

### Фаза E — Value

| # | steps | flLoad |
|---|-------|--------|
| E1 | … + `invDbtDbtEnsure`, `dbtValueLoad` | `true` |

### Пример curl (фаза B1)

```bash
curl -s -X POST http://127.0.0.1:8080/graphql \
  -H 'Content-Type: application/json' \
  -d '{
    "query": "mutation($input: RunSudzDbtUplFunnelInput!){ runSudzDbtUplFunnel(input:$input){ ranSteps stub }}",
    "variables": {
      "input": {
        "uplKey": 902,
        "yrKey": 901,
        "flLoad": true,
        "steps": ["orgNotInBuirg", "CnNotLoad", "CnExistCtptNotLoad"]
      }
    }
  }'
```

Лог: `sudzDbtUplLauncher(uplKey).file.cidufLoadingProgress` или вкладка «Ход загрузки» в UI.

---

## SQL-проверки gate'ов

Файл: [verify_funnel_manual_gates.sql](sql/26-0831-sudz-dbt-slot-link/verify_funnel_manual_gates.sql)

Кратко:

```sql
-- G2: число строк CnExistCtptNotLoad (0 = PASS)
-- см. findDbtUplCnExistCtptNotLoad / ciduCnExistCtptNot

-- G3:
SELECT COUNT(*) FROM sudz.CnInvUplSfDouble
 WHERE ciusUnloadKey = @upl AND ciusStatus = N'open';

-- G4:
SELECT COUNT(*) FROM sudz.CnInvUplInvDbtDouble
 WHERE ciudUnloadKey = @upl AND ciudStatus = N'open';
```

---

## Скрипт проверки (без UI)

```bash
./code/scripts/verify-funnel-manual-gates.sh <uplKey> [graphql_url]
```

Читает `cidufLoadingProgress` через GraphQL и считает open-очереди (если доступен `sqlcmd` / переменные `FEMSQ_DB_*` — дополнительно SQL G2).

**Exit code:** `0` — все gate'ы PASS; `1` — есть блокеры (выводит список).

---

## Чеклист перед «полный apply» и Rslt-gate

- [ ] G2: ExistCtpt — *отсутствуют*
- [ ] G3: КСДСФ open = 0
- [ ] G4: КСДД open = 0
- [ ] `COUNT(DbtValue WHERE dvUpl=@upl)` согласован с Tbl (± реестр исключений)
- [ ] Gate yr/base (S75/S76) на **901** не регрессировал после изменений кода

---

## Связанные артефакты

| Артефакт | Назначение |
|----------|------------|
| [30_SEED_funnel_upl_902_903.sql](sql/26-0831-sudz-dbt-slot-link/30_SEED_funnel_upl_902_903.sql) | seed File/FileSh |
| [verify-qiv-stage2-gate.sh](sql/26-0831-sudz-dbt-slot-link/verify-qiv-stage2-gate.sh) | Rslt QIV (после полного цикла) |
| [02-10_contracts-cnNum-access.md](../UI/02-10_contracts-cnNum-access.md) | ручной G2 |
| [02-9 §4a](../UI/02-9_sudz-mvp-screens.md) | экраны КСДСФ / КСДД |
