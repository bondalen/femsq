# Эксплуатация: выполнение ревизий (`ags.ra_execution`)

**Назначение:** разовая диагностика «зависших» запусков и ручное снятие блокировки перед повторным `executeAudit`.

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

### Темы

| Тема | CSS-класс | Назначение |
|------|-----------|------------|
| **Kimbie Dark** (по умолчанию) | `.femsq-auditlog.theme-kimbie-dark` | Тёплая тёмная палитра (ориентир Cursor Kimbie Dark) |
| **Светлая (Visual Studio)** | `.femsq-auditlog.theme-vs-light` | Светлый фон, тёмный текст (ориентир Cursor VS Light) |

Переключатель — в `AuditsView`; предпочтение в `localStorage` (`femsq.auditLogTheme`). Стили — во frontend (`audit-log.scss`), не в backend HTML.

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
