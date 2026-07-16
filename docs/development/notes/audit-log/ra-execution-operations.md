# Эксплуатация: выполнение ревизий (`ags.ra_execution`)

**Назначение:** разовая диагностика «зависших» запусков и ручное снятие блокировки перед повторным `executeAudit`.

## Blocker thin JAR (G8)

**Факт (2026-07-16, `0.1.0.135`):**
- fat JAR публикует `POST /graphql` и позволяет запускать `executeAudit`;
- thin JAR поднимает REST/health и подключение к БД, но `POST /graphql` возвращает `404`;
- в thin-логе отсутствуют строки `Loaded ... GraphQL schema` и `GraphQL endpoint HTTP POST /graphql`;
- удаление `BOOT-INF/classpath.idx`/`layers.idx` и запуск через `PropertiesLauncher` ситуацию не меняют: `/graphql` остаётся `404`, а `REST`/health доступны;
- текущая рабочая гипотеза подтвердилась: в thin-режиме ломалось автообнаружение schema resources;
- локальный фикс через явную регистрацию `graphql/*.graphqls` в `GraphQlConfig` восстановил `Loaded 2 resource(s) in the GraphQL schema`, публикацию `POST /graphql` и ответ `200` на thin smoke (`:8083`).

**Следствие (обновлено 2026-07-16):** G8 и soft-deploy rehearsal закрыты на thin JAR **0.1.0.136** (`/home/alex/femsq-test/test-26-0716`): `POST /graphql` = 200; CLI dry-run type=5 **exec 1193**, type=3 **exec 1194**; UI AuditsView sign-off. Для RALP нужен `af_source=1` на файле type=3. Далее — prod (§9.5.1+, задача 0048).

## Разовая проверка БД

Записи в статусе `RUNNING` и возраст в минутах:

```sql
SELECT e.exec_key,
       e.exec_adt_key,
       e.exec_status,
       e.exec_started,
       DATEDIFF(MINUTE, e.exec_started, SYSUTCDATETIME()) AS running_minutes
FROM ags.ra_execution e
WHERE e.exec_status = N'RUNNING'
ORDER BY e.exec_started ASC;
```

Если строка существует долго при остановленном/упавшем приложении — это кандидат на ручное завершение.

## Ручное завершение зависшего `RUNNING`

1. Убедиться, что процесс ревизии на сервере **не выполняется** (нет активного async-прогона).
2. Выполнить обновление **конкретной** строки по `exec_key` (подставить значения из запроса выше):

```sql
UPDATE ags.ra_execution
SET exec_status = N'FAILED',
    exec_finished = SYSUTCDATETIME(),
    exec_error = N'Ручное завершение зависшего RUNNING (оператор).'
WHERE exec_key = ? /* и при необходимости */ AND exec_adt_key = ?
  AND exec_status = N'RUNNING';
```

3. После деплоя версии с `catch (Throwable)` в `AuditExecutionServiceImpl` повторный сбой async должен сам переводить запись в `FAILED`. Ручной шаг остаётся для старых сборок и аварийных ситуаций.

4. Запустить ревизию снова: GraphQL `mutation { executeAudit(id: …) { started alreadyRunning message } }`. Пока последняя запись по ревизии в `RUNNING`, мутация вернёт «уже выполняется».

## UI: параметры запуска перед «Выполнить ревизию»

`executeAudit` на backend читает из БД `ags.ra_a.adt_AddRA` и `adt_staging_log_level`, а не значения чекбокса/селекта в форме.

**Поведение (с 2026-07-16):** при нажатии «Выполнить ревизию» frontend (`AuditsView.vue`) автоматически вызывает `updateAudit`, если в форме изменились **«Обновляем базу данных?»** или **«Детализация лога Stage 1»** без «Сохранить». Остальные поля ревизии по-прежнему требуют явного сохранения.

## Наблюдаемость в приложении

### Терминал: `watch-audit-progress.sh`

Во время длительного `executeAudit` (особенно type=5 по SMB) в **отдельном терминале**:

```bash
chmod +x code/scripts/watch-audit-progress.sh
./code/scripts/watch-audit-progress.sh 14 15
```

Каждые 15 с выводит:
- `adtStatus` из GraphQL (in-memory)
- `exec_key`, `status`, минуты в `RUNNING` из `ags.ra_execution`
- последний номер строки Excel из хвоста `adt_results`
- счётчики `ra_stg_ra` / `ra_stg_ralp` для текущего `exec_key`

Если `excel_row` растёт — процесс **идёт**; если `running_min` растёт без изменения строки >10 мин — возможное зависание (см. watchdog ниже).

### Лог приложения

При Stage 1 с построчным HTML-логом (type=5) каждые **50 строк** в лог пишется `[AuditStaging] progress auditId=… excelRow=… inserted=…` (сборка после 2026-07-08).

## Производительность Stage 1 (`StagingLogLevel`)

**Контекст (2026-07-09):** прогон `exec_key=1136` (type=5, март, dry-run, ~1720 строк) занял **~117 мин**. Основная причина — режим `VERBOSE`: одиночный `INSERT` + `RETURN_GENERATED_KEYS` на каждую строку и частый `saveProgress` с растущим HTML в `adt_results`. Чтение Excel по SMB — менее 1% времени.

### Уровни детализации лога

Поле ревизии `adt_staging_log_level` (или `NULL` → `audit.staging.default-log-level` в `application.yml`, по умолчанию `SUMMARY`):

| Уровень | `adt_results` | INSERT | Когда использовать |
|---------|---------------|--------|-------------------|
| `VERBOSE` | Каждая строка Excel (как в VBA) | по одной строке | Приёмка, сравнение с VBA |
| `SUMMARY` | Прогресс раз в 100 строк + проблемные строки (пустые обязательные поля, ошибки формата ячеек) | batch (200) | Обычная эксплуатация |
| `MINIMAL` | Только итоги листа | batch | CI, быстрые smoke |

Ожидаемое время Stage 1 type=5 при `SUMMARY`: **~3–5 мин** вместо ~106 мин.

**Замер (2026-07-09, exec_key=1139, март 2026, dry-run):** Stage 1 type=5 — **~70 с** (1720 строк); полный прогон с reconcile — **~3 мин** (vs ~117 мин при VERBOSE, exec_key=1136).

### Настройка

| Источник | Параметр |
|----------|----------|
| UI | Форма ревизии → «Детализация лога Stage 1» |
| БД | `ags.ra_a.adt_staging_log_level` (`VERBOSE` / `SUMMARY` / `MINIMAL`, `NULL` = default) |
| `application.yml` | `audit.staging.default-log-level: SUMMARY` |

Для сравнения с VBA временно выставить `VERBOSE` на конкретной ревизии; для smoke и эксплуатации — `SUMMARY`.

### Построчный аудит reconcile (apply)

При `SUMMARY` / `MINIMAL` построчные записи apply reconcile (создание/обновление RA/RC, эволюция сумм) **не пишутся** в `adt_results` — только агрегаты (`RECONCILE_TYPE5_*`). Per-row аудит apply включается только при `adt_staging_log_level = VERBOSE` (`StagingLogLevel.emitReconcileRowAudit()`).

### Сохранение HTML-лога (`saveProgress`, задача 0046)

Интервал flush в БД при накоплении событий (`onEntryAppended`): **VERBOSE 1 с**, **SUMMARY 10 с**, **MINIMAL 30 с** (`StagingLogLevel.progressFlushIntervalMs()`). `buildHtmlLog()` кэшируется до следующей записи; flush пропускается, если число событий не изменилось.

В конце ревизии в лог пишется `AUDIT_LOG_PERSIST_STATS` (и строка `[AuditProgress]` в server log): `flushes`, `skippedThrottled`, `buildHtmlMs`, `dbUpdateMs`, `lastHtmlChars`.

**Замер (2026-07-09, exec 1145, март SUMMARY, 0.1.0.119):** dry-run **155 с** (vs exec 1144 **180 с**); `flushes=12`, `dbUpdateMs=5402`, HTML ≈463 КБ.

## RALP (`af_type=3`): база dev и откат

- **Эталон домена:** март `2026_03` → **420** valid (`ralpRa`/`ralpRaAu`); июль `2026-07` → **1248** valid (+838 документов). Trim: `trim-ralp-domain-to-march-baseline.sql` (staging exec **1152**).
- **Smoke март vs июль (2026-07-09):** exec **1152** → **1153** (`unchanged=1248`) → **1154** (apply без изменений) → откат → **1155**; скрипты в `code/scripts/`.
- Подробнее: `docs/development/remote-development-nb-win.md` → «База RALP».

## Производительность reconcile type=5 (задача 0044)

**Контекст:** после 0043 reconcile — ~8% dry-run SUMMARY. Оптимизация `AllAgentsReconcileService`: JDBC batch (`APPLY_BATCH_SIZE=200`) для UPDATE/INSERT, bulk-загрузка latest sums (`BULK_IN_CHUNK=500`) вместо per-row SELECT.

**Замер dry-run март SMB (adt_key=14):** exec_key **1144** (0.1.0.118) — **180 с**, `ra_stg_ra=1720` (vs exec 1140 ~183 с на 0.1.0.117). Полный выигрыш по времени dry-run небольшой; основная польза — меньше round-trips при **apply** (`adt_AddRA=1`) и отсутствие лишнего построчного аудита reconcile в SUMMARY.

## Читаемость лога в UI (`adt_results`, задача 0049)

**Контекст (2026-07-10):** функциональный UAT RALP (type=3, exec **1162–1166**) пройден, но оператор **не воспринимает** HTML-лог в `AuditsView` — blocker для эксплуатации. Задача **0049**, chat-plan §9.3.3–9.3.4.

### Темы (глобальные, задача 0050)

С **2026-07-13** темы лога **не переключаются отдельно** — наследуют глобальную тему приложения.

| Тема | ID | По умолчанию |
|------|-----|--------------|
| **Kimbie Dark** | `kimbie-dark` | да |
| **Светлая (Visual Studio)** | `vs-light` | |

- Переключатель: **иконка в TopBar** (не в `AuditsView`).
- Хранение: `localStorage` **`femsq.theme`** (миграция с устаревшего `femsq.auditLogTheme`).
- Акцент Kimbie: **тёплый** `#d19a66`.
- Подробности: `docs/development/frontend-themes.md`, chat-plan §9.3.5.

Стили лога — `code/femsq-frontend-q/src/styles/audit-log.css` на CSS-переменных `--femsq-*`.

### Плотность и оформление

- Межстрочный интервал уменьшается примерно **в 3 раза** (`padding`, `line-height`).
- Badge начала фазы (`*_START`): **`+`** вместо `START`.

### Сообщения о пропуске строк Excel (SUMMARY)

| Причина | Текст в логе (целевой формат) |
|---------|-------------------------------|
| Пустые обязательные поля | `пропущено — пусто обязательное поле: col1 («Заголовок1»), col2 («Заголовок2») и ещё N` |
| Нет бизнес-данных в строке | `пропущено — в строке нет данных` |
| Ошибка формата обязательного поля | детали из `STAGING_ROW_ISSUE` (колонка, заголовок, сырое значение) |

Показываются **первые 3** обязательных поля; при большем числе — суффикс **«и ещё N»**.

### Type5 reconcile в логе

Строки match/apply (`RECONCILE_TYPE5_MATCH_STATS`, `RECONCILE_TYPE5_APPLY_STATS`) — **на русском**: отчёты / изменения; категории: новые, изменённые, без изменений, некорректные, неоднозначные.

### Приёмка

Оператор подтверждает читаемость на существующих exec **1162–1166** (просмотр без нового apply) или на новом dry-run после деплоя **0.1.0.123+**.

## Трассировка Excel-строки и аномалии сверки (задача 0051)

**Статус:** закрыта 2026-07-15 (formal **U10** / **G3** / **P5**; совместно с **0052**/**0053**).

**Контекст (2026-07-14):** в details сверки RALP видно `некорректных = 4`, но без перечня строк и причин — blocker **U10**. Решение: хранить номер строки исходного Excel в staging и писать построчные WARN в духе Access (`RAAudit_ralp`); итоговая детализация — также в дереве сверки (§9.3.8).

### Колонки в staging

| Таблица | Колонка | Назначение | Состояние до 0051 |
|--------|---------|------------|-------------------|
| `ags.ra_stg_ra` | `rainRow` | Excel-строка 1-based (как в Access `ra_ImpNew`) | колонка есть; **Stage 1 заполняет** (§9.3.6.2) |
| `ags.ra_stg_ralp` | `ralprtRow` | то же для type=3 | **DDL ✅**; **Stage 1 заполняет** (§9.3.6.2) |
| `ags.ra_stg_ralp_sm` | `ralprsRow` | сводный лист «учет_аренды» | **DDL ✅**; **Stage 1 заполняет** (§9.3.6.2) |

Заполнение — **синтетическая** колонка при INSERT Stage 1 (рядом с `*_exec_key`), не через `ra_col_map` / заголовок Excel. Реализация: `StagingExcelRowColumns` + `DefaultAuditStagingService` (§9.3.6.2 ✅).

### Построчные сообщения (SUMMARY / VERBOSE)

После Stage 2 и/или в начале сверки для каждой аномалии:

```
⚠ Excel-строка N, лист «…»: отчёт «…» от …
  — <причина в духе Access>
  → строка исключена из сверки (некорректная) | рассмотрение пропущено | …
```

Обязательные семейства причин: стройка не найдена / отсутствует в БД; дата отсутствует; отправитель/филиал отсутствует или несколько; пустое «Поступило»; orphan при apply; type=5 — invalid/ambiguous/missing lookup **по строкам**, не только топ-агрегат.

Агрегат `некорректных = N` должен совпадать с числом детальных WARN по этой категории.

### Stage 2 type=3 (задача 0051, §9.3.6.3)

После FK-resolution в лог пишется итог:

`Этап 2 (RALP) выполнен: … разрешён = …; промежуточная таблица = N, неразрешённых строк = M (стройка NULL = …, отправитель NULL = …, дата NULL = …).`

В режимах `SUMMARY`/`VERBOSE` — по каждой неразрешённой строке код `RALP_STAGE2_FK_UNRESOLVED` (A1–A4, стиль Access): Excel-строка (`ralprtRow`), лист, № отчёта, причины. `MINIMAL` — только агрегат.

### Сверка type=3 (задача 0051, §9.3.6.4)

| Код | Когда | Содержание |
|-----|-------|------------|
| `RALP_RECONCILE_INVALID_REF` | invalid &gt; 0 | INFO: число некорректных + отсылка к WARN Этапа 2 (без дублирования причин) |
| `RALP_RECONCILE_EMPTY_ARRIVED` | пусто «Поступило» | WARN по строке с `ralprtRow` (A5) |
| `RALP_RECONCILE_ORPHAN_RA` | orphan RA (apply или dry-run-список) | WARN «Лишние отчёты в БД: …» (A6) |
| `RALP_RECONCILE_AU_DEMOTE` | demote sibling AU | INFO по строке **только VERBOSE** (A7); в SUMMARY — агрегаты в details |

В details сверки добавлено: `без рассмотрения (пустое Поступило) = N`.

### Сверка type=5 (задача 0051 / §9.3.8)

Отказы валидации RA/RC: детализация в **дереве сверки**. Плоские `RA_VALIDATION_FAIL` / `RC_VALIDATION_FAIL` — **только VERBOSE** (в SUMMARY дублировали дерево).

| Код | Когда |
|-----|--------|
| Дерево §9.3.8 | SUMMARY и VERBOSE |
| `RA_VALIDATION_FAIL` / `RC_VALIDATION_FAIL` | только VERBOSE |

Номер строки — из `ags.ra_stg_ra.rainRow`. Агрегат `RECONCILE_TYPE5_DIAGNOSTICS` сохраняется.

Реализация: `Type5ReconcileErrorGrouper`; плоские WARN — `Type5RowAnomalyFormatter` + `emitValidationAnomalies` → VERBOSE.

### Smoke §9.3.6.6 (2026-07-14, JAR **0.1.0.126**)

| Прогон | exec_key | Результат |
|--------|----------|-----------|
| type=3 март dry-run SUMMARY | **1169** | `ralprtRow` 424/424; 4 FK-WARN (Excel 91/151/243/283); `некорректных = 4` |
| type=5 март dry-run SUMMARY | **1170** | `rainRow` 1720/1720; `некорректные=71`; построчные WARN с листом «Отчеты» (без строк с неизвестным номером) |

План работ: chat-plan §9.3.6; SQL-пакет: `docs/development/notes/sql/26-0714/` (+ `MSSQL2012/` для prod).

## Stage 1 type=5: диапазон листа и фильтры (решение 2026-07-14)

**Контекст UAT:** в логе «Найден диапазон … `$D$2:$D$19135`», прогресс кажется «обрывающимся», `отфильтровано по типу … UNKNOWN_SIGN ×17002`. На шаре проверены файлы `2025_2026_01`, `2026_03`, `2026-07` (лист «Отчеты»).

### Факты

1. Нижняя граница диапазона **ранее** = последняя непустая ячейка в колонке якоря (`№ ОА` / `rainRaNum`). После блока данных часто шёл **резерв пустых строк** и хвост (число/формат) → диапазон ~19 к. **Исправлено в §9.3.7.2:** нижняя граница — последняя значимая строка.
2. Фильтр по `rsc_sign_whitelist` **ранее** выполнялся до проверки «пустая строка» → пустой `rainSign` как **`UNKNOWN_SIGN`**. **Исправлено в §9.3.7.1.**
3. Признак **`ОА Аренда`** на шаре **всегда** отсекается whitelist’ом; отдельный regex по номеру для аренды **не нужен** (100 % совпадение по колонке «Признак»; «кривые» № вроде `0046/31025` тоже с этим признаком).
4. Поле `ags.ra_sheet_conf.rsc_row_pattern` (`%_______-%`) в БД **есть**, в Java Stage 1 **не используется** (зафиксировано ещё в plan 26-0323).

### Принятое целевое поведение

| Шаг | Правило | Лог |
|-----|---------|-----|
| 1 | Нормализация «№ ОА» (схлопнуть пробелы / переводы строк) | — |
| 2 | Пустая строка / пустой № (и нет бизнеса) | только **счётчик** пустых; **не** `UNKNOWN_SIGN` |
| 3 | `Признак = «ОА Аренда»` | исключить; **агрегат** `исключено по признаку «ОА Аренда» = N` |
| 4 | Whitelist `ОА` / `ОА изм` / `ОА прочие` | кандидаты на INSERT (как сейчас) |
| 5 | Прочие непустые № **без** `\d{7}` (и не аренда) | **поштучный** WARN (Excel-строка + значение + признак); на шаре это единицы (хвост вроде `2132.0`) |
| 6 | Нижняя граница диапазона | последняя строка с **осмысленными данными** (whitelist или «ОА Аренда», либо № с `\d{7}`), **не** «последняя непустая в D» |

### Regex для отчётов агентов (конфиг приложения)

Рабочий маркер номера ОА для обрезки диапазона / классификации OTHER (не для отсечения аренды):

```yaml
audit:
  staging:
    type5:
      ra-num-regex: "\\d{7}"
```

- Предпочтителен `\d{7}` (семь цифр кода стройки внутри №), а не жёсткий `-\\d{7}-`: на шаре подтягивает `НПТ…У3001052-1`, `СЗ26-2001507Е1`.
- Хранить в **настройках приложения**, чтобы править по логу OTHER без DDL.
- `rsc_row_pattern` в БД — не опираться до явного решения (deprecate / заменить на regex в app).

Проверка на шаре (исключение аренды **только по признаку**, затем `\d{7}`):

| Файл | «ОА Аренда» | Кандидаты `\d{7}` | OTHER |
|------|-------------|-------------------|-------|
| 2025 | 3108 | 13672 | 1 |
| 2026_03 | 412 | 1720 | 1 |
| 2026-07 | 1478 | 5959 | 1 |

**Статус §9.3.7 (Stage 1 фильтр):** 9.3.7.1–9.3.7.5 ✅ (smoke JAR 0.1.0.129, exec 1175/1176; formal sign-off 2026-07-15 / G4). Задача **0052** закрыта.

## Дерево сверки в логе (type=5 / type=3) — решение 2026-07-15

**Задача 0053**, chat-plan §9.3.8.

После «Начало сверки» целевая иерархия (развёртка `<details>`, badge `+`/`−`):

### Type=5

1. Всего строк staging  
2. **ОА** → собственно ОА | изменения к ОА (база `ra_type=ОА`)  
3. **ОА прочие** → собственно ОА прочие | изменения к ОА прочие (база `ОА, прочие`)  
4. В каждом: NEW / CHANGED / ошибки (группировка значение→Excel-строки) / (опц.) лишние  
5. NEW ≠ ошибки (invalid отдельно)  
6. Изм. без резолва базы — отдельный «хвост», не угадывать ОА vs прочие  

**Факт БД:** изм. к «ОА прочие» редки (**2** / ~3047 в `ra_change`), но реальны → ветка 1.2.2 обязательна.

**Статус §9.3.8.1 (каркас):** в логе после режима — `Всего строк` + nested spans `ОА` / `ОА прочие` / (опц.) orphan; внутри — собственно / изменения к базе; при NEW/CHANGED=0 — «Не найдены…». Коды: `RECONCILE_TYPE5_OA_*`, `RECONCILE_TYPE5_OA_OTHER_*`, `RECONCILE_TYPE5_RC_ORPHAN_*`. Классификация изм. по `ags.ra.ra_type` базы.

**Статус §9.3.8.2 (списки):** под NEW/CHANGED — span **«готово к внесению»** (dry-run) или **«внесено»** (apply) со строками Access-стиля (№ Excel, № ОА, суммы / inline-diff). `SUMMARY` — первые **40** + «и ещё N (… VERBOSE)»; `VERBOSE` — полный список; `MINIMAL` — только счётчики.

**Статус §9.3.8.3 (ошибки):** «Не участвуют в сверке / ошибки» → стройки / отправитель / неоднозначность / иные; значение→Excel-строки; meta `primaryReason`. Приоритет primary: стройка → отправитель → иное.

### Type=3

Один ствол «Отчёты аренды» без ОА/прочие/изм.: Всего → NEW → CHANGED → **Без рассмотрения (пустое «Поступило»)** → ошибки A1–A4 → (опц.) лишние. Детализация FK и A5 — только в дереве сверки (агрегат Stage 2 в логе остаётся; построчные WARN Stage 2 / плоские A5 не дублируются).

**Статус §9.3.8.4:** `RalpReconcileTreeLogger` + `RalpReconcileErrorMapper`; вызов из `RalpReconcileService`; unit `RalpReconcileTreeLoggerTest`. A5 — span `+`/`−` внутри ствола (SUMMARY лимит 40).

**Статус §9.3.8.5 (закрыто 2026-07-15):** smoke + sign-off оператора («замечаний нет»). JAR **0.1.0.134**. Ключевые exec: type=5 март dry **1186** / apply **1187** (+откат); июль dry **1188** (5959 строк, ~340 с); type=3 июль apply **1183** (+откат). Июль type=5 apply не запускался. Задача **0053** закрыта.

### UI toggle +/−

Frontend `audit-log.css`: при `details[open]` badge `_START` показывает «−» (U+2212), иначе «+». Совместимо со старыми HTML, где в badge уже литерал «+».

## Ошибки формата ячеек Excel (Stage 1)

**Задача 0045, фаза 7.3 чат-плана.** Сейчас `AuditExcelCellReader.readInt()` / `readDecimal()` при несовпадении типа бросают `AuditExcelException` → откат всего staging → ревизия `FAILED`. Целевое поведение: **ревизия не падает**, пользователь видит причину в `adt_results` и сам правит Excel.

### Правила (после реализации 0045)

| Поле в `ra_col_map` | Ошибка формата (int / decimal / date) | Строка в staging | Сообщение в логе |
|---------------------|----------------------------------------|------------------|------------------|
| `rcm_required = 0` | текст вместо числа и т.п. | **Принимается** | WARNING: колонка, заголовок, сырое значение; **«строка принята, поле записано как NULL»** |
| `rcm_required = 1` | то же | **Пропускается** | WARNING: те же детали; **«строка пропущена»** |

Пустое обязательное поле — строка пропускается. В режиме `SUMMARY` в логе указываются **конкретные поля** (имя колонки БД и заголовок Excel): первые **3** + «и ещё N» при большем числе (задача **0049**, chat-plan §9.3.4.3). До реализации 0049 — общее «недостаточно обязательных данных».

### Пример (необязательное поле)

Июльский smoke `exec_key=1141`: в `rainRaSheetsNumber` («Кол-во листов ОА») значение «в электронном виде». После 0045 ожидается:

```
⚠ Excel-строка 4601, лист «Отчеты»:
  колонка rainRaSheetsNumber («Кол-во листов ОА»): ожидается целое число,
  получено «в электронном виде» — строка принята, поле записано как NULL.
```

Строка попадает в `ra_stg_ra` с `rainRaSheetsNumber = NULL`; остальные поля строки сохраняются.

### Итоги листа

В `STAGING_LOAD_STATS` добавляются счётчики `parseErrorFields` (принятые строки с обнулённым полем) и `skippedParseError` (пропущенные из‑за обязательного поля с ошибкой формата). В режиме `MINIMAL` — только итоговые числа.

Компонент `AuditExecutionStalenessWatchdog` раз в N минут ищет `RUNNING` старше порога и пишет в лог префикс `[AuditExecutionStale]`.

**Micrometer** (при подключённом `spring-boot-starter-actuator`):

| Метрика | Тип | Смысл |
|---------|-----|--------|
| `audit.execution.stale.running` | gauge | Текущее число «зависших» строк после последней проверки |
| `audit.execution.stale.rows.detected` | counter | Суммарно зафиксированных строк за все тики (инкремент на размер списка при ненулевом) |
| `audit.execution.stale.check.failure` | counter | Сбои запроса к БД в watchdog |

Просмотр: `GET /actuator/metrics` (включены `health` и `metrics`; см. `management.endpoints.web.exposure` в `application.yml`).

Параметры (`application.yml` / override):

| Свойство | Смысл |
|----------|--------|
| `audit.execution.stale-watchdog-enabled` | Включить проверку (по умолчанию `true`) |
| `audit.execution.stale-warning-after-minutes` | Порог «простоя» в минутах (по умолчанию `45`) |
| `audit.execution.stale-check-cron` | Cron Spring (`0 */10 * * * *` — каждые 10 минут) |

## Поведение при ошибках async

Не только `Exception`, но и `Error` (например `NoSuchMethodError` при несовпадении версий модулей) должны приводить к вызову `markFailed` — см. `AuditExecutionServiceImpl` (`catch (Throwable)`).

---

## Чеклист «сразу по эксплуатации» (после релиза / раз в квартал)

### 1. Выкладка приложения (все среды, где крутится femsq-web)

Цель: на каждом хосте JAR не старее логики с `catch (Throwable)` и `AuditExecutionStalenessWatchdog` (ветка `main` после соответствующих коммитов).

1. Собрать толстый JAR (из корня backend-модуля):  
   `mvn -pl femsq-web -am package -DskipTests`  
   Артефакт: `code/femsq-backend/femsq-web/target/femsq-web-0.1.0.*-SNAPSHOT.jar` (четвёртая цифра версии см. в `code/pom.xml`).
2. Остановить сервис приложения → заменить JAR → запустить (команды зависят от ОС: `systemd`, Docker, ручной `java -jar`, и т.д.).
3. Убедиться, что поднялся тот же порт/контекст, что и раньше; при необходимости проверить GraphQL `executeAudit` на тестовой ревизии.

*Автоматически из IDE/агента на ваши прод-серверы зайти нельзя — пункты 1–2 выполняет оператор на каждой среде.*

### 2. БД: колонка и seed `rsc_sign_whitelist` (type=5)

Changeset: `code/femsq-backend/femsq-web/src/main/resources/db/changelog/changes/2026-04-02-ra-sheet-conf-sign-whitelist.sql`.

Проверки на **целевой** БД:

```sql
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = N'ags' AND TABLE_NAME = N'ra_sheet_conf'
  AND COLUMN_NAME = N'rsc_sign_whitelist';

SELECT rsc_key, rsc_sign_whitelist
FROM ags.ra_sheet_conf
WHERE rsc_key = 1;
```

Ожидание: колонка `nvarchar(500)`; для `rsc_key = 1` — `ОА;ОА изм;ОА прочие` (или осознанно иное значение).

Если таблицы Liquibase (`DATABASECHANGELOG`) в базе нет — сравнение с файлом changeset всё равно обязательно: схема могла накатываться вручную или другим способом.

**Журнал проверки (DBHub, подключение по умолчанию, 2026-04-04):** колонка присутствует; для `rsc_key = 1` whitelist задан; активных `RUNNING` в `ra_execution` нет.

### 3. Долгие `RUNNING` (квартальный / после инцидента)

Выполнить запрос из раздела «Разовая проверка БД» выше. Пустой результат — норма. При строках — разбор по runbook (ручной `FAILED` при мёртвом процессе + повторный запуск после деплоя).

## Исходники JasperReports

Канонические **`.jrxml`** встроенных отчётов — только в `femsq-reports/src/main/resources/reports/embedded/`. Копии под `**/temp/**/*.jrxml` в репозиторий не коммитить (см. корневой `.gitignore`).

**Файл создан:** 2026-04-03  
**lastUpdated:** 2026-07-09
