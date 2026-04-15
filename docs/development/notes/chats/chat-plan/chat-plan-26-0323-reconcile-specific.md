# План следующего шага: reconcile-specific по `af_type` (2/3/5/6)

**Дата создания:** 2026-03-23  
**Последнее обновление:** 2026-04-06  
**Проект:** FEMSQ  
**Версия плана:** 0.9.35  

---

## Цель
Реализовать и верифицировать доменную логику reconcile для `af_type ∈ {2,3,5,6}`:
- заполнение доменных таблиц согласно логике VBA,
- запись изменений в соответствующие `*_change`-журналы,
- идемпотентность повторного запуска на том же `exec_key`,
- чек-листы верификации и финальная ручная проверка.

---

## Вход в чат (что уже сделано)
В предыдущем чате `chat-plan-26-0319-excel-processing-parallel.md` выполнены:
- общий Excel-инфраструктурный каркас (`audit.excel`) и Stage 1–2 (FK/derived) для типов 2/3/5/6,
- общий reconcile-каркас (контракты `ReconcileContext/ReconcileResult`, координатор, транзакционные границы на тип файла) — `Фаза 5.0`.

---

## Фаза 0: Preflight для Type 5 перед `1.1.1` (Stage 1 smoke + качество staging) ✅
**Подтвердить, что данные из Excel реально и корректно загружаются в `ags.ra_stg_ra` до старта match-логики.**

### 0.1. Практический smoke-тест Stage 1 (Excel → `ra_stg_ra`) ✅
- ✅ 0.1.1. Выполнить запуск ревизии с файлом `af_type=5` при `af_source=true` — исполнено (`auditId=14`, успешный Stage 1).
- ✅ 0.1.2. Подтвердить создание/обновление записи запуска в `ags.ra_execution` и фиксировать `exec_key` — исполнено (последний проверенный `exec_key=9`).
- ✅ 0.1.3. Подтвердить по журналу, что вызван Stage 1 загрузки для `AllAgentsAuditFileProcessor` — исполнено (лог содержит `AllAgents processor Stage1 ... inserted=2133`).

**Краткая сводка исполнения (2026-03-23):**
- ✅ Stage 1 стабильно проходит для `af_type=5` и загружает staging.
- ✅ Добавлены диагностические счётчики причин отсева строк (`sourceRows/inserted/skipped*` и `signStats`).

### 0.2. DBHub-проверка факта загрузки по `exec_key` ✅
- ✅ 0.2.1. Проверить, что в `ags.ra_stg_ra` есть строки для текущего `rain_exec_key` — исполнено (`exec_key=10`, `rows=2133`).
- ✅ 0.2.2. Проверить, что `rain_exec_key` корректно изолирует строки текущего запуска — исполнено (последние запуски: `exec=10 -> 2133`, `exec=9 -> 2133`).
- ✅ 0.2.3. Проверить, что нет полностью пустых бизнес-строк (строки без ключевых значений) — исполнено (`fully_empty_business_rows=0`).

### 0.3. Проверка качества ключевых полей staging (для будущего `1.1.1`) ✅
- ✅ 0.3.1. Оценить долю `NULL/blank` по полям `rainRaNum`, `rainRaDate`, `rainCstAgPnStr`, `rainSender`, `rainSign` — исполнено (для `exec_key=10`: `rainRaNum=0`, `rainRaDate=1`, `rainCstAgPnStr=1`, `rainSender=0`, `rainSign=1`).
- ✅ 0.3.2. Проверить наличие проблем нормализации (пробелы/варианты регистра/невалидные даты) — исполнено (leading/trailing whitespace: `0`; даты типизированы SQL DATE, невалидные форматы в staging отсутствуют).
- ✅ 0.3.3. Зафиксировать первичные правила normalisation (trim/null/date) как вход для `1.1.1` — исполнено (приняты: `trimToNull` для строк, date только типизированная/`NULL`, контроль `rainSign` с явным учётом unsupported значений в reconcile-счётчиках).

**Краткая сводка исполнения (2026-03-23):**
- ✅ `exec_key`-изоляция подтверждена на последних прогонах.
- ✅ Критичных проблем качества ключевых полей для старта `1.1.1` не выявлено.

### 0.4. Контрольный запуск `af_source=false` ✅
- ✅ 0.4.1. Выполнить запуск той же ревизии/файла с `af_source=false` — исполнено (`auditId=14`, контрольный запуск с временным `af_source=false`).
- ✅ 0.4.2. Подтвердить, что Stage 1 не загружает новые строки в `ags.ra_stg_ra` — исполнено (`exec_key=11`, `rows_for_last_exec=0`).
- ✅ 0.4.3. Подтвердить корректное отражение skip в журнале выполнения — исполнено (лог: `AllAgents processor Stage1 ... inserted=0`, запуск завершён `COMPLETED`).

**Краткая сводка исполнения (2026-03-23):**
- ✅ Поведение `af_source=false` подтверждено: Stage 1 не выполняет загрузку в staging.
- ✅ После проверки рабочее значение `af_source` для `af_key=312` восстановлено в `true`.

### 0.5. Go/No-Go для старта `1.1.1` ✅
- ✅ 0.5.1. `GO`: Stage 1 стабильно загружает `ra_stg_ra`, ключевые поля пригодны для матчинга, `exec_key`-изоляция подтверждена — исполнено (решение: **GO**).
- ✅ 0.5.2. `NO-GO`: staging пустой/грязный, массовые пропуски ключевых полей или нет воспроизводимости — проверено, критерии `NO-GO` **не выполнены**.
- ✅ 0.5.3. При `NO-GO` — завести блокирующие задачи на исправление Stage 1 до начала `1.1.1` — **не требуется** (блокирующих задач нет).

**Краткая сводка решения (2026-03-23):**
- ✅ Принято итоговое решение `GO` для старта `1.1.1`.
- ✅ Переход к Фазе 1 (Type 5 reconcile) разрешён.

---

## Фаза 1: Type 5 (`ra_stg_ra` → `ags_ra` / `ags_ra_change`)
**Выполнить логику сверки и переноса данных VBA.**

### 1.1. Match-логика с доменными данными ✅
- ✅ 1.1.1. Зафиксировать канонический ключ матчинга `ra_stg_ra` → `ags_ra` (правила null/trim/date) — исполнено (ключ скорректирован к Access-логике в `AllAgentsReconcileService`: `(ogKey, cstapKey, periodKey, ra_num)`; добавлены счётчики `canonicalKeyValid/canonicalKeyInvalid`).
- ✅ 1.1.2. Реализовать lookup-резолвинг (`periodKey`, `cstapKey`, `ogKey`) для staging-строк — исполнено (резолвер приведён к `ra_ImpNewQu`: `rainRaDate -> ags.ra_period` по half-month, `rainCstAgPnStr -> ags.cstAgPn`, `rainSender -> ags.ogNmF_allVariantsNoRepeat.ogNm255`; добавлены счётчики `lookupResolvedAll/lookupMissing*/lookupAmbiguous*`).
- ✅ 1.1.3. Реализовать SQL/read-model сопоставления (аналог `ra_ImpNewQuRa`) — исполнено (в `AllAgentsReconcileService` добавлен read-model match по ключу `(ogKey,cstapKey,periodKey,ra_num)` с counters `matchRowsConsidered/matchFilteredSign/matchInvalid/matchMissing/matchAmbiguous/matchSingle/matchUnchanged/matchChanged`; вывод включён в `adt_results`).
- ✅ 1.1.4. Ввести классификацию результатов: `NEW / CHANGED / UNCHANGED / AMBIGUOUS / INVALID` — исполнено (в `AllAgentsReconcileService` добавлены явные категории `matchCategoryNEW/CHANGED/UNCHANGED/AMBIGUOUS/INVALID` на базе read-model матчинга; вывод включён в `adt_results`).
- ✅ 1.1.5. Зафиксировать правила обработки неоднозначности/пустого соответствия (лог + счётчики + блокировка apply) — исполнено в редакции VBA-semantics: row-level reject для некондиции без глобальной блокировки apply кондиционных строк.
- ✅ 1.1.6. Подготовить DBHub-check SQL по категориям матчинга — исполнено (`docs/sql-scripts/type5-match-categories-check.sql`: `applyEligibility`, проверка знака `ОА`/`ОА прочие` до `NEW`, `#classified` для нескольких result set, `partialApplyCoexistsRejected` вместо `shouldBlockApply`).
- ✅ 1.1.7. Реализовать row-level eligibility/reject для RA-ветки (`ELIGIBLE`, `REJECTED_*`, `FILTERED_TO_RC`) без глобального стопа apply — исполнено (в `AllAgentsReconcileService` убран глобальный блокиратор apply по `AMBIGUOUS/INVALID`; при `addRa=true` apply выполняется для кондиционных `NEW/CHANGED`, некондиция остаётся в логе и счётчиках).
- ✅ 1.1.8. Добавить счётчики `rowsEligible/rowsRejected/rejectedByReason(*)` и вывод в `adt_results` — исполнено (в `AllAgentsReconcileService.formatCounters`: `rowsEligible`, `rowsRejected`, `rejectedByReason(filteredToRc|invalidCanonical|disallowedSign|ambiguous)`).
- ✅ 1.1.9. Разделить `FILTERED_SIGN` (например, `ОА изм`) и реальные ошибки качества данных для RA-apply — исполнено (ветка RC считается отдельно как `rejectedByReason(filteredToRc)`; отказы по данным: `invalidCanonical`, `disallowedSign`, `ambiguous`).
- ✅ 1.1.10. Подготовить DBHub-check SQL для проверки partial-apply: при наличии rejected-строк apply кондиционных выполняется — исполнено практической проверкой на реальной БД (контролируемый test-run `exec_key=23`: `applied=true`, `affectedRows=1578`, последующий rollback до baseline).

### 1.2. Upsert в `ags_ra` ✅
- ✅ 1.2.1. Реализовать insert для `NEW` (аналог `AuditRaCreateNew`) — исполнено (в `AllAgentsReconcileService` добавлен apply-шаг: при `addRa=true` и отсутствии блокировки `AMBIGUOUS/INVALID` вставляются строки категории `NEW` в `ags.ra`; учтён mapping `ОА прочие -> ОА, прочие`).
- ✅ 1.2.2. Реализовать update для `CHANGED` (аналог `AuditRaEdit`) — исполнено (в `AllAgentsReconcileService` добавлен apply-шаг update для категории `CHANGED` по `ra_key` с обновлением сравниваемых полей RA; выполняется только при `addRa=true` и отсутствии блокировки `AMBIGUOUS/INVALID`).
- ✅ 1.2.3. Реализовать шаг эволюции сумм `ags.ra_summ` по правилам VBA: insert новой версии только при отличии от latest (`ags.raSmLt`), при равенстве — skip — исполнено (для `NEW` и `CHANGED` в `AllAgentsReconcileService` добавлен шаг `ra_summ` с проверкой latest по `ras_date/ras_key`; добавлены счётчики `summInserted/summUnchangedSkipped` в `adt_results`).
- ✅ 1.2.4. Реализовать dry-run режим при `addRa=false` (без записи в домен, но с полными счётчиками) — исполнено (в `AllAgentsReconcileService` при `addRa=false` включён расчёт `inserted/updated/summInserted/summUnchangedSkipped` без `INSERT/UPDATE`; добавлен флаг `dryRun=true` в `adt_results`).
- ✅ 1.2.5. Зафиксировать и писать в лог счётчики: `inserted/updated/unchanged/errors/summInserted/summUnchangedSkipped` — исполнено (в `AllAgentsReconcileService` в `adt_results` зафиксированы и выводятся `inserted/updated/unchanged/errors/summInserted/summUnchangedSkipped` с учётом dry-run/apply режимов).
- ✅ 1.2.6. Скорректировать apply-поведение `1.2.1–1.2.5` под partial apply из VBA: применять только `ELIGIBLE`, `REJECTED_*` только логировать — исполнено (глобальная блокировка apply снята; `INSERT/UPDATE/ra_summ` выполняются для строк, прошедших match-eligibility, rejected-строки не применяются и остаются в диагностике).

### 1.3. Запись изменений в `ags_ra_change`
- ✅ 1.3.1. Реализовать SQL/read-model сопоставления изменений (аналог `ra_ImpNewQuRc`) — исполнено: `RcStagingLineParser` (логика `RcStringNum`/`RcStringRaNum`/`RcStringRaDate`), загрузка `ags.ra` по `(ra_period, ra_num)`, `ags.ra_change` + `ra_chSmLt`, ключ `(ra_period, raс_ra, raс_num)` с учётом кириллических имён колонок в БД; счётчики `rcRowsConsidered/rcParseInvalid/rcCategoryNEW|UNCHANGED|CHANGED/...` в `adt_results` (`AllAgentsReconcileService`).
- ✅ 1.3.1.1. Подтвердить устойчивость regex-конвейера `RcStagingLineParser` на большом объёме вариантов исходных строк (ревизия с «толстым» type=5) — исполнено: см. **сводку прогона 2026-03-24** ниже.

**Сводка прогона парсера изменений (regex) — 2026-03-24**

Контролируемый полный прогон ревизии **13** (`test_25`, файл `2025 Свод инф-ции по ОА.xlsm`, больше строк staging, чем у ревизии 14), с **`adt_AddRA=true`** и последующим **полным откатом** доменных таблиц `ags.ra` / `ags.ra_summ` по снимкам (baseline восстановлен).

| Показатель | Значение (`exec_key=28`, фрагмент `adt_results`) |
|------------|--------------------------------------------------|
| Строк ветки RC, прошедших конвейер разбора | `rcRowsConsidered=609` |
| Строк, не попавших под шаблоны regex (остаются `rcParseInvalid`) | `rcParseInvalid=151` (см. разбор ниже; после правки парсера ожидается ~0 для этого класса строк) |
| После разбора: новые к доменному сравнению / без изменений / изменённые | `rcCategoryNEW=177`, `rcCategoryUNCHANGED=193`, `rcCategoryCHANGED=0` |
| Не найден базовый `ags.ra` под разобранный номер (не ошибка regex) | `rcMissingBaseRa=88` |

**Разбор `rcParseInvalid=151` (данные `ags.ra_stg_ra`, `rain_exec_key=28`, знак «ОА изм»)**

По коду `RcStagingLineParser.parse` счётчик `rcParseInvalid` в `AllAgentsReconcileService` увеличивается, если `parse` возвращает пустой `Optional` (цепочка: пустая строка → нет токена изменения → нет номера изменения → нет токена отчёта с «-» → нет даты).

Проверка в БД на тех же 609 строках:

- Строк, **не** содержащих подстроки `Изм` или `изм` с **учётом регистра** (Cyrillic_General_CS_AS): **151**.
- Строк, содержащих подстроку **`ИЗМ`** в верхнем регистре: **151**.

То есть **все 151** «неразобранных» на прогоне строк — это не «левый» формат текста, а **полностью прописанные «ИЗМ» / «ИЗМЕНЕНИЕ»**, на которые не срабатывали:

1. `containsIzmenenieToken` — искал только подстроки `Изм` и `изм` (в «ИЗМ» нет строчной «з»);
2. шаблон `CHANGE_HEAD` — без флага case-insensitive не находил «ИЗМ…».

**Исправление (2026-03-24):** в `RcStagingLineParser` — `token.toLowerCase(ru).contains("изм")` для токена и `Pattern.CASE_INSENSITIVE | UNICODE_CASE` для `CHANGE_HEAD`; регрессия в `RcStagingLineParserTest` (пример `ИЗМ 1 в ГР25-…`).

**Вывод:** на большом объёме конвейер отработал стабильно; «151» — **артефакт регистрозависимой проверки**, а не следствие нехватки regex на произвольный мусор. После правки для повторного прогона имеет смысл сверить новые `rcParseInvalid` (останутся только реальные отклонения: нет даты, нет дефиса в номере отчёта и т.д.). Apply для RC по-прежнему только read-model (п.п. 1.3.2–1.3.4 не реализованы).

**Повторный прогон после деплоя JAR (2026-03-25, `exec_key=29`)**

Контролируемый повторный запуск ревизии **13** после case-insensitive исправления `RcStagingLineParser`:
- статус `exec_add_ra=false` (dry-run, без записи в доменные таблицы);
- в `adt_results` для ветки RC: `rcRowsConsidered=609`, `rcParseInvalid=0`;
- разбор стартовал с `Reconcile start: type=5, execKey=29`.

**Вывод:** класс отказов «только верхний регистр ИЗМ/ИЗМЕНЕНИЕ» устранён — `rcParseInvalid` для этого источника данных стал равен нулю. Apply для RC по-прежнему только read-model.

**Проверка на другой ревизии (adt_key=14, exec_key=31)**

Контролируемый dry-run ревизии **14** после case-insensitive исправления:
- `exec_add_ra=false` (apply-skipped)
- ветка RC: `rcRowsConsidered=71`, `rcParseInvalid=1`
- `rcMissingBaseRa=58`, `rcCategoryNEW=12`, `rcCategoryUNCHANGED=0`, `rcCategoryCHANGED=0`

**Вывод:** на ревизии 14 доля `rcParseInvalid` также стала минимальной (1 строка из 71), то есть фикс не регрессировал другой дата-срез.

- ✅ 1.3.2. Реализовать create для `rac_key is null` (аналог `AuditRcCreateNew`): вставка делается в `ags.ra_change` и в базовую историю `ags.ra_change_summ`, т.к. `ags.ra_chSmLt` является `VIEW` (direct insert в него невозможен)
  - **Исполнение (проверка)**: `executeAudit(14)` с `adt_AddRA=true` (`exec_key=33`) показал `rcChangesInserted=12` и `rcSumsInserted=12`; затем выполнен rollback до baseline.

- ✅ 1.3.3. Реализовать update для `rac_key is not null and rs=false` (аналог `AuditRcEdit`): обновление полей в `ags.ra_change` + эволюция сумм в `ags.ra_change_summ` (вставка новой версии только при отличии от latest в `ags.ra_chSmLt`)
  - **Исполнение (проверка)**: добавлен контролируемый интеграционный тест `RcChangeApplyIntegrationIT`, который создаёт `CHANGED` (искусственно портит одну строку `ags.ra_change`) и ожидает `rcChangesUpdated>=1`, затем делает rollback по диапазонам ключей. Запуск: `mvn test -pl femsq-web -Dtest=RcChangeApplyIntegrationIT -Dfemsq.integration.rcApply=true`.
- ✅ 1.3.4. Реализовать эволюцию сумм изменений `ags.ra_change_summ`: insert новой версии только при отличии от latest (`ags.ra_chSmLt`), при равенстве — skip
  - **Исполнение (проверка)**: эволюция сумм вынесена в общий хелпер (используется и в 1.3.2, и в 1.3.3). Для 1.3.3 проверка выполняется через `RcChangeApplyIntegrationIT` (искусственно создаёт расхождение и проверяет update), а при отсутствии расхождений ожидание — рост `rcSumsUnchangedSkipped`.
- ✅ 1.3.5. Привязать все действия к текущему `exec_key` и сверять счётчики с reconcile-результатом
  - **Реализация**: в `adt_results` добавлены поля план/факт для RC apply, рассчитанные на данных текущего `rain_exec_key`: `rcApplyPlannedNew/rcApplyPlannedChanged` и дельты `rcApplyDeltaNew/rcApplyDeltaChanged` (сколько “ожидалось” по read-model и сколько реально вставлено/обновлено в apply).

### 1.4. Специфические операции из VBA
- ✅ 1.4.1. Реализовать delete-ветку для RA (аналог A4: есть в БД, отсутствует в источнике)
  - **Реализация**: вычисляется план `raDeletePlanned` для доменных строк `ags.ra`, которые попадают в scope текущего exec (по `ra_period` из кондиционных source-строк), но отсутствуют в source canonical key set. Применение удалений защищено флагом `-Dfemsq.reconcile.type5.enableDeletes=true`; по умолчанию только лог/счётчики.
- ✅ 1.4.2. Реализовать delete-ветку для RC (аналог B4: есть в БД, отсутствует в источнике)
  - **Реализация**: вычисляется план `rcDeletePlanned` для `ags.ra_change` (scope по `rcPeriod` из source RC-строк), удаление (сначала `ags.ra_change_summ`, потом `ags.ra_change`) также включается только через `-Dfemsq.reconcile.type5.enableDeletes=true`.
- ✅ 1.4.3. Зафиксировать decision по `close/reopen`
  - **Решение**: на текущем этапе **не реализуем** `close/reopen` для Type 5 (ни для RA, ни для RC).
  - **Причина**: в схемах `ags.ra` / `ags.ra_change` нет явного поля статуса закрытия, а предметная семантика “закрыть/переоткрыть” должна быть подтверждена по VBA/Access‑логике и правилам бизнеса (иначе риск неверного изменения жизненного цикла документов).
  - **Текущее поведение**: только `create/update` (1.2/1.3.2/1.3.3) и опциональный `delete` (1.4.1/1.4.2) под явным guard‑флагом.
- ✅ 1.4.4. Зафиксировать порядок выполнения операций: блок A (`ags_ra`) → блок B (`ags_ra_change`)
  - **Реализация**: в `AllAgentsReconcileService.reconcileInTransaction` порядок apply соответствует VBA: сначала apply RA (`ags.ra` + `ags.ra_summ`), затем apply RC (`ags.ra_change` + `ags.ra_change_summ`), затем (опционально) delete‑ветки под guard‑флагом (`RA`‑delete, затем `RC`‑delete).

### 1.5. Идемпотентность type 5
- ✅ 1.5.1. Идемпотентность через marker-таблицу `ags.ra_reconcile_marker` (шаги `TYPE5_APPLY_RA` / `TYPE5_APPLY_RC` / `TYPE5_DELETE_RA` / `TYPE5_DELETE_RC`)
- ✅ 1.5.2. Защититься от дублей на уровне SQL (ключи/индексы/условия upsert)
  - **Реализация**: в `insertNewRaRows` добавлен SQL guard `WHERE NOT EXISTS` на вставку в `ags.ra` по ключам read-model `(ra_period, ra_num)` + при “уже существующей” записи резолвится `ra_key` для корректной эволюции `ags.ra_summ`.
- ✅ 1.5.3. Проверить повторный запуск на одном `exec_key` (без дублей/потерь)
  - **Исполнение (проверка)**: добавлен интеграционный тест `Type5ExecKeyIdempotencyIntegrationIT`, который после `executeAudit(14)` берёт последний `exec_key` и дважды вызывает `AllAgentsReconcileService.reconcile(new ReconcileContext(exec_key, 14, true, 5))`, проверяя, что max-ключи/кол-ва строк в `ags.ra`, `ags.ra_summ`, `ags.ra_change`, `ags.ra_change_summ` и marker-строки для `exec_key` не меняются. Запуск: `mvn test -pl femsq-web -Dtest=Type5ExecKeyIdempotencyIntegrationIT -Dfemsq.integration.type5ExecIdem=true`.
- ✅ 1.5.4. Проверить повторный запуск по той же ревизии с новым `exec_key`
  - **Исполнение (проверка)**: добавлен интеграционный тест `Type5NewExecKeyIdempotencyIntegrationIT`: запускает `executeAudit(14)` несколько раз (получая разные `exec_key`) и для каждого `exec_key` вызывает `AllAgentsReconcileService.reconcile(new ReconcileContext(exec_key, 14, true, 5))`, проверяя сходимость: на втором/третьем `exec_key` доменные max-ключи `ags.ra/ra_summ/ra_change/ra_change_summ` больше не растут (нет дублей/лишних версий), при этом marker-таблица фиксирует шаги для каждого `exec_key`. Запуск: `mvn test -pl femsq-web -Dtest=Type5NewExecKeyIdempotencyIntegrationIT -Dfemsq.integration.type5NewExecIdem=true`.
- ✅ 1.5.5. Проверить поведение при частичном сбое (rollback и повторный безопасный запуск)
  - **Исполнение (проверка)**: добавлен интеграционный тест `Type5PartialFailureRecoveryIntegrationIT`, который получает `exec_key` через `executeAudit(14)` в dry-run (`adt_AddRA=0`), затем вызывает reconcile apply c искусственным падением после шага `TYPE5_APPLY_RA` (через `-Dfemsq.reconcile.type5.simulateFailureStep=TYPE5_APPLY_RA`) и проверяет, что домен и marker-таблица не меняются (rollback). После этого выполняет повторный reconcile без флага и проверяет успешное применение + идемпотентность повторного вызова на том же `exec_key`. Запуск: `mvn test -pl femsq-web -Dtest=Type5PartialFailureRecoveryIntegrationIT -Dfemsq.integration.type5FailureRecovery=true`.

### 1.6. Верификация type 5
- ✅ 1.6.1. Подготовить чек-лист SQL-верификации для DBHub (`docs/sql-scripts/type5-verification-checklist.sql`)
- ✅ 1.6.2. Сверять цепочку `ra_stg_ra` → `ags_ra` → `ags_ra_change` → journal выполнения (`docs/sql-scripts/type5-chain-stg-domain-journal.sql`)
- ✅ 1.6.3. Сверять reconcile-счётчики с фактическими count в БД (`docs/sql-scripts/type5-counters-vs-db-check.sql`)
- ✅ 1.6.4. Зафиксировать шаблон отчёта ручной проверки (exec_key, expected vs actual, итог) (`docs/development/notes/templates/type5-manual-verification-report-template.md`)
- ✅ 1.6.5. Подтвердить VBA-аналогию partial apply: наличие некондиционных строк не препятствует внесению кондиционных — исполнено контролируемым тестом с обратимостью (внесение подтверждено, baseline восстановлен).

### 1.7. Минимальный вертикальный срез Type 5 (порядок реализации)
- ✅ 1.7.1. Инкремент A: `match (RA)` → SQL-проверка через DBHub — исполнено по факту: `AllAgentsReconcileService.buildRaReadModel` + счётчики/`adt_results` + `docs/sql-scripts/type5-match-categories-check.sql` (категории, `applyEligibility`, partial apply).
- ✅ 1.7.2. Инкремент B: `upsert (RA)` → SQL-проверка через DBHub — исполнено по факту: insert/update/`ra_summ` в `AllAgentsReconcileService`, контрольный прогон `exec_key=23` (`inserted`/`affectedRows` vs rollback), артефакт пост-проверки `docs/sql-scripts/type5-post-apply-ra-sanity.sql`.
- ✅ 1.7.3. Инкремент C: `match + upsert (RA_CHANGE)` → SQL-проверка через DBHub (`docs/sql-scripts/type5-rc-match-apply-check.sql`)
- ✅ 1.7.4. Инкремент D: идемпотентность на одном `exec_key` (marker-таблица + интеграционный тест `Type5ExecKeyIdempotencyIntegrationIT`)
- ✅ 1.7.5. Инкремент E: delete-ветки и финальная сверка счётчиков/журнала (`docs/sql-scripts/type5-delete-final-check.sql`)

### 1.8. Ход ревизии (логирование, parity с Access/VBA)
- ✅ 1.8.1. Архитектура и требования (актуальный источник): `docs/development/notes/audit-log/audit-log-vba-to-java-mapping.md`  
  _(ранее: `audit-execution-log-vba-parity.md`, переведён в `deprecated` после консолидации)_
- ✅ 1.8.2. Каталог событий (compact, актуальный источник): `docs/development/notes/audit-log/audit-log-vba-to-java-mapping.md`  
  _(ранее: `audit-log-event-catalog.md`, переведён в `deprecated` после консолидации)_
- ✅ 1.8.3. Mapping VBA→Java: `docs/development/notes/audit-log/audit-log-vba-to-java-mapping.md`
  - ✅ 1.8.3.1. Извлечён список “ключевых событий” оркестровки из VBA (`btnAuditRun_Click` + `RAAudit_*`, без полного дампа всех строк)
  - ✅ 1.8.3.2. Выполнено первичное сопоставление этих событий с точками в Java (present/partial/missing)
- ✅ 1.8.4. План внедрения (актуальный источник): `docs/development/notes/audit-log/audit-log-vba-to-java-mapping.md`  
  _(ранее: `audit-log-implementation-plan.md`, переведён в `deprecated` после консолидации)_
  - ✅ 1.8.4.1. Внедрён базовый каркас оркестровки в Java (universal events): `AUDIT_END`, `FILE_START/FILE_END`, `WORKBOOK_OPEN/WORKBOOK_CLOSE`, `SHEET_FOUND/SHEET_MISSING`, `STAGING_START/STAGING_END`
  - ✅ 1.8.4.2. Добавлена вложенность (ревизия → файл → workbook → staging → reconcile) через `spanId/parentSpanId` в `AuditLogEntry` и отступы при рендеринге `adt_results`
  - ✅ 1.8.4.3. Нормализованы уровни и тексты: WARNING/ERROR задаются `AuditLogLevel`, HTML‑сообщения без префиксов вида `WARN:`
  - ✅ 1.8.4.4. END‑события блоков дополнены длительностью (duration) для основных span‑блоков, включая `RECONCILE_*`
  - ✅ 1.8.4.5. Улучшен `RECONCILE_DONE/SKIPPED`: добавлено краткое резюме ключевых счётчиков (1–2 строки) в `adt_results`
  - ✅ 1.8.4.6. Унифицированы вызовы логирования: заменены оставшиеся `appendEntry(new AuditLogEntry(...))` на `context.append(...)`/`beginSpan/endSpan` в оркестраторе и file‑processor’ах (оставлена защита auto-parenting в `AuditExecutionContext`)
- ✅ 1.8.4.7. Выполнена консолидация документации audit-log в единый source-of-truth  
  - ✅ В `audit-log-vba-to-java-mapping.md` добавлены разделы `Event Catalog (compact)` и `Implementation Backlog (compact)`  
  - ✅ Файлы `audit-execution-log-vba-parity.md`, `audit-log-event-catalog.md`, `audit-log-implementation-plan.md` переведены в `deprecated` с указанием актуального источника
- ✅ 1.8.5. Шаблон ручной проверки: `docs/development/notes/templates/audit-log-manual-review-template.md`
  - ✅ 1.8.5.1. Выполнена ручная проверка на реальном прогоне (`adt_key=14`, `exec_key=57`): подтверждены вложенность и последовательность блоков (`AUDIT -> FILE -> WORKBOOK -> STAGING -> RECONCILE`), наличие duration на `END`, краткое reconcile‑резюме counters в `adt_results`; polling/выполнение завершаются штатно, без JS‑ошибок.

### 1.8.6. Визуальный контракт журнала (отступы/выделения)
- ✅ 1.8.6.1. Согласовать и зафиксировать шаг отступа (px на уровень вложенности) + правила выравнивания
  - ✅ Контракт: `indentStep=16px` на уровень вложенности; раскрытие по умолчанию `AUDIT/FILE=open`, `WORKBOOK/STAGING/RECONCILE=collapsed`, авто‑раскрытие при наличии `WARNING/ERROR` внутри блока
- ✅ 1.8.6.2. Добавить цветовые выделения в `adt_results` по `AuditLogLevel` (INFO/WARNING/ERROR/SUCCESS/SUMMARY) через inline‑style (самодостаточный HTML)
- ✅ 1.8.6.3. Добавить визуальные маркеры блоков START/END (например, border-left, фон, жирный заголовок) без потери копируемости текста
  - ✅ Реализовано свёртывание/развёртывание блоков через `<details>/<summary>` для span‑блоков
  - ✅ Добавлены бейджи `START/END` и подсветка строк по `AuditLogLevel` (self‑contained HTML + inline CSS)

### 1.8.7. Инкрементальная “подача” лога (не только после завершения файла)
- ✅ 1.8.7.1. Уточнить поведение: когда именно `adt_results` обновляется во время RUNNING (оценка “streaming”)
  - ✅ Зафиксировано контрольным опросом GraphQL `audit(id)` во время `RUNNING`: `adtUpdated` меняется инкрементально в процессе выполнения (не только по завершению файла/ревизии).
- ✅ 1.8.7.2. Реализовать throttled flush: периодическое сохранение `adt_results` (например, раз в 0.5–2 сек или по ключевым событиям) во время Stage1/Stage2/Reconcile для длинных файлов
  - ✅ Реализовано через `AuditExecutionContext.setOnEntryAppended(...)` + `ThrottledProgressFlusher` в `AuditExecutionServiceImpl` (интервал 1 сек, безопасный throttling, финальная контрольная фиксация сохранена).
- ✅ 1.8.7.3. Проверить UI‑сценарий: во время RUNNING лог “растёт сверху”, без зависаний, polling не ломается при частых обновлениях
  - ✅ Исправление высот/скролла при открытии карточки и при росте `adt_results`:
    - `audit-form-card` ограничен сверху: `max-height: calc(100vh - 210px)` (чтобы карточка не росла и не “съедала” свободное место под лог).
    - `audit-log-container` ограничен сверху и скроллится внутри: `max-height: calc(100vh - 350px)` + `overflow-y: auto` (чтобы при переполнении текст не выходил за видимую область).
    - Для корректной flex-цепочки использованы `min-height: 0` на промежуточных flex-контейнерах и `overflow: hidden` там, где это нужно для передачи “ответственности” скролла контейнеру лога.
    - Убрано бесполезное/вредное правило для `.q-panel` внутри `QTabPanels` (вставки такого враппера для `QTabPanels` нет; это создавало риск разрыва высотной цепочки).
  - ✅ Фактический результат: при открытии после Ctrl+F5 и при активном выполнении контроль лога имеет собственный скролл, а нижние строки не “уезжают” вне видимости вместе с ростом высоты карточки.

### 1.8.8. Проверки на реальных режимах (Excel + apply в домен)
- ✅ 1.8.8.1. Длинный прогон с реальным чтением Excel (объёмный файл) — лог обновляется инкрементально и остаётся читаемым
  - **Факт прогона (2026-04-15):** `auditId=13`, dry-run (`adt_AddRA=0`), `executeAudit(13)` → `exec_key=1116`, `exec_status=COMPLETED`.
  - **Инкрементальность подтверждена:** в фазе `RUNNING` зафиксировано **7** последовательных обновлений `adt_results` (`adt_updated` рос на каждом тике; `LEN(adt_results)` вырос с `3205` до `7943548`).
  - **Читаемость/полнота:** итоговый `adt_results` содержит ключевые фазы (`Начало ревизии`, `ревизия завершена`) и диагностический режим (`сухойПрогон=true`).
  - **Безопасность:** исходное значение `adt_AddRA` восстановлено (`restored adt_AddRA=0`), доменные apply-операции не выполнялись.
- ✅ 1.8.8.2. Прогон с `adt_AddRA=true` (apply) + контроль безопасности (snapshot/rollback) — корректность лога и обратимость подтверждены
  - **Факт прогона (2026-04-15):** `auditId=13`, apply-run (`adt_AddRA=1`), `executeAudit(13)` → `exec_key=1117`, `exec_status=COMPLETED`.
  - **Лог apply подтверждён:** в `adt_results` присутствуют `применение`, `addRa=true`, `Type5 match — RA:`, `Type5 apply — RA:`, `сухойПрогон=false`, а также row-level signal (создание записей/сумм/validation/excess).
  - **Snapshot before apply:** baseline max-ключи  
    `ra=51537`, `ras=37711`, `rac=3429`, `racs=2409`.
  - **После apply:** max-ключи выросли  
    `ra=104849`, `ras=92496`, `rac=5021`, `racs=4001` (`delta`: `+53312/+54785/+1592/+1592`).
  - **Rollback:** удаление хвостов `WHERE key > baseline` для `ags.ra_summ`, `ags.ra`, `ags.ra_change_summ`, `ags.ra_change`; результат: `rollback ok = true` (все max-ключи вернулись к baseline), `adt_AddRA` восстановлен в `0`.
- ✅ 1.8.8.3. Отдельно проверить ветки ошибок: отсутствует файл/лист/якорь/ошибка парсинга ячейки — WARN/ERROR и точка остановки подтверждены
  - **Сценарий A (отсутствует файл):** временно `ags.ra_f.af_name='/tmp/__femsq_missing_file_1883__.xlsm'` для `af_key=308`; прогон `exec_key=1118`, статус `COMPLETED`, в `adt_results` есть понятный маркер `в файловой системе не обнаружен` (ветка file-missing отработала без падения ревизии).
  - **Сценарий B (отсутствует лист):** временно `ags.ra_sheet_conf.rsc_sheet='__MISSING_SHEET_1883__'` (`rsc_key=1`); прогон `exec_key=1120`, статус `FAILED`, в `adt_results` зафиксированы:
    - `Лист не найден: __MISSING_SHEET_1883__`
    - `Ошибка выполнения ревизии. Подробности см. в журнале сервера.`
    - **Точка остановки:** явный переход в `FAILED`.
  - **Сценарий C (отсутствует якорь):** временно `ags.ra_sheet_conf.rsc_anchor='__MISSING_ANCHOR_1883__'` (`rsc_key=1`); прогон `exec_key=1121`, статус `FAILED`, в `adt_results` зафиксированы:
    - `Якорь не найден: __MISSING_ANCHOR_1883__, лист=Отчеты`
    - `Ошибка выполнения ревизии. Подробности см. в журнале сервера.`
    - **Точка остановки:** явный переход в `FAILED`.
  - **Сценарий D (ошибка парсинга/валидации ячейки):** контрольный прогон `exec_key=1122`, статус `COMPLETED`; в `adt_results` подтверждено наличие диагностической ветки парсинга/валидации:
    - счётчик `ошибокПарсингаИзменений=...` (ветка `rcParseInvalid`),
    - row-level сообщения `RA: отказ валидации (...)`.
  - **Безопасность/восстановление:** после каждого сценария восстановлены исходные значения `af_name`, `rsc_sheet`, `rsc_anchor`; рабочий режим ревизии возвращён в dry-run (`adt_AddRA=0`).

### 1.8.9. Следующий инкремент: реализация TARGET‑сообщений в Java (по mapping)
- ✅ 1.8.9.1. Реализовать в коде `J-A [MSG][TARGET]` для оркестровки (`msg.start/msg.end`, `dir lookup`, `dir fs`, `file fs`, `files.empty`) и перевести соответствующие `status` в mapping из `missing` в `present/semantic`
  - ✅ Реализованы события `DIR_LOOKUP_FOUND`, `DIR_LOOKUP_NOT_FOUND`, `FILES_EMPTY` в `AuditExecutionServiceImpl`; расширены `AUDIT_START`/`AUDIT_END` (включая поля времени и статус завершения).
  - ✅ В `audit-log-vba-to-java-mapping.md` статусы по `V-A`/`J-A` для оркестровочных сообщений переведены в `present` (workbook lifecycle по-прежнему `semantic` через `J-B.1.1/1.2`).
- ✅ 1.8.9.2. Для узлов `V-A` с map на `J-B.1.1/1.2` (`WORKBOOK_OPEN/CLOSE`) зафиксировать окончательное решение: оставить `semantic` (без app-level Excel событий) либо добавить явные app-level сообщения и обновить mapping/каталог
  - ✅ Принято решение: **оставить `semantic`**, app-level события `EXCEL_APP_OPEN/CLOSE` не добавлять.
  - ✅ Обоснование: фактическая точка открытия/закрытия книги находится в едином Excel-layer (`DefaultAuditStagingService`), событие `WORKBOOK_OPEN/CLOSE` достаточно для диагностики и не дублирует оркестратор.
  - ✅ Зафиксировано в mapping: для `V-A.1.2.b.b.check.b1`, `V-A.1.2.b.b.check.b2.0.a.0.a1`, `V-A.1.msg.excel.close` статус остаётся `semantic` c map на `J-B.1.1/1.2`.
- ✅ 1.8.9.3. Синхронизировать ключи/поля событий в коде и mapping (`eventKey`, `messageType`, `colorHint`, `emphasis`) и проверить, что HTML остаётся только render-слоем
  - ✅ В `AuditExecutionServiceImpl` для оркестровочных событий добавлено единое обогащение meta-полей: `messageType`, `colorHint`, `emphasis` (helper `withPresentationMeta(...)`).
  - ✅ Ключи `eventKey` синхронизированы с mapping (`AUDIT_START/END`, `DIR_LOOKUP_*`, `DIR_FS_*`, `FILE_*`, `FILES_EMPTY`, `AUDIT_ERROR`).
  - ✅ Подтверждено правило: HTML используется как render-слой, source-of-truth для визуальной семантики — структурированные meta-поля события.
- ✅ 1.8.9.4. Выполнить контрольный прогон и обновить `V-A -> J-*` статусы (`missing/partial/semantic/present`) по факту реализации
  - ✅ Контрольный прогон выполнен (`auditId=13`) через GraphQL `executeAudit` + polling `audit(id)`: статус `COMPLETED`.
  - ✅ В `adt_results` подтверждены ключевые оркестровочные сообщения (`Начало ревизии`, `Время начала`, `Имя директории`, `Файл пропущен (по настройке)`, `ревизия завершена`).
  - ✅ Актуальные статусы `V-A -> J-*` в `audit-log-vba-to-java-mapping.md` зафиксированы: оркестровка `present`, workbook lifecycle `semantic` (по принятому решению 1.8.9.2).

### 1.8.10. Закрытие «дыры» между оркестровкой и type=5 (принцип «от общего к частному»)
- ✅ 1.8.10.1. Шаг 1: сформировать полный inventory сообщений VBA для `ra_aAllAgents.cls` (`Audit`, `AuditRa*`, `AuditRc*`, `RaReadOfExcel`)
  - ✅ Выделены `V-C.* [MSG]` с условиями появления и группировкой по подветкам: `V-C.R`, `V-C.RA`, `V-C.RA.C/E`, `V-C.RC`, `V-C.RC.C/E`.
  - ✅ В mapping добавлены message-категории по фактической логике `ra_aAllAgents.cls`: row-level `paragraph`, summary-count блоки, new/changed/excess, mismatch(old/expected), apply-result.
  - ✅ Для inventory зафиксирована визуальная семантика VBA (Crimson/Peru/SeaGreen/OrangeRed/Blue) как база для последующего `J-C.5 [TARGET]` контракта.
- ✅ 1.8.10.2. Шаг 2: добавить целевое дерево `J-C.5.* [MSG][TARGET]` с разбиением по существующим Java-файлам
  - ✅ Добавлен блок `J-C.5.A` (`AllAgentsAuditFileProcessor`): `FILE_ALL_AGENTS_STAGE1`, `FILE_ALL_AGENTS_STAGE2_NOOP`, переход к reconcile.
  - ✅ Добавлен блок `J-C.5.B` (`DefaultAuditStagingService`): `WORKBOOK_*`, `SHEET_*`, целевые `ANCHOR_*`, `STAGING_*`.
  - ✅ Добавлен блок `J-C.5.C` (`AllAgentsReconcileService`): целевые события `RECONCILE_TYPE5_*` (start/match/apply/diagnostics/done-skipped-failed).
  - ✅ Для всех `J-C.5.* [TARGET]` зафиксированы `eventKey`, `scope`, минимальный `meta`-контракт и правила `map/status/gap`.
- ✅ 1.8.10.3. Шаг 3: реализовать `J-C.5 [TARGET]` по слоям (сначала агрегаты, потом row-level)
  - ✅ Layer 1: process-level parity (этапы type=5 в читаемом виде, без перегруза лога).
    - ✅ `AllAgentsAuditFileProcessor`: добавлены meta-контракты для `FILE_ALL_AGENTS_STAGE1` и `FILE_ALL_AGENTS_STAGE2_NOOP` (`messageType/colorHint/emphasis` + `auditId/filePath/fileType/...`).
    - ✅ `DefaultAuditStagingService`: добавлены `ANCHOR_FOUND/ANCHOR_MISSING`, meta-контракты для `WORKBOOK_*`, `SHEET_*`, `STAGING_*`.
    - ✅ `AuditReconcileCoordinator`: введены type5-коды `RECONCILE_TYPE5_START|DONE|SKIPPED|FAILED` и структурированные meta-поля.
  - ✅ Layer 2: row-level parity для `V-C.2.1.a.1.1.a.*` (эквивалент `paragraph`) с ограничением шума (`top-N + counters`).
    - ✅ `DefaultAuditStagingService`: добавлены ограниченные row-level события `ROW_PARAGRAPH_PREVIEW` / `ROW_PARAGRAPH_PREVIEW_SKIPPED` для type=5.
    - ✅ Введено ограничение шума: `ROW_PREVIEW_LIMIT=12`, плюс итоговый `ROW_PARAGRAPH_PREVIEW_SUMMARY` (sampled/suppressed/total).
    - ✅ Сохранён принцип render-layer: визуальная семантика хранится в `meta` (`messageType/colorHint/emphasis`), HTML только отображение.
  - ✅ Проверено: HTML остаётся render-слоем, визуальная семантика вынесена в `meta` для новых событий type5.
- ✅ 1.8.10.4. Шаг 4: выполнить контрольный прогон type=5 и обновить статусы `V-C -> J-C.5`
  - ✅ 1.8.10.4.1. Контрольный прогон выполнен (`auditId=13`) через GraphQL `executeAudit` + polling `audit(id)` до `COMPLETED`.
  - ✅ 1.8.10.4.2. В фактическом `adt_results` подтверждён type5 pipeline (`Этап 1 (Все агенты)` + `Сверка`) и отсутствие регрессии оркестровки.
  - ✅ 1.8.10.4.3. Статусы в mapping обновлены по факту: process-level `J-C.5.A/B/C` — `present/partial`; row-level preview — `partial` (зависит от наличия/качества строк и лимита `top-N`).
  - ⚠️ 1.8.10.4.4. В контрольном наборе не зафиксированы явные `ROW_PARAGRAPH_PREVIEW*` записи; для полного визуального подтверждения row-level нужен отдельный прогон на файле/периоде с репрезентативными строками type 5.
    - 1.8.10.4.4.1. **Методика проверки `adt_results`:** технические коды событий (`ROW_PARAGRAPH_PREVIEW*`, многие `ANCHOR_*` и др.) в сохранённом HTML через `AuditExecutionContext.localizeCode` чаще отображаются как «СОБЫТИЕ», а не как исходный `eventKey`; поиск сырой подстроки `ROW_PARAGRAPH_PREVIEW` в HTML не доказывает отсутствие события. Для верификации row-level ориентироваться на **текст тела сообщения**: `paragraph: row=` / `paragraph-skip: row=`, фразы «добавлено в staging», «пропущено (нет достаточных данных)», блок `Row-level preview`, строка `[AuditStaging] sheet=` из `STAGING_LOAD_STATS` и аналоги.
      - ✅ **Применение методики (2026-04-01):** по GraphQL `audit(id:13|14) { adtResults }` проверены подстроки из списка выше. В HTML **обеих** ревизий **нет** `paragraph: row=`, `paragraph-skip: row=`, «добавлено в staging», «пропущено (нет достаточных данных)», `Row-level preview`; подстрока `ROW_PARAGRAPH_PREVIEW` тоже отсутствует. При этом присутствует агрегат staging-статистики с префиксом **`[AuditStaging]`** (в выводе после локализации — `лист=…`, `таблица=staging РА`, счётчики строк). **Вывод:** в сохранённом `adt_results` нет ни технических кодов row-level, ни их текстовых тел — отсутствие превью **не** объясняется только подменой кода на «СОБЫТИЕ»; дальнейший разбор — по 1.8.10.4.4.3–1.8.10.4.4.4 (п. 4.4.2 проверен: `af_source` не причина).
    - 1.8.10.4.4.2. **Условие вызова staging для type=5:** в `AllAgentsAuditFileProcessor` `loadToStaging` выполняется только при `Integer.valueOf(1).equals(file.getSource())` (в БД — признак источника `af_source`). Проверить для контрольного файла type=5 значение `afSource`; при `false`/`NULL` staging и row-level превью не выполняются, хотя файл в каталоге один.
      - ✅ **Проверка (2026-04-01):** GraphQL `file(id:308|312)` и `filesByDirectory(14|15)`: для единственных файлов type=5 в контрольных каталогах **`afSource: true`** (ревизия 13 → `afKey=308`, ревизия 14 → `afKey=312`), `afExecute: true`. В `AuditExecutionServiceImpl` это даёт `AuditFile.source=1`, условие `AllAgentsAuditFileProcessor` на вызов **`loadToStaging` выполняется**. **Вывод:** отсутствие row-level превью в `adt_results` **не** объясняется выключенным `af_source`; гипотеза 1.8.10.4.4.2 для контрольного набора **снята** → далее 1.8.10.4.4.3–1.8.10.4.4.4.
    - 1.8.10.4.4.3. **Если staging вызывался, а превью строк нет:** возможен ранний выход до цикла по строкам — например, пустой список `insertColumns` после `resolveInsertColumns` (нет ни одной колонки для вставки), либо в обрабатываемом диапазоне нет ни одной строки, дающей `rowParagraphTotal > 0` (тогда нет и `ROW_PARAGRAPH_PREVIEW_SUMMARY`). Сверить маппинг колонок, якорь и заголовок, `ra_sheet_conf` / лист, схему staging-таблицы, наличие `executionKey` для exec-колонки.
      - ✅ **Проверка (2026-04-01):** по **старым** снимкам `adt_results` (до повторного прогона) уже видно, что цикл загрузки **отрабатывал**: блок `[AuditStaging] …` с ненулевым `добавлено=` / `строкВИсточнике=` (ревизии 13 и 14). Значит ветка **`insertColumns.isEmpty()` с немедленным `return 0`** для этих прогонов **не срабатывала** (при пустых колонках не было бы массовой вставки и агрегатной статистики в том же духе). Якорь и лист подтверждены косвенно: есть «Лист найден», «Начало загрузки в staging», «Завершение загрузки в staging»; в блоке сверки присутствует `ключВыполнения`. **Контроль на актуальном backend:** после `executeAudit(13)` и `executeAudit(14)` в новом `adt_results` появились ожидаемые маркеры **тела** row-level (`paragraph: row=`, `Row-level preview` / summary). Итог: перечисленные в п. 4.4.3 «технические» причины (пустой `insertColumns`, отсутствие строк для `rowParagraphTotal`) **не объясняют** отсутствие превью в **старых** HTML — оно согласуется с **1.8.10.4.4.4** (запись лога версией без row-level или до включения фичи). **Замечание:** поля `rowParagraphSampled` / `rowParagraphTotal` передаются в **`meta` у `STAGING_LOAD_STATS`**, в текст HTML не попадают — искать их подстрокой в `adt_results` нельзя. **Связанный root-cause для отбора строк:** см. новый блок **1.8.10.5** (перевод фильтра type=5 на поле `Признак`).
    - 1.8.10.4.4.4. **Актуальность прогона:** для подтверждения поведения текущего кода выполнить повторный прогон ревизии на **собранной сейчас** версии backend; записи `adt_results` старых прогонов могли быть сформированы до появления row-level или иной веткой логики.
    - 1.8.10.4.4.5. **Опциональные доработки прозрачности:** (а) в render-слой добавить скрытый или data-атрибут с техническим `code` / режим «отладка»; (б) расширить `localizeCode` для ключевых кодов аудита; (в) при `insertColumns.isEmpty()` — явное предупреждение в лог и корректное завершение staging-span; (г) в UI/доке зафиксировать лимит превью (`ROW_PREVIEW_LIMIT`, сейчас 12) и смысл summary.
  - ✅ 1.8.10.4.5. Последовательность инкремента соблюдена: `1.8.10.1 -> 1.8.10.2 -> 1.8.10.3 -> 1.8.10.4`.

- ✅ 1.8.10.5. Перевод отбора строк type=5 с маски номера на фильтр по полю `Признак`
  - ✅ 1.8.10.5.1. Зафиксировать текущее поведение (as-is): Java не использует VBA-подобный `Find("*???????-*")` как фильтр строк при загрузке `ra_stg_ra`; строки обходятся линейно от заголовка до конца листа и проверяются через `requiredColumns/hasBusinessData`.
  - ✅ 1.8.10.5.2. Подтвердить конфигурационный контекст: поле `rsc_row_pattern` (для type=5 задано `%_______-%`) присутствует в `ags.ra_sheet_conf`, но в текущей runtime-логике staging не участвует в отборе.
  - ✅ 1.8.10.5.3. Утвердить целевое правило отбора (to-be): включать в staging только строки с `rainSign in {"ОА", "ОА изм", "ОА прочие"}`, исключать `ОА Аренда` и прочие значения.
    - ✅ 1.8.10.5.3.1. Зафиксировано: `ОА изм` обязательно сохраняется для RC-ветки reconcile (иначе будет потеря строки изменений и деградация счётчиков `rcRowsConsidered/category*`).
    - ✅ 1.8.10.5.3.2. Зафиксирована нормализация сравнения признака: `trim` (удаление ведущих/замыкающих пробелов), case-insensitive сравнение через единый регистр (`Locale.ROOT`), null/пустое значение -> категория `UNKNOWN_SIGN` (строка не загружается в staging, учитывается в `filteredBySign`).
    - ✅ 1.8.10.5.3.3. Зафиксирован формат отражения в логе: итог фильтрации включается в `STAGING_LOAD_STATS` (`acceptedBySign`, `filteredBySign`, top-N `filteredSigns`), отдельный технический event не вводится на первом шаге.
  - ✅ 1.8.10.5.4. Реализация фильтра в `DefaultAuditStagingService` (без изменения reconcile-контрактов)
    - ✅ 1.8.10.5.4.1. Фильтрация применена до `statement.addBatch()` только для `af_type=5` (через gate по `rainSign` до bind/insert ветки).
    - ✅ 1.8.10.5.4.2. Добавлены счётчики `filteredBySign` / `acceptedBySign`; включены в `STAGING_LOAD_STATS` (сообщение + `meta`).
    - ✅ 1.8.10.5.4.3. Добавлен top-N по исключённым значениям `rainSign` (`filteredSignsTop`) для диагностики качества источника.
    - ✅ 1.8.10.5.4.4. Введена нормализация `rainSign` в коде (`trim` + `toLowerCase(Locale.ROOT)`), пустые/null учитываются как `UNKNOWN_SIGN` и попадают в `filteredBySign`.
    - ✅ 1.8.10.5.4.5. Проверка сборки: `mvn -DskipTests test-compile` для `femsq-web` — успешно.
  - ✅ 1.8.10.5.5. Выбрать способ конфигурирования whitelist
    - ⚪ 1.8.10.5.5.1. Вариант A (быстрый): hardcoded whitelist для type=5. *(не выбран; оставлен как fallback в коде при пустой конфигурации)*.
    - ✅ 1.8.10.5.5.2. Вариант B (предпочтительный): whitelist из конфигурации (`ra_sheet_conf`) без перекомпиляции — реализован.
      - ✅ Добавлено поле `rsc_sign_whitelist` в `ags.ra_sheet_conf` (Liquibase changeset).
      - ✅ Для `rsc_key=1` (type=5) задано значение `ОА;ОА изм;ОА прочие`.
      - ✅ `JdbcRaSheetConfDao`/`RaSheetConf`/`DefaultAuditStagingService` обновлены: whitelist читается из БД и применяется в runtime.
    - ✅ 1.8.10.5.5.3. Выбранный вариант и причина зафиксированы: B выбран для управляемости правила без новых сборок; hardcoded-список сохранён как безопасный fallback.
  - ✅ 1.8.10.5.6. Верификация и критерии приёмки
    - ✅ 1.8.10.5.6.1. Контрольный прогон ревизий 13/14 после внедрения фильтра.
      - ✅ Ревизия `14`: повторный прогон выполнен, `adtStatus=COMPLETED`, `execKey=104`.
      - ✅ Ревизия `13`: зависший `RUNNING` (`exec_key=103`) вручную переведён в `FAILED`; повторные прогоны `executeAudit(13)` → `COMPLETED` (`exec_key=105`, затем контрольные `106`/`107` после релиза `0.1.0.106-SNAPSHOT`).
    - ✅ 1.8.10.5.6.2. SQL-проверка staging: `rainSign='ОА Аренда'` не попадает в `ags.ra_stg_ra` для нового `exec_key`.
      - ✅ DBHub (exec_key=`104`): в `ags.ra_stg_ra` присутствуют только `ОА` (`1338`), `ОА изм` (`71`), `ОА прочие` (`311`); `ОА Аренда` = `0`.
    - ✅ 1.8.10.5.6.3. Проверка `adt_results`: есть явное отражение фильтрации по признаку (счётчики/summary), row-level preview остаётся консистентным.
      - ✅ В `adt_results` ревизии `14` присутствуют `acceptedBySign=...`, `filteredBySign=...`, `filteredSignsTop=...`, а также `paragraph: row=` и `Row-level preview`.
    - ✅ 1.8.10.5.6.4. Проверка reconcile: RA (`ОА`, `ОА прочие`) и RC (`ОА изм`) ветки сохраняют ожидаемые counters и идемпотентность.
      - ✅ По ревизии `14` ветки RA/RC активны, reconcile-сообщения (`Начало сверки`, `Type5 match/apply показатели`, diagnostics) присутствуют.
      - ✅ Ревизия `13` (2026-04-03): два подряд завершённых прогона GraphQL `executeAudit(13)` → `COMPLETED` (`exec_key=106`, затем `107`). По `ags.ra_stg_ra` для обоих `exec_key` распределение `rainSign` совпадает (`ОА` 10913 / `ОА прочие` 2150 / `ОА изм` 609), строк с признаком «ОА Аренда» нет — идемпотентность набора staging на повторном запуске подтверждена.

  - ✅ 1.8.10.5.7. Диагностика и устранение дефекта `audit RUNNING` без завершения
    - ✅ 1.8.10.5.7.1. Воспроизвести зависание для `auditId=13` с server-log трассировкой и фиксированным `exec_key`. *(зафиксировано: `exec_key=103`, причина — `Error` вне `catch(Exception)`, см. логи/анализ сессии)*
    - ✅ 1.8.10.5.7.2. Определить место зависания (staging/reconcile/async completion) и причину отсутствия перехода в `FAILED/COMPLETED`. *(невызванный `markFailed` при `NoSuchMethodError` / иных `Throwable` вне `Exception`)*
    - ✅ 1.8.10.5.7.3. Внести защиту: гарантированный перевод статуса ревизии в `FAILED` при необработанной ошибке async-ветки. *(в коде: `AuditExecutionServiceImpl` — `catch (Throwable)` и guard при загрузке ревизии; регрессия `AuditExecutionServiceImplThrowableTest`; в проде — актуальная сборка `femsq-web`, начиная с ветки с фиксом)*
    - ✅ 1.8.10.5.7.4. Повторить `1.8.10.5.6.1/1.8.10.5.6.4` и закрыть блок верификации полностью. *(выполнено: см. `1.8.10.5.6.1` и `1.8.10.5.6.4` выше; SQL по `exec_key` 105/106/107 и `adt_results` для `adt_key=13`)*
    - ✅ **Эксплуатация и наблюдаемость:** runbook `docs/development/notes/audit-log/ra-execution-operations.md` (SQL, ручной UPDATE, метрики Actuator); `AuditExecutionStalenessWatchdog` + Micrometer + `RaExecutionDao.findRunningOlderThanMinutes`; см. также коммиты после `0.1.0.106-SNAPSHOT` (watchdog, метрики, SPA/`actuator`).

### 1.8.11. Аналогия лога type=5: полный срез кнопка → «ревизия завершена» (VBA parity, вариант A)

**Решения (2026-04-05):**
- **Р1 (row-level reconcile):** вариант **A — полная аналогия с VBA** (per-row сообщения для RA/RC new/changed/excess/validation без ограничения top-N). После достижения устойчивой работоспособности можно пересмотреть ограничение объёма лога.
- **Р2 (RA/RC summary):** вариант **A** — отдельные явные сообщения «Всего строк отчётов: N» (`V-C.3.1`) и «Всего строк изменений: N» (`V-C.4.1`) как самостоятельные MSG в начале соответствующих reconcile-блоков.

#### 1.8.11.1. Синхронизация mapping (только документация, без кода)
- ✅ 1.8.11.1.1. Обновить статус `V-C.2.1.a.1.filter` в mapping: `partial` → `present`; закрыть `P3.1` в backlog
- ✅ 1.8.11.1.2. Добавить аннотацию `map/status` для узла `V-A.1.2.b.b.check.b2.0.a.1.5.1.b` → `SHEET_MISSING` в дереве V-A и в таблице связей
- ✅ 1.8.11.1.3. Проверить фактическое наличие `RECONCILE_TYPE5_START/DONE/SKIPPED/FAILED` в `AuditReconcileCoordinator`; актуализировать статусы `J-C.5.C.1` и `J-C.5.C.5` в mapping (план `1.8.10.3` ✅, но в mapping — `missing`)
  - **Факт кода:** `AuditReconcileCoordinator.run()` — `beginSpan` с `codeForType(..., \"RECONCILE_TYPE5_START\")`; `appendResult` → `endSpan` с `RECONCILE_TYPE5_DONE` или `RECONCILE_TYPE5_SKIPPED`; в `catch` → `RECONCILE_TYPE5_FAILED`.
  - **Mapping:** `J-C.5.C.1` / `J-C.5.C.5` → `status: present`, уточнены `gap` (класс `AuditReconcileCoordinator`, технический HTML vs VBA); добавлены строки в «Таблица связей узлов»; версия mapping **0.3.3**.
- ✅ 1.8.11.1.4. Зафиксировать в mapping решения Р1/Р2 (full parity A): обновить `gap`-описания `V-C.3.*/V-C.4.*` на целевые
- ✅ 1.8.11.1.5. Интегрировать данные реального прогона type=5 (06.04.2026) в `audit-log-vba-to-java-mapping.md`:
  добавлен раздел **Visual Reference** (SCR-003-A/B/C/D, SCR-002-A/B/C/D) с реальными текстами и цветами;
  35 аннотаций `screenshot`/`visual` в узлах V-A и V-C;
  сводная таблица цветовых токенов (11 ролей, light/dark HEX);
  изображения `26-0406-002.PNG`, `26-0406-003.PNG` добавлены в репозиторий.
  Версия mapping → **0.3.0**.

#### 1.8.11.2. Staging: детализация диапазона и якоря
- ✅ 1.8.11.2.1. `SHEET_FOUND`: добавить в meta координаты диапазона (`column`, `firstRow`, `lastRow`, `address`) — аналог VBA `ra_RA.Column/Row/Rows.count/Address`
  → `V-C.2.1.a`: `partial` → `present`; Event Catalog: расширить поля `SHEET_FOUND`
  - **Факт кода:** `DefaultAuditStagingService` эмитит `SHEET_FOUND` после `locateColumns`, HTML по SCR-003-C; столбец диапазона — приоритет `rainRaNum` / `rainSign` / `rainCstAgPnStr`, иначе первый required по `rcmTblColOrd`.
- ✅ 1.8.11.2.2. `ANCHOR_FOUND/ANCHOR_MISSING`: реализовать как явные события в `DefaultAuditStagingService`
  (сейчас при отсутствии якоря бросается исключение без события в лог)
  Шаблон строки `ANCHOR_FOUND` из SCR-003-B:
  «Найдена ячейка {columnName} колонка - {N}, строка - 1. Содержание: {cellContent}.» `[BLUE]`
  (одно сообщение на каждый столбец из конфигурации в порядке обхода)
  → `J-C.5.B.3`: `missing` → `present`
  - **Факт кода:** `DefaultAuditStagingService` формирует `ANCHOR_FOUND` в формате SCR-003-B:
    «Найдена ячейка {columnName} колонка - {N}, строка - {row}. Содержание: {cellContent}.»;
    `colorHint` изменён `GREEN` → `BLUE`, meta дополнены `anchorColumn`, `anchorCellContent`, `anchorRowOneBased`.

#### 1.8.11.3. Отдельные summary-сообщения RA/RC перед reconcile-блоком (V-C.3.1 / V-C.4.1)
- ✅ 1.8.11.3.1. В `AllAgentsReconcileService` добавить явный MSG «Всего строк отчётов: N» перед блоком RA
  (аналог VBA `"<P>Всего строк отчётов: <b>" & rsRaAll.RecordCount & "</b></P>"`)
  → `V-C.3.1`: `partial` → `present`
  - **Факт кода:** `eventKey: RA_ROWS_SUMMARY`, `raRowsCount` = `matchRowsConsidered`; `ReconcileContext` передаёт `AuditExecutionContext` из `AuditReconcileCoordinator`.
- ✅ 1.8.11.3.2. В `AllAgentsReconcileService` добавить явный MSG «Всего строк изменений: N» перед блоком RC
  (аналог VBA `"<P>Всего строк изменений: <b>" & rsRaAll.RecordCount & "</b></P>"`)
  → `V-C.4.1`: `partial` → `present`
  - **Факт кода:** `eventKey: RC_ROWS_SUMMARY`, `rcRowsCount` = `rcRowsConsidered` после `buildRcChangeReadModel` (dry-run и apply).

#### 1.8.11.4. Reconcile framework events (start / mode / stats / done)
- ✅ 1.8.11.4.1. Подтвердить/реализовать `RECONCILE_TYPE5_START` как явное событие в `adt_results`
  (meta: `executionKey`, `addRa`, `fileType=5`)
  → `J-C.5.C.1`: `missing` → `present`
  - **Факт кода (подтверждение — 2026-04-06):** `AuditReconcileCoordinator.run()` строка 61: `String startCode = codeForType(file, "RECONCILE_START", "RECONCILE_TYPE5_START")` → `context.beginSpan(... startCode ...)` с meta `executionKey`, `addRa`, `fileType`; ранее зафиксировано в 1.8.11.1.3.
- ✅ 1.8.11.4.2. Подтвердить/реализовать trio-model `RECONCILE_TYPE5_DONE/SKIPPED/FAILED`
  → `J-C.5.C.5`: `missing` → `present`
  - **Факт кода (подтверждение — 2026-04-06):** строки 123–124: `RECONCILE_TYPE5_DONE` (applied) / `RECONCILE_TYPE5_SKIPPED` (dry-run); строка 93: `RECONCILE_TYPE5_FAILED` в `catch(RuntimeException)`; ранее зафиксировано в 1.8.11.1.3.
- ✅ 1.8.11.4.3. `RECONCILE_TYPE5_MATCH_STATS`: вынести из diagnostics-строки в структурированный MSG
  (meta: `raNew/raChanged/raUnchanged/raInvalid/raAmbiguous`, `rcNew/rcChanged/rcUnchanged/rcInvalid/rcAmbiguous`)
  → `J-C.5.C.2`: `partial` → `present`
  - **Факт кода:** `Type5ReconcileAuditCounters.MatchStats` в `ReconcileResult`, сбор в `AllAgentsReconcileService`, отдельное событие в `AuditReconcileCoordinator.appendType5MatchStats`; fallback на строку `counters`, если `type5AuditCounters==null`.
- ✅ 1.8.11.4.4. `RECONCILE_TYPE5_APPLY_STATS`: структурированный MSG
  (meta: `raInserted/raUpdated/raUnchanged/raDeleted`, `rcInserted/rcUpdated/rcUnchanged/rcDeleted`, `sumInserted`)
  → `J-C.5.C.3`: `partial` → `present` (агрегатный слой)
  - **Факт кода:** `Type5ReconcileAuditCounters.ApplyStats`; `sumInserted` = RA `ra_summ` вставки + RC `ra_change_summ` вставки (`rcSumsInserted` + `rcSumsInsertedChanged`).
- ✅ 1.8.11.4.5. Добавить явный MSG режима reconcile: «Режим: диагностика (addRa=false)» / «Режим: применение (addRa=true)»
  (`eventKey: RECONCILE_TYPE5_MODE`)
  → `V-C.3.5/V-C.4.5`: `partial` → `present`
  - **Факт кода:** `RECONCILE_TYPE5_MODE` с meta `mode=APPLY|DIAGNOSTIC`, `addRa`; эмиссия вместе с `RA_ROWS_SUMMARY` в начале `reconcileInTransaction`.

#### 1.8.11.5. Row-level события RA (V-C.3.2.a.* / V-C.3.3.a.* / V-C.3.4) — полная аналогия с VBA
- ✅ 1.8.11.5.1. **NEW RA per row** `V-C.3.2.a.1`: MSG «создан, ключ=N, ОА=..., стройка=..., период=...»
  (`eventKey: RA_NEW_CREATED`)
  - **Факт кода:** `insertNewRaRows` → `appendRaNewCreatedAudit` (только apply, не dry-run); учёт идемпотентного INSERT (`insertedNewRow` в meta).
- ✅ 1.8.11.5.2. **NEW RA sums per row** `V-C.3.2.a.2`: MSG «суммы: total=... work=... equip=... others=...» либо «суммы отсутствуют»
  (`eventKey: RA_NEW_SUMS`)
  - **Факт кода:** `evolveRaSums` для каждой пары `NewRaRow`/`InsertedRaRow` → `appendRaNewSumsAudit` (`versionInserted` в meta).
- ✅ 1.8.11.5.3. **NEW RA validation fail per row** `V-C.3.2.a.3`: читаемая причина на строку («нет ОА», «нет периода», «нет стройки», «неподдерживаемый Признак», «ошибка создания суммы»)
  (`eventKey: RA_VALIDATION_FAIL`)
  - **Факт кода:** `buildRaReadModel`: нет канонического ключа, недопустимый признак, неоднозначный матч → `appendRaValidationFail` (dry и apply).
- ✅ 1.8.11.5.4. **CHANGED RA field mismatch per row** `V-C.3.3.a.1`: MSG «поле X: старое=A (Crimson), ожидается=B (Peru)»
  (`eventKey: RA_FIELD_MISMATCH`)
- ✅ 1.8.11.5.5. **CHANGED RA after apply per row** `V-C.3.3.a.2`: MSG «обновлено: X=B (SeaGreen)»
  (`eventKey: RA_FIELD_UPDATED`)
  > ⚠️ **Архитектурное ограничение (SCR-002-B):** `RA_FIELD_MISMATCH` + `RA_FIELD_UPDATED` — inline-пары
  > без `<P>` между полями одной записи; все изменённые поля одной RA-строки помещаются в **одну `<P>`**.
  > Новая `<P>` открывается только при переходе к следующей RA-записи.
  - **Факт кода:** после `UPDATE` в `updateChangedRaRows`: одна `<P>` с тройками Crimson/Peru/SeaGreen на поле; второе событие `RA_FIELD_UPDATED` — для учёта `eventKey` 5.5 с **пустым** `messageHtml`, текст в паре `RA_FIELD_MISMATCH`, meta `detailInEvent` / `pairedEventKey`.
- ✅ 1.8.11.5.6. **CHANGED RA sum mismatch per row** `V-C.3.3.a.3`: покомпонентный diff `ttl/work/equip/others` + пересоздание/добавление суммы
  (`eventKey: RA_SUM_MISMATCH`)
  - **Факт кода:** `evolveRaSumsWithOutcome` для `ChangedRaRow` при фактической вставке новой версии `ra_summ` → `appendRaSumMismatchAudit`.
- ✅ 1.8.11.5.7. **Excess RA list** `V-C.3.4`: построчный список кандидатов на удаление (`ra_key`, `ra_name`)
  (`eventKey: RA_EXCESS_ITEM`)
  - **Факт кода:** после `planRaDeletes` → `appendRaExcessItemsAudit` (dry и apply); план несёт `RaExcessPlanned(raKey, period, raNum)`.

#### 1.8.11.6. Row-level события RC (V-C.4.2.a.* / V-C.4.3.a.* / V-C.4.4) — полная аналогия с VBA
- ✅ 1.8.11.6.1. **NEW RC per row** `V-C.4.2.a.1`: MSG «создано изменение, ключ=N, ОА=..., период=..., №=...»
  (`eventKey: RC_NEW_CREATED`)
  - **Факт кода:** `insertNewRcChanges` → `appendRcNewCreatedAudit` (apply, не dry); meta `insertedNewRc`.
- ✅ 1.8.11.6.2. **NEW RC sums per row** `V-C.4.2.a.2`: MSG «суммы: total=... work=... equip=... others=...» либо «суммы отсутствуют»
  (`eventKey: RC_NEW_SUMS`)
  - **Факт кода:** после `evolveRcSumsWithOutcome` для NEW → `appendRcNewSumsAudit` (`versionInserted` в meta).
- ✅ 1.8.11.6.3. **NEW RC validation fail per row** `V-C.4.2.a.3`: читаемая причина на строку («нет ra_key», «нет периода», «нет №», «нет отправителя», «ошибка создания RC/суммы»)
  (`eventKey: RC_VALIDATION_FAIL`)
  - **Факт кода:** `buildRcChangeReadModel` → `appendRcValidationFail` (parse, периоды, base RA, lookup, ambiguous rac).
- ✅ 1.8.11.6.4. **CHANGED RC field mismatch per row** `V-C.4.3.a.1`: MSG «поле X: старое=A, ожидается=B»
  (`eventKey: RC_FIELD_MISMATCH`)
- ✅ 1.8.11.6.5. **CHANGED RC after apply per row** `V-C.4.3.a.2`: MSG «обновлено: X=B»
  (`eventKey: RC_FIELD_UPDATED`)
  > ⚠️ **Архитектурное ограничение (SCR-002-B, аналогия с RA):** `RC_FIELD_MISMATCH` + `RC_FIELD_UPDATED` —
  > inline-пары в одной `<P>` для всех полей одной RC-записи; новая `<P>` — только на следующую запись.
  - **Факт кода:** после `UPDATE` в `updateChangedRcChanges`: одна `<P>` в `RC_FIELD_MISMATCH`; `RC_FIELD_UPDATED` с пустым HTML и meta `detailInEvent` / `pairedEventKey` (как RA 5.5).
- ✅ 1.8.11.6.6. **CHANGED RC sum mismatch per row** `V-C.4.3.a.3`: покомпонентный diff + пересоздание суммы RC
  (`eventKey: RC_SUM_MISMATCH`)
  - **Факт кода:** при фактической вставке новой версии в `ra_change_summ` для CHANGED → `appendRcSumMismatchAudit`.
- ✅ 1.8.11.6.7. **Excess RC list** `V-C.4.4`: построчный список кандидатов на удаление (`rac_key`, `rc_name`)
  (`eventKey: RC_EXCESS_ITEM`)
  - **Факт кода:** после `planRcDeletes` → `appendRcExcessItemsAudit` (dry и apply); план несёт `RcExcessPlanned(racKey, rcPeriod, raFk, changeNum)`.

#### 1.8.11.7. Staging: per-row insert ID MSG (V-C.2.1.a.1.1.a.2.a.1)
- ✅ 1.8.11.7.1. В `DefaultAuditStagingService` для каждой вставленной строки (`af_source=true`) добавить MSG «добавлен в импорт. ID = N»
  (аналог VBA `"добавлен в импорт. ID - " & raRow`; `eventKey: STAGING_ROW_INSERTED`)
  → `V-C.2.1.a.1.1.a.2.a.1`: `missing` → `present`
  > Примечание: при больших файлах (2000+ строк) лог будет значительным — это принятое следствие решения Р1 (varian A). Реализовать в рамках того же type=5 scope.
  - **Факт кода:** `STAGING_ROW_INSERTED` сразу после `executeUpdate` + `readGeneratedRainKey`, до `ROW_PARAGRAPH_PREVIEW`; при отсутствии ключа — `WARN`/`ORANGE`. Пакетный режим без по-строчных ключей — событие не эмитится.

#### 1.8.11.9. Коррекция уже реализованных записей лога (present-узлы с gap по скриншотам)

> Работа по Java-коду: привести цвет (`colorHint`), акцент (`emphasis`) и текстовый шаблон
> already-`present`-узлов в соответствие с реальным VBA-логом из SCR-*.
> Источник-приоритет: реальный текст/цвет из скриншотов (§ Visual Reference, v0.3.0).

- ✅ 1.8.11.9.1. **`AUDIT_START`** `V-A.1.msg.start`:
  добавить/выровнять `colorHint=RED`, `emphasis=BOLD` для имени ревизии
  (SCR-003-A: «Начало проведения ревизии ***2026-й год***.» — имя ревизии красным жирным)
- [факт] `AuditExecutionServiceImpl`: `eventKey=AUDIT_START`, `withPresentationMeta(..., "START", "RED", "BOLD")`
- ✅ 1.8.11.9.2. **`AUDIT_END`** `V-A.1.msg.end`:
  выровнять текст: «В {finishTime} - ***ревизия завершена***. С {startTime} в течении {min} мин. {sec} сек., (всего {total} сек.).»;
  `colorHint=BLUE_BOLD`
  (SCR-002-D)
- [факт] `AuditExecutionServiceImpl.appendAuditEnd`: кириллическое «С», длительность «N мин. M сек.», хвост «(всего K сек.)»; meta `durationTotalSec`; для успеха цвет заголовка `#0055AA`, `BLUE`/`BOLD`.
- ✅ 1.8.11.9.3. **`DIR_LOOKUP_FOUND`** `V-A.1.2.b.b.msg`:
  добавить `colorHint=GREEN`, `emphasis=BOLD` для имени директории
  (SCR-003-A: «Имя директории ***...*** для ревизии обнаружено»)
- [факт] `AuditExecutionServiceImpl`: `eventKey=DIR_LOOKUP_FOUND`, `withPresentationMeta(..., "INFO", "GREEN", "BOLD")`
- ✅ 1.8.11.9.4. **`DIR_FS_EXISTS` / `DIR_FS_MISSING`** `V-A.1.2.b.b.check.b/a`:
  добавить `colorHint=GREEN`/`RED`, `emphasis=BOLD` для имени директории
  (SCR-003-A: «Директория с именем ***...*** в файловой системе обнаружена/не обнаружена»)
- [факт] `AuditExecutionServiceImpl.verifyDirectoryExistsInFileSystem`: HTML как в VBA (имя директории зелёное/красное жирное); meta `DIR_FS_EXISTS` → `GREEN`/`BOLD`, `DIR_FS_MISSING` без изменений (`RED`/`BOLD`).
- ✅ 1.8.11.9.5. **`WORKBOOK_OPEN` / `WORKBOOK_CLOSE`** `J-B.1.1 / J-B.1.2`:
  добавить `colorHint=BLUE_BOLD`; текст «***Приложение Excel открыто/закрыто***» жирным синим
  (SCR-003-A, SCR-002-D)
- [факт] `DefaultAuditStagingService`: `WORKBOOK_OPEN` → `withPresentationMeta(..., "START", "BLUE", "BOLD")`, `WORKBOOK_CLOSE` → `withPresentationMeta(..., "END", "BLUE", "BOLD")`
- ✅ 1.8.11.9.6. **`FILE_FS_FOUND` / `FILE_FS_MISSING`** `V-A.1.2.b.b.check.b2.0.a.0.a/b`:
  уточнить шаблон текста по SCR-003-A:
  «{datetime} - Файл с именем "..." в файловой системе обнаружен» (имя файла в `<b>`, meta `GREEN`/`NORMAL` для FOUND)
  Аналогично MISSING: префикс с датой/временем, имя в `<b><font color=red>`, meta `RED`/`BOLD`
- [факт] `AuditExecutionServiceImpl`: `formatInstantHuman(Instant.now())` + путь в HTML как выше.
- ✅ 1.8.11.9.7. **`ROW_PARAGRAPH_PREVIEW`** (staging per-row, `V-C.2.1.a.1.1.a.1`):
  выровнять цветовую схему по SCR-003-D:
  — тип `*{sign}*` → `colorHint=TEAL_BOLD`
  — «Отчёт внесён в промеж. тбл. ID - » → `colorHint=DARK_GREEN`
  — `{insertedId}` → `colorHint=ORANGE`, `emphasis=BOLD`
- [факт] `DefaultAuditStagingService`: для type=5 убран лимит `ROW_PREVIEW_LIMIT`; строка лога в HTML с цветами `#007070` / `#006400` / `#D06000`; после каждого успешного `INSERT` — `RETURN_GENERATED_KEYS` → `rain_key` в тексте; meta `ROW_PARAGRAPH_PREVIEW` → `TEAL`/`NORMAL` (детализация в HTML). **Производительность:** при больших файлах — по одному `executeUpdate` на принятую строку (осознанный trade-off для полноты лога, решение Р1).

#### 1.8.11.8. Acceptance: контрольный прогон и финальная синхронизация mapping
- ✅ 1.8.11.8.1. Контрольный прогон type=5 (один файл, `af_source=true`, `addRa=false`) → `COMPLETED`
  - **Процедура:** выставить `ags.ra_a.adt_AddRA=0` для тестовой ревизии; выполнить ревизию с type=5 файлом; в `ra_execution.exec_status` — `COMPLETED`.
- ✅ 1.8.11.8.2. Верификация `adt_results` (dry-run): видны все фазы от `AUDIT_START` до `AUDIT_END`
  — `RECONCILE_TYPE5_START`, режим **диагностика** (`RECONCILE_TYPE5_MODE`), summary RA/RC (`RA_ROWS_SUMMARY` / `RC_ROWS_SUMMARY`), row-level RA/RC (при наличии данных: validation / excess / …), `RECONCILE_TYPE5_MATCH_STATS`, `RECONCILE_TYPE5_APPLY_STATS`, завершение reconcile: **`RECONCILE_TYPE5_SKIPPED`** (dry-run, `applied=false`; не `RECONCILE_TYPE5_DONE`).
  - **Автоматизация:** opt-in IT `Type5AcceptanceAdtResultsIntegrationIT` (проверка устойчивых русских фрагментов в HTML `adt_results`), флаг `-Dfemsq.integration.type5Acceptance=true`, опция `-Dfemsq.integration.auditId=…`.
- ✅ 1.8.11.8.3. Прогон с `addRa=true` (apply, snapshot/rollback): RA created/updated, RC created/updated явно в логе
  - **Процедура:** как в `RcChangeApplyIntegrationIT` / второй тест acceptance IT: `adt_AddRA=1`, по завершении — откат доменных вставок по baseline-ключам; в `adt_results` — режим **применение**, `dryRun=false`, структурированные `Type5 apply`, плюс row-level тексты (`Создана…`, суммы, mismatch и т.д. при наличии сценария).
- ✅ 1.8.11.8.4. Обновить все `map/status/gap` в `audit-log-vba-to-java-mapping.md` по факту реализации
  - **Факт:** синхронизированы ветки `V-C.2.1.a.1.*` (gap про reconcile), `V-C.3.*`/`V-C.4.*`, сводная таблица, каталог событий, backlog; версия mapping **0.4.0**.
- ✅ 1.8.11.8.5. Закрыть `P2` и `P3` в backlog mapping если достигнуто full parity по type=5
  - **Факт:** для **целевого scope type=5 (решение A)** parity по reconcile row-level + staging достигнута; `P2` сужен до «остальные типы файлов»; `P3`/`P4` обновлены (см. `Implementation Backlog` в mapping). Полный inventory всех `af_type` — не входит в критерий этого шага.
- ✅ 1.8.11.8.6. Реальный acceptance IT-прогон на доступной БД + живом backend (финальная фиксация)
  - **Факт прогона (2026-04-06):** `mvn -pl femsq-backend/femsq-web test -Dtest=Type5AcceptanceAdtResultsIntegrationIT -Dfemsq.integration.type5Acceptance=true -DfailIfNoTests=false`
  - **Результат:** `BUILD SUCCESS`, `Tests run: 2, Failures: 0, Errors: 0, Skipped: 0`.
  - **Проверка артефактов БД после apply-run (`addRa=true`):** доменные хвосты очищены `finally`-блоком теста (`ags.ra*` / `ags.ra_change*`), `adt_AddRA` восстановлен; ожидаемо остаются технические следы `ags.ra_execution` и `ags.ra_reconcile_marker`.
  - **Важно для повторяемости:** в HTML `adt_results` после локализации `AuditExecutionContext.localizeMessageHtml` используется `сухойПрогон=true/false` (а не `dryRun=true/false`), поэтому acceptance-проверки должны искать локализованную форму.
- ✅ 1.8.11.8.7. Политика очистки `ags.ra_reconcile_marker` для тестового стенда (Вариант B: TTL + retention)
  - **Решение:** для TEST-стенда принят регламент управляемой очистки marker-таблицы:
    - удалять только маркеры старше TTL (по `created_at`),
    - дополнительно сохранять минимум N последних `exec_key` на каждую ревизию (`exec_adt_key`),
    - никогда не удалять маркеры `RUNNING`.
  - **SQL-плейбук:** `docs/sql-scripts/type5-reconcile-marker-cleanup-policy.sql`
    (режимы dry-run/DELETE, safety guards, параметры `@ttlDays`, `@keepLatestPerAudit`, `@applyDelete`).
  - **Операционный регламент (TEST):** запуск 1 раз в неделю, рекомендуемо `@ttlDays=14..30`, `@keepLatestPerAudit>=20`.
- ✅ 1.8.11.8.8. Стабилизирован acceptance IT для CI/ручных прогонов (runbook + post-run smoke-check)
  - **Runbook:** добавлен раздел в `code/scripts/README-TESTING.md`:
    - предусловия (backend/GraphQL/БД),
    - каноническая команда запуска `Type5AcceptanceAdtResultsIntegrationIT`,
    - ожидаемый итог `BUILD SUCCESS` + `Tests run: 2`.
  - **Нюанс локализации зафиксирован:** для `adt_results` проверяется `сухойПрогон=true/false` (не `dryRun=true/false`).
  - **Post-run SQL smoke-check:** добавлен `docs/sql-scripts/type5-acceptance-postrun-smoke-check.sql`
    (baseline snapshot, сравнение delta по доменным max-ключам, статус rollback, контроль ожидаемых технических артефактов `ra_execution`/`ra_reconcile_marker`).
- ✅ 1.8.11.8.9. Smoke-check SQL чеклист сделан обязательным после каждого apply IT
  - **Операционное правило:** для каждого acceptance/apply-прогона (`addRa=true`) post-run smoke-check выполняется обязательно.
  - **Критерий PASS:** `rollback_status=OK_ROLLBACK`; критерии FAIL: `CHECK_REQUIRED` или `BASELINE_NOT_SET`.
  - **SQL приведён к рабочему ритуалу “до/после”:** `docs/sql-scripts/type5-acceptance-postrun-smoke-check.sql`
    (явный baseline-capture + post-run блок с ручной подстановкой baseline значений).
  - **Фиксация результата:** введён шаблон отчёта
    `docs/development/notes/templates/type5-acceptance-smoke-check-report-template.md`.
  - **Runbook обновлён:** `code/scripts/README-TESTING.md` — обязательность шага и критерии PASS/FAIL.

---

## Фаза 2: Type 2 (`ra_stg_cn_prdoc` → домен)
**Выполнить reconcile по VBA `RAAudit_cn_PrDoc`.**

### 2.1. Match-логика и SQL-адаптация
- [ ] 2.1.1. Зафиксировать канонический ключ сопоставления для `ra_stg_cn_prdoc` и целевых доменных таблиц
- [ ] 2.1.2. Перенести SQL-логику Access в SQL Server-совместимые запросы (lookup + сравнение)
- [ ] 2.1.3. Ввести категории результата матчинга (`NEW / CHANGED / UNCHANGED / AMBIGUOUS / INVALID`)
- [ ] 2.1.4. Подготовить DBHub-check SQL для категорий сопоставления

### 2.2. Upsert/Delete по результатам match
- [ ] 2.2.1. Реализовать insert для новых записей
- [ ] 2.2.2. Реализовать update для изменённых записей
- [ ] 2.2.3. Реализовать delete/close-ветку для записей, отсутствующих в источнике (если подтверждено VBA)
- [ ] 2.2.4. Добавить dry-run (`addRa=false`) с полными счётчиками без apply

### 2.3. Журналы изменений и идемпотентность
- [ ] 2.3.1. Реализовать запись в соответствующие `*_change` (если предусмотрено моделью reconcile)
- [ ] 2.3.2. Защититься от дублей (ключи/индексы/условия upsert)
- [ ] 2.3.3. Проверить повторный запуск на одном `exec_key` и на новой сессии той же ревизии

### 2.4. Минимальный вертикальный срез Type 2
- [ ] 2.4.1. Инкремент A: `match` → SQL-проверка через DBHub
- [ ] 2.4.2. Инкремент B: `upsert` → SQL-проверка через DBHub
- [ ] 2.4.3. Инкремент C: `*_change + idempotency` → финальная сверка счётчиков/журнала

---

## Фаза 3: Type 3 (`ra_stg_ralp` + `ra_stg_ralp_sm` → домен)
**Выполнить reconcile по VBA `RAAudit_ralp` (оба листа).**

### 3.1. Match-логика на двух staging-источниках
- [ ] 3.1.1. Зафиксировать канонические ключи сопоставления для `ra_stg_ralp` и `ra_stg_ralp_sm`
- [ ] 3.1.2. Реализовать объединённый read-model match с учётом обоих листов
- [ ] 3.1.3. Ввести категории результата (`NEW / CHANGED / UNCHANGED / AMBIGUOUS / INVALID`) для каждой ветки
- [ ] 3.1.4. Подготовить DBHub-check SQL по обеим staging-таблицам

### 3.2. Порядок применения изменений
- [ ] 3.2.1. Явно зафиксировать порядок `ra_stg_ralp` → `ra_stg_ralp_sm` (или обратный) и обоснование
- [ ] 3.2.2. Обеспечить детерминированность результата при повторных запусках
- [ ] 3.2.3. Зафиксировать поведение при конфликте данных между листами

### 3.3. Upsert/Delete и журналы изменений
- [ ] 3.3.1. Реализовать insert/update по основной ветке reconcile
- [ ] 3.3.2. Реализовать delete/close-ветку для записей, отсутствующих в источнике (если подтверждено VBA)
- [ ] 3.3.3. Реализовать запись изменений в `*_change` (если предусмотрено моделью reconcile)
- [ ] 3.3.4. Добавить dry-run (`addRa=false`) и полные счётчики

### 3.4. Идемпотентность и вертикальный срез Type 3
- [ ] 3.4.1. Проверить повторный запуск на одном `exec_key`
- [ ] 3.4.2. Проверить повторный запуск по той же ревизии с новым `exec_key`
- [ ] 3.4.3. Инкремент A: `match (оба листа)` → DBHub-check
- [ ] 3.4.4. Инкремент B: `upsert + *_change + idempotency` → финальная сверка счётчиков/журнала

---

## Фаза 4: Type 6 (`ra_stg_agfee` → домен)
**Выполнить reconcile по VBA `RAAudit_AgFee_Month` + `ra_aAgFee23_06.Audit`.**

### 4.1. Match-логика и guard
- [ ] 4.1.1. Зафиксировать канонический ключ сопоставления `ra_stg_agfee` с целевым доменом
- [ ] 4.1.2. Реализовать match/read-model с категориями результата (`NEW / CHANGED / UNCHANGED / INVALID`)
- [ ] 4.1.3. Сохранить и проверить guard по `auditType` (согласованный на Stage 2)
- [ ] 4.1.4. Подготовить DBHub-check SQL по match-результатам

### 4.2. Upsert/Delete и журналы изменений
- [ ] 4.2.1. Реализовать insert/update по правилам VBA для Type 6
- [ ] 4.2.2. Реализовать delete/close-ветку (если подтверждено VBA)
- [ ] 4.2.3. Реализовать запись изменений в `*_change` (если предусмотрено моделью reconcile)
- [ ] 4.2.4. Добавить dry-run (`addRa=false`) и полные счётчики

### 4.3. Идемпотентность и вертикальный срез Type 6
- [ ] 4.3.1. Защититься от дублей на уровне SQL (ключи/индексы/условия upsert)
- [ ] 4.3.2. Проверить повторный запуск на одном `exec_key`
- [ ] 4.3.3. Проверить повторный запуск по той же ревизии с новым `exec_key`
- [ ] 4.3.4. Инкремент A: `match` → DBHub-check
- [ ] 4.3.5. Инкремент B: `upsert + *_change + idempotency` → финальная сверка счётчиков/журнала

---

## Фаза 5: cross-type (идемпотентность / SQL artifacts / Liquibase)

### 5.1. Единые правила идемпотентности для `af_type ∈ {2,3,5,6}`
- [ ] 5.1.1. Зафиксировать общий контракт повторного запуска (`same exec_key` / `new exec_key same audit`)
- [ ] 5.1.2. Согласовать единый набор счётчиков reconcile (`inserted/updated/deleted/unchanged/errors`)
- [ ] 5.1.3. Определить общую стратегию защиты от дублей (unique keys, merge-условия, marker-таблица)
- [ ] 5.1.4. Добавить инварианты на транзакционность/rollback для всех type-specific reconcile

### 5.2. SQL-артефакты reconcile
- [ ] 5.2.1. Выделить и унифицировать SQL-шаблоны: `match`, `upsert`, `delete-missing`, `changes`
- [ ] 5.2.2. Зафиксировать общие naming conventions и параметры фильтрации по `exec_key`
- [ ] 5.2.3. Подготовить набор DBHub-check SQL для каждого типа в едином формате
- [ ] 5.2.4. Согласовать минимальные performance-ограничения (batch size, индексы, предикаты)

### 5.3. Liquibase / схема / служебные объекты
- [ ] 5.3.1. Проверить потребность в новых индексах/уникальных ограничениях для идемпотентности
- [ ] 5.3.2. Проверить потребность в новых служебных таблицах (например, marker reconcile-run)
- [ ] 5.3.3. Оформить изменения Liquibase changeset-ами с безопасным rollout-порядком
- [ ] 5.3.4. Подготовить SQL-план отката/проверки после применения миграций

---

## Фаза 6: Верификация и финальная ручная проверка

### 6.1. Чек-листы верификации по типам
- [ ] 6.1.1. Подготовить отдельный checklist для type 2
- [ ] 6.1.2. Подготовить отдельный checklist для type 3
- [ ] 6.1.3. Подготовить отдельный checklist для type 5
- [ ] 6.1.4. Подготовить отдельный checklist для type 6

### 6.2. Сквозная сверка данных и счётчиков
- [ ] 6.2.1. Сверять счётчики: `staging` → доменные таблицы → `*_change` → journal выполнения
- [ ] 6.2.2. Подтвердить, что staging-таблицы заполнены по правильному `*_exec_key`
- [ ] 6.2.3. Подтвердить поведение `af_source=false` (staging не загружается, лог корректен)
- [ ] 6.2.4. Подтвердить поведение `af_source=true` и `addRa=true` (домен получает новые/обновлённые данные)

### 6.3. Финальный прогон приложения
- [ ] 6.3.1. Выполнить финальный прогон `JAR` для `af_type=2,3,5,6`
- [ ] 6.3.2. Проверить UI/логи в ручном сценарии длительного выполнения
- [ ] 6.3.3. Зафиксировать наблюдения по ошибкам/предупреждениям и фактические `exec_key`

### 6.4. DBHub-пакет итоговой проверки
- [ ] 6.4.1. Подготовить единый SQL-пакет проверки для всех типов
- [ ] 6.4.2. Выполнить SQL-пакет по результатам финального прогона
- [ ] 6.4.3. Зафиксировать итоговый протокол (expected vs actual, отклонения, вывод)

---

## Параллелизм
- Type 5 можно закрывать независимо после готовности Stage 1–2 для type 5.
- Type 2/3/6 можно выполнять параллельно между собой, фиксируя порядок применения изменений только внутри своих композиций (например, Type 3 — два листа).

