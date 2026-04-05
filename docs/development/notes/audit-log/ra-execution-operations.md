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

Компонент `AuditExecutionStalenessWatchdog` раз в N минут ищет `RUNNING` старше порога и пишет в лог префикс `[AuditExecutionStale]`.

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

**Файл создан:** 2026-04-03  
**lastUpdated:** 2026-04-04
