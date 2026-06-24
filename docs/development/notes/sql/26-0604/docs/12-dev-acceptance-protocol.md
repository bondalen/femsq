# Протокол dev-приёмки: сходимость `_2606` ↔ `_2605` + производительность

**Дата:** 2026-06-15  
**lastUpdated:** 2026-06-17  
**Среда:** Docker `femsq-mssql`, БД `FishEye` (продуктив — тот же протокол позже)  
**Связанные документы:** `06-sp-recordsets-and-acceptance.md`, `08-testing-strategy.md`

---

## Параметры эталонного прогона (цепь 5)

| Параметр | Значение |
|----------|----------|
| `@ipgCh` | **5** |
| `@MounthEndDate` | **`'2022-12-31'`** (RS4–RS7: окт–ноя–дек 2022) |
| `_2606` | `@ipgStKey=NULL`, `@stCostKey=NULL` |
| `_2605` | `@ipgSt=NULL` |

RS1 (Java) **не зависит** от `@MounthEndDate` — полный год (~14 447 строк).  
Access: RS4–RS7 при `12-31` — **больше данных**, чем при `09-30`.

---

## Две оси каждого шага

1. **CORRECT** — сходимость с `_2605` / нулевой EXCEPT.  
2. **PERF** — время vs лимит (К-6, К-7, К-8).

Формат лога: `step | ms | rows | CORRECT | PERF`.

---

## Фаза 1 — сходимость `_2606` ↔ `_2605`

| # | Шаг | Скрипт | CORRECT | PERF (лимит) |
|---|-----|--------|---------|--------------|
| 1 | fn2 stIpg=61 | `07h_compare_fn2_to_2605` | pres/lim PASS | — |
| 2 | fn2 stIpg=46 | `07h_compare_fn2_to_2605` | pres/lim PASS | **К-6 < 60 с** |
| 3 | fn2 NULL | `07h6` D | rows=11587 | **К-7 < 120 с** |
| 4 | PercentBrn | `07f` | F.1–F.3 PASS | **К-8 < 10 мин** |
| 5 | Fill RS | `spMstrg_2605/2606` @saveToTables=1 | — | wall-clock |
| 6 | RS1–RS7 | `07k` | RS1: keyDiff=0; RS2–7: COUNT | — |
| 7 | RS4–RS7 spot | `07l` | COUNT; EXCEPT — инфо | — |

**Оркестратор:** `./run_acceptance_dev_chain5.sh` → лог `acceptance_dev_chain5_*.log`.

---

## Фаза 2 — аддитивность `212 = 172 + 187 + 195`

| # | Шаг | Скрипт | stIpg |
|---|-----|--------|-------|
| 1 | Лимиты mastering | `07i` | 61 → 46 → NULL |
| 2 | Факт RA + gate 182 | `07j` | 61 → 46 → NULL |
| 3 | fnStCost @195 | `07b` | разово |

Инварианты: `07i` lim212 ≈ lim172+lim187+lim195; `07j` pres/accp; `regression_182=0`.

Проверка на уровне RS (сегменты `@stCostKey`) — **backlog** `07l` (после PASS фазы 1).

> **Примечание:** в оркестраторе фаза 2 сейчас выполняется для `stIpg=61, 46` (не NULL). Прогон `07i`/`07j` @ NULL — в фазе 3e и в backlog оркестратора.

---

## Фаза 3 — помесячные планы по stCost (dev-only, перед финальной сборкой флеша)

**Среда:** только dev Docker. **Не входит** в deploy-day на prod.  
**Подробно:** [`13-plan-stcost-monthly-acceptance.md`](13-plan-stcost-monthly-acceptance.md)

**Предусловие:** fixture `fixture/dev-chain5-utpl-stcost/` (разбивка `ipgUtPlPnLmMn` на 172/187/195).

| # | Шаг | Скрипт | CORRECT | PERF |
|---|-----|--------|---------|------|
| 1 | Данные UtPlMn | `FIXTURE_04_verify_data.sql` | суммы/месяцы по 4 stCost | секунды |
| 2 | **К-12** план = лимит | `07m_plan_limit_conformance_chain5.sql` | `agSmmTtl@stCost` = `ipgpSm*` на `@dt` для строек с UtPlMn | **≤ 8 мин**, NULL |
| 3 | **К-13** план аддитивен | `07m_plan_additive_chain5.sql` | `agSmmTtl@212 ≈ @172+@187+@195` на `@dt` | **≤ 8 мин**, NULL |
| 4 | Лимиты (контроль) | `07i` @ NULL | как фаза 2 | **≤ 8 мин** |

**Оркестратор:** `./run_acceptance_dev_chain5.sh --with-plan-stcost` *(планируется)*.

**Критерий перед prod-деплоем (dev):** К-12 и К-13 PASS @ `2022-12-31` на полной цепи. Процедура на prod **не дополняется** шагами fixture/07m.

---

## Whitelist расхождений

| Паттерн | Условие |
|---------|---------|
| money | ε = 0,01 |
| NULL ↔ 0 | 24 пары на stIpg=46 (M.5) — документировать, не считать регрессией fn2 |
| RS1 vs @dt | расхождение RS1 при смене даты = **баг** |

---

## Контрольные точки (обновление после прогона)

| Точка | Условие |
|-------|---------|
| **К-9b** | `07k` PASS @ `2022-12-31`, все RS1..RS7 |
| **К-12** | План = лимит ipgPn по **212, 195, 172, 187** (dev, после fixture) | см. `13-plan-stcost-monthly-acceptance.md` |
| **К-13** | План: `212 = 172 + 187 + 195` на `@dt` (dev, после fixture) | ⬜ |
| К-6, К-7, К-8 | см. `08-testing-strategy.md` |

---

*Автор: Александр*
