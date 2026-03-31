# Type 5: Row Eligibility и Partial Apply (VBA semantics)

**Статус:** проектное правило для реализации reconcile `af_type=5`  
**Основание:** VBA `ra_aAllAgents.Audit()`, `AuditRaCreateNew`, `AuditRaEdit`, `AuditRcCreateNew`, `AuditRcEdit`  
**lastUpdated:** 2026-03-24

---

## Ключевой принцип

Для Type 5 применяется **частичная загрузка (partial apply)**:

- кондиционные строки применяются в доменные таблицы;
- некондиционные строки не применяются;
- по некондиционным строкам формируется диагностический лог "ход ревизии";
- наличие некондиционных строк **не должно** глобально блокировать применение кондиционных.

Глобальная блокировка допустима только при фатальных технических ошибках (SQL/транзакция/инфраструктура).

---

## Матрица обработки строки (RA-ветка)

| Условие строки | Категория | Действие в apply | Отражение в логе |
|---|---|---|---|
| `rainSign in ("ОА","ОА прочие")`, есть `periodKey/cstapKey/ogKey`, корректный canonical key | ELIGIBLE | `INSERT` (NEW) или `UPDATE` (CHANGED) в `ags.ra`; sums по правилу эволюции в `ags.ra_summ` | как примененная строка |
| Нет `periodKey` | REJECTED_MISSING_PERIOD | skip | `Нет периода` + значение |
| Нет `cstapKey` | REJECTED_MISSING_CSTAP | skip | `Нет стройки` + значение |
| Нет `ogKey` | REJECTED_MISSING_OG | skip | `Нет отправителя` + значение |
| Пустой/некорректный `rainRaNum` | REJECTED_INVALID_RA_NUM | skip | причина по номеру |
| `rainSign = "ОА изм"` | FILTERED_TO_RC | не обрабатывается в RA-ветке | служебный счётчик фильтра |
| `rainSign = "ОА Аренда"` (до выделения отдельной ветки) | REJECTED_UNSUPPORTED_SIGN | skip | причина по типу |
| >1 доменный кандидат по canonical key | REJECTED_AMBIGUOUS | skip | причина по неоднозначности |

---

## Матрица обработки строки (RC-ветка)

Для `rainSign = "ОА изм"` применяется аналогичный row-level подход:

- ELIGIBLE -> create/update в `ags.ra_change` + sums в `ags.ra_change_summ`;
- отсутствующие ключи/связи -> REJECTED с детализацией в логе;
- отсутствие части кондиционных строк не должно блокировать применение остальных кондиционных.

---

## Инварианты для Java реализации

1. `addRa=false` -> dry-run: без записи в домен, но с полными счётчиками.
2. `addRa=true` -> apply только для ELIGIBLE-строк.
3. REJECTED-строки всегда детализируются в `adt_results`.
4. Наличие REJECTED-строк не отменяет применение ELIGIBLE-строк.
5. Суммы (`ra_summ`, `ra_change_summ`) пишутся как эволюция версий:
   - вставка только при отличии от latest;
   - при равенстве skip.

---

## Минимальный набор счётчиков в "ходе ревизии"

- `rowsEligible`
- `rowsRejected`
- `rejectedByReason(...)`
- `inserted`
- `updated`
- `unchanged`
- `summInserted`
- `summUnchangedSkipped`
- `errors` (только технические/системные)

---

## Подтверждение на реальной БД (контролируемый тест)

Дата проверки: 2026-03-24 (audit `adt_key=14`, файл 2026).

Сценарий:

1. Зафиксирован baseline:
   - `ags.ra`: `count=49479`, `max(ra_key)=51537`
   - `ags.ra_summ`: `count=35851`, `max(ras_key)=37711`
2. Временный `adt_AddRA=true`, запуск `executeAudit(14)`.
3. Получен успешный apply (`exec_key=23`, `COMPLETED`):
   - `applied=true`, `affectedRows=1578`
   - `inserted=1578`, `updated=0`
   - `summInserted=1578`, `summUnchangedSkipped=0`
   - при этом некондиционные строки остались в диагностике (missing lookup и т.п.).
4. Выполнен rollback в транзакции:
   - `DELETE FROM ags.ra_summ WHERE ras_ra > 51537`
   - `DELETE FROM ags.ra WHERE ra_key > 51537`
5. Подтверждено восстановление baseline:
   - `ags.ra`: `count=49479`, `max(ra_key)=51537`
   - `ags.ra_summ`: `count=35851`, `max(ras_key)=37711`

Техническое уточнение:

- `ags.ra.ra_datePeriod` — вычисляемый столбец `ags.fnRaPeriodDate(ra_period)`;
- попытка записи в него вызывала SQL error 271;
- в Java-apply запись в `ra_datePeriod` исключена, вычисление выполняется на стороне БД.

