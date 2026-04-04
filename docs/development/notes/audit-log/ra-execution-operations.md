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

**Файл создан:** 2026-04-03  
**lastUpdated:** 2026-04-03
