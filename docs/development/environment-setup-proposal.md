# Предложение: Управление окружениями разработки

## Проблема

Разработка ведется на нескольких машинах с разными:
- Путями к MS SQL Server
- Параметрами подключения к БД
- Установками инструментов

DBHub специфичен для проекта (разные проекты = разные БД), остальные MCP серверы глобальны.

## Решение

### 1. Структура описания машин в `project-docs.json`

Добавить секцию `development.environments`:

```json
{
  "development": {
    "environments": {
      "description": "Машины разработки с порядком приоритета подключения",
      "check_order": [
        "machine1",
        "machine2"
      ],
      "machines": {
        "machine1": {
          "name": "Основная рабочая машина",
          "hostname": "workstation-1",
          "os": "Fedora 42",
          "priority": 1,
          "database": {
            "type": "docker",
            "container_name": "vuege-mssql",
            "host": "localhost",
            "port": 1433,
            "database": "Fish_Eye",
            "username": "sa",
            "password": "kolob_OK1",
            "connection_string": "sqlserver://sa:kolob_OK1@localhost:1433/Fish_Eye?sslmode=disable&encrypt=false&trustServerCertificate=true"
          },
          "dbhub": {
            "type": "local",
            "path": ".cursor/dbhub",
            "package": "@bytebase/dbhub",
            "version": "latest"
          },
          "notes": "Основная машина разработки, SQL Server в Docker"
        },
        "machine2": {
          "name": "Домашняя машина",
          "hostname": "home-pc",
          "os": "Windows 11",
          "priority": 2,
          "database": {
            "type": "local_service",
            "service_name": "MSSQLSERVER",
            "host": "localhost",
            "port": 1433,
            "database": "FishEye",
            "username": "sa",
            "password": "kolob_OK1",
            "connection_string": "sqlserver://sa:kolob_OK1@localhost:1433/FishEye?sslmode=disable&encrypt=false&trustServerCertificate=true"
          },
          "dbhub": {
            "type": "local",
            "path": ".cursor/dbhub",
            "package": "@bytebase/dbhub",
            "version": "latest"
          },
          "notes": "Домашняя машина, SQL Server как служба Windows"
        }
      }
    }
  }
}
```

### 2. Автоматическая проверка в `.cursorrules`

Добавить секцию проверки окружения:

```markdown
## Проверка окружения разработки

### При начале работы в чате
**ОБЯЗАТЕЛЬНО** выполнить проверку окружения:

1. **Определить текущую машину:**
   - Прочитать `docs/project/project-docs.json` → `development.environments.machines`
   - Сопоставить по `hostname`, `os` или другим признакам
   - Если машина не найдена - запросить у пользователя

2. **Проверить установки:**
   - **DBHub (локально в проекте):**
     - Проверить наличие `.cursor/dbhub/package.json`
     - Если нет - установить: `npm install @bytebase/dbhub --prefix .cursor/dbhub`
     - Проверить наличие `.cursor/dbhub/node_modules/@bytebase/dbhub`
   
   - **SQL Server:**
     - Проверить доступность порта из `database.port`
     - Для Docker: проверить статус контейнера `database.container_name`
     - Для службы: проверить статус службы `database.service_name`
     - Проверить подключение к БД с параметрами из `database.connection_string`

3. **Обновить `.cursor/mcp.json`:**
   - Обновить только секцию `dbhub`:
     - `command`: путь к локальной установке DBHub
     - `env.DSN`: использовать `database.connection_string` из текущей машины
   - **НЕ изменять** другие MCP серверы (desktop-commander, fedoc и т.д.)

4. **Сообщить пользователю:**
   - Результаты проверки
   - Обнаруженные проблемы
   - Выполненные действия

### Шаблон проверки
```bash
# Псевдокод проверки
1. Читаю project-docs.json → development.environments
2. Определяю текущую машину (по hostname или запрашиваю)
3. Проверяю DBHub в .cursor/dbhub/
4. Проверяю SQL Server (порт/контейнер/служба)
5. Обновляю .cursor/mcp.json только для dbhub
6. Сообщаю результаты
```
```

### 3. Локальная установка DBHub в проекте

**Структура:**
```
.cursor/
  dbhub/
    package.json          # Зависимости DBHub
    node_modules/         # Локальная установка (в .gitignore)
    .gitignore           # Игнорировать node_modules
```

**Инициализация:**
```bash
mkdir -p .cursor/dbhub
cd .cursor/dbhub
npm init -y
npm install @bytebase/dbhub
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
      "NODE_ENV": "production",
      "DSN": "${database.connection_string}",
      "TRANSPORT": "stdio"
    }
  }
}
```

### 4. Разделение ответственности

**В проекте (`.cursor/mcp.json`):**
- ✅ `dbhub` - специфичен для проекта

**На машине (`~/.cursor/mcp.json` или глобально):**
- ✅ `desktop-commander` - глобальный инструмент
- ✅ `fedoc` - глобальный инструмент
- ✅ Другие MCP серверы

**Примечание:** Cursor может использовать оба файла, но приоритет у локального `.cursor/mcp.json`.

## Реализация

### Шаг 1: Добавить секцию environments в project-docs.json
### Шаг 2: Обновить .cursorrules с инструкциями проверки
### Шаг 3: Создать скрипт инициализации DBHub
### Шаг 4: Обновить .gitignore для .cursor/dbhub/node_modules

## Преимущества

1. ✅ Автоматическое определение машины
2. ✅ Локальная установка DBHub для каждого проекта
3. ✅ Разные БД для разных проектов
4. ✅ Глобальные MCP серверы остаются глобальными
5. ✅ Автоматическая проверка при начале работы
