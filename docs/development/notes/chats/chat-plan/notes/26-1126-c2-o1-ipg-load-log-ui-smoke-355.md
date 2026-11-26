# C2 §3.5.5 — UI-smoke C: «Ход загрузки» на новой SMOKE_LOG_* ИП

**Дата:** 2026-11-26 · **Задача:** 0081 · **План:** [chat-plan-26-1120-c2-d11-ipg-plans.md](../chat-plan-26-1120-c2-d11-ipg-plans.md) §3.5.5  
**Контракт:** [26-1126-c2-ipg-load-log-contract.md](26-1126-c2-ipg-load-log-contract.md)  
**Статус:** ✅

## Цель

Полный операторский цикл в Cursor browser на **изолированной** ИП:
Parse → Reconcile → Apply (dryRun + запись) с проверкой накопительного HTML-лога.
**Не трогать** load **9 / 10 / 11**.

## Контур (факт)

| Артефакт | Факт | Cleanup |
|----------|------|---------|
| ИП | `ipgKey=31` · `SMOKE_LOG_261126` · og=7 · yy=28 · num=90 · stNet=5 | SQL `DELETE ipg` ✅ |
| Load | `iilKey=12` · Excel `…/sql_0.xlsx` | `deleteImpIpgLoad(12)` ✅ |
| Пункты | applied **329** · errors **69** (STI_HOLE / soft-open) | SQL lim+stPn+pn ✅ |
| Цепь / сеть | не создавали (reuse stNet **5**) | — |
| load 9–11 | logLen без изменений (4017/3019/3020) | не трогали ✅ |

**JAR:** `0.1.0.412-SNAPSHOT` · UI `http://127.0.0.1:8080/` · лог `code/logs/app_412_smoke355.log`

## Чеклист приёмки

| # | Критерий | Факт |
|---|----------|------|
| 1 | После **Разобрать** — «Ход загрузки» не пуст | ✅ Parse: 39S/398L → staging 437 |
| 2 | После **Сверить** — Parse на месте + RECONCILE | ✅ Закрыто 31 · открыто 8; лог накопительный |
| 3 | **Проверить** (dryRun) + **Загрузить** | ✅ dryRun UI; запись applied=329; `iilResults` 4150→**6868** |
| 4 | Вложенность / уровни ≈ ревизии | ✅ `<details>` + lvl-warning/summary/success |
| 5 | Cleanup; load 9–11 целы | ✅ pn/load/ipg=0; loads911=3 |

## Ход выполнения

1. §3.5.5.0 — rebuild 412 (ipglog в fat JAR), stop 411, start 412.  
2. §3.5.5.1 — UI «Инвестпрограммы» → Создать `SMOKE_LOG_261126`.  
3. §3.5.5.2–4 — Структура stNet5 → ИП 31 → Разобрать → вкладка лог → Сверить.  
4. §3.5.5.5 — «Загрузка пунктов»: Проверить → Загрузить (≈4.5 мин, 1 pn/conn).  
5. §3.5.5.6 — UI+БД: Parse+Reconcile+Apply в одном `iilResults`.  
6. §3.5.5.7 — GraphQL `deleteImpIpgLoad(12)` + SQL lim/stPn/pn/ipg 31.

## Замечания

- dryRun **не** пишет APPLY в `iilResults` (по контракту) — в UI помечается; после записи dry-note исчезает.  
- Soft-open ПТСФ + STI_HOLE 69 — ожидаемо для sql_0 на чистой ИП без map всех разделов; для smoke лога достаточно.  
- Preview GATE/STI/SH endpoints по-прежнему вне UI-smoke (хвост контракта).
