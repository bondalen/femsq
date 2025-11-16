# Итоговое предложение: Управление окружениями разработки

## Резюме проблемы

- Разработка на нескольких машинах с разными настройками
- DBHub специфичен для проекта (разные проекты = разные БД)
- Остальные MCP серверы глобальны
- Нужна автоматическая проверка при начале работы

## Решение

### 1. Структура в `project-docs.json`

Добавить секцию `development.environments` с описанием машин:

```json
{
  "development": {
    "environments": {
      "check_order": ["machine1", "machine2"],
      "machines": {
        "machine1": {
          "name": "Описание машины",
          "hostname_pattern": ".*pattern.*",
          "database": { ... },
          "dbhub": { ... }
        }
      }
    }
  }
}
```

**См. пример:** `docs/development/environment-setup-example.json`

### 2. Обновление `.cursorrules`

Добавить секцию проверки окружения при начале работы:

1. Определение текущей машины
2. Проверка DBHub (локально в проекте)
3. Проверка SQL Server
4. Обновление `.cursor/mcp.json` (только `dbhub`)

**См. шаблон:** `.cursorrules.environment-check`

### 3. Локальная установка DBHub

**Структура:**
```
.cursor/
  dbhub/
    package.json
    node_modules/  (в .gitignore)
    .gitignore
```

**Инициализация:**
```bash
./code/scripts/setup-dbhub.sh
```

**В `.cursor/mcp.json`:**
```json
{
  "dbhub": {
    "command": "node",
    "args": [
      "${workspaceFolder}/.cursor/dbhub/node_modules/@bytebase/dbhub/dist/index.js"
    ],
    "env": {
      "DSN": "{из конфигурации машины}"
    }
  }
}
```

### 4. Разделение ответственности

| Компонент | Расположение | Причина |
|-----------|--------------|---------|
| `dbhub` | `.cursor/mcp.json` (в проекте) | Специфичен для проекта, разные БД |
| `desktop-commander` | `~/.cursor/mcp.json` (глобально) | Глобальный инструмент |
| `fedoc` | `~/.cursor/mcp.json` (глобально) | Глобальный инструмент |

## Файлы

1. **`docs/development/environment-setup-proposal.md`** - Детальное предложение
2. **`docs/development/environment-setup-example.json`** - Пример конфигурации
3. **`.cursorrules.environment-check`** - Шаблон проверки
4. **`code/scripts/setup-dbhub.sh`** - Скрипт установки DBHub
5. **`.cursor/dbhub/.gitignore`** - Игнорирование node_modules

## Следующие шаги

1. ✅ Создать структуру для описания машин
2. ✅ Создать скрипт установки DBHub
3. ⏳ Добавить секцию `environments` в `project-docs.json`
4. ⏳ Обновить `.cursorrules` с инструкциями проверки
5. ⏳ Протестировать на обеих машинах

## Преимущества

- ✅ Автоматическое определение машины
- ✅ Локальная установка DBHub для каждого проекта
- ✅ Разные БД для разных проектов
- ✅ Глобальные MCP серверы остаются глобальными
- ✅ Автоматическая проверка при начале работы
