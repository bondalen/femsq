# Правила ведения проектной документации FEMSQ

**Версия:** 2.1.0  
**Дата создания:** 2025-10-08  
**Последнее обновление:** 2026-11-17  
**Автор:** Александр  

## Обзор

Данный документ описывает структуру, правила и порядок ведения проектной документации для "Cистемы работы с контрагентами и объектами при капитальном строительстве на основе БД MS SQL Server" FEMSQ (Fish Eye MS SQL Server). Система предназначена для организации взаимодействия с контрагентами и дочерними организациями при капитальном строительстве.

## Связанные документы

- **[Справочник по системе ссылок](project-documentation-rules-reference.md)** - таблица форматов ссылок, примеры, правила формирования ID
- **[Система структурной нумерации](project-documentation-rules-structural-numbering.md)** - правила нумерации модулей, компонентов, классов
- **Правила отчётов JasperReports:** `code/femsq-backend/femsq-reports/src/main/resources/reports/embedded/REPORTING_RULES.md` (обязательно соблюдать при переносе/разработке отчётов)
- **MS Access — снятие сведений о таблицах, запросах и объектах:** [project/proposals/vba-analysis/MS-ACCESS-OBJECTS-CAPTURE.md](project/proposals/vba-analysis/MS-ACCESS-OBJECTS-CAPTURE.md) (порядок работы; каталог `access-queries/`: [access-queries/README.md](project/proposals/vba-analysis/access-queries/README.md))

## Роли документов и синхронизация с реальным состоянием

> Введено 2026-11-17 по итогам аудита ([chat-plan-26-1116-docs-sync.md](development/notes/chats/chat-plan/chat-plan-26-1116-docs-sync.md), реестр Р-26…Р-31). Цель — чтобы документация не отставала от кода и прода: меньше обязательного дублирования, конкретные моменты обновления, автоматическая проверка.

### Роли

| Документ | Роль | Чего в нём **не** ведём |
|----------|------|--------------------------|
| План чата `development/notes/chats/chat-plan/chat-plan-YY-MMDD-*.md` | **Рабочий документ:** цель, дерево работ (WBS), статусы узлов, ход, решения, журнал правок | — |
| Дорожная карта (сейчас [roadmap-r1](development/notes/chats/chat-plan/chat-plan-26-1116-roadmap-r1.md)) | Целевое состояние горизонта, треки, выпуски, **реестр планов**, бэклог | Детали работ — они в планах |
| `development/project-development.json` | **Реестр задач:** одна задача = направление работ (обычно = план чата); статус, ссылка `chatPlan`, место в дереве | Шаги и подпункты плана |
| `journal/project-journal.json` | **Журнал:** чат = сессия работы; лог = завершённый блок/шаг | Повтор содержания плана (кратко + ссылка) |
| `project/project-docs.json` + `extensions/` | **Описание системы:** архитектура, окружения (включая прод), функции, проблемы | История работ |
| `project/extensions/modules/modules.json` | **Модули и пакеты** кода (не классы) | История сборок — в `extensions/modules/builds-manifest.json` |
| [`project/business-processes.md`](project/business-processes.md) | **Этапы пользователя:** все бизнес-процессы со сквозной нумерацией (P1, P2, …) | Детали — в доменных документах |

### Точки синхронизации (обязательно)

| Событие | Что обновить |
|---------|--------------|
| **Создан план чата** | Задача в `project-development.json` (`status: pending/in-progress`, `links.chatPlan`, место в `structure.trees`); чат в журнале (`links.chatPlan`); строка в реестре планов дорожной карты |
| **Завершён блок плана** | Статус узла в плане; лог в журнале; коммит |
| **Закрыт план** | Задача → `completed`; чат → `completed`; реестр планов; `modules.json` — если появились/исчезли пакеты; `project-docs.json` → `features` — если появилась функция; хвосты — в бэклог дорожной карты, не «открытыми» в закрытом плане |
| **Выкладка на прод** | `project-docs.json` → `development.environments.machines.prod-fisheye`: версия JAR, применённые SQL-пакеты, дата; ссылка из плана |
| **Новый бизнес-процесс или этап** | [`project/business-processes.md`](project/business-processes.md) + доменный документ |
| **Новый REST-контроллер** (только исключения) | Таблица исключений в `.cursorrules` |

### Словари

- **Статусы** задач, чатов, узлов дерева: `pending` · `in-progress` · `paused` · `blocked` · `completed` · `cancelled`. Других написаний (`in_progress`, `active`, `started`, `planned`) не используем. Соответствие значкам планов: ☐ `pending`, 🔶 `in-progress`, ⏸ `paused`, ⛔ `blocked`, ✅ `completed`.
- **Статус лога:** `completed` · `failed` · `blocked` (лог пишется по факту).
- **Идентификаторы:** чат `chat-YYYY-MM-DD-NNN`, лог `log-YYYY-MM-DD-NNN` — `NNN` = следующий свободный номер **за дату по всему журналу** (проверяет `check-docs`); задача — `tasks.nextTaskId`.
- **Порядок журнала:** `sessions` — по убыванию `created`; новый чат — в начало.

### Проверка `check-docs`

Скрипт `code/scripts/check-docs.sh` (вводится в блоке 4 плана docs-sync) проверяет документацию на расхождения.

| Ошибка (блокирует) | Предупреждение |
|--------------------|----------------|
| Невалидный JSON | `lastUpdated` старше 60 дней |
| Битые пути в действующих разделах | План без задачи / без чата / без строки в реестре планов |
| Повторяющиеся id задач, чатов, логов | Статусы плана, задачи и чата расходятся |
| Статус вне словаря | Пакет есть в коде, но не в `modules.json`, и наоборот |
| `@RestController` вне таблицы исключений `.cursorrules` | Порядок журнала нарушен |
| | Битые пути в исторических записях (по списку исключений) |

**Когда запускать:** вручную в любой момент; pre-commit хук (`.githooks/`, подключается `core.hooksPath`); `build-thin-jar.sh`; обязательно — при закрытии плана и перед выкладкой на прод.  
**Режим:** до блока 13 плана docs-sync — только предупреждает; после — ошибки блокируют коммит и сборку. Предупреждения не блокируют никогда.

## Структура документации

### 1. **project/project-docs.json** - Проектная документация
**Назначение:** Центральный файл с описанием архитектуры, технологий, модулей и конфигурации проекта.
**Содержание и правила ведения:** описаны в файле **project/project-docs-json-rules.md**.

### 2. **development/project-development.json** - Планирование разработки
**Назначение:** Файл планирования разработки в виде иерархической структуры задач с возможностью сворачивания ветвей.
**Содержание и правила ведения:** описаны в файле **development/project-development-json-rules.md**.

### 3. **journal/project-journal.json** - Дневник разработки
**Назначение:** Дневник разработки с детальным описанием выполненных работ, изменений и состояний.
**Содержание и правила ведения:** описаны в файле **journal/project-journal-json-rules.md**.

### 4. **project/glossary.md** - Словарь терминов
**Назначение:** Алфавитный реестр определений терминов предметной области и проекта (ИП, ревизия, расчёт освоения, UtPl и т.д.).
**Правила:** новые термины — в алфавитном порядке по заголовку; при изменении определения — обновлять дату статьи и `lastUpdated` файла.


### 5. **project/business-processes.md** - Этапы пользователя
**Назначение:** сводный документ всех бизнес-процессов приложения со сквозной нумерацией (P1 СУДЗ, P2 освоение лимитов, …). Доменные документы (`development/notes/domain/*/03-processes.md`) содержат расширенное описание и ссылаются на номера отсюда.
**Правила:** новый процесс или этап — сначала строка здесь, затем доменный документ; номера не переиспользуются.


## Объекты разработки

### Кодовая база проекта
- Модули Maven, пакеты backend и разделы frontend описаны в `project/extensions/modules/modules.json` на уровне **модулей и пакетов** (отдельные классы не регистрируются).

## Процесс добавления новых артефактов

### Чеклист (уровень пакета, а не класса)

Регистрация нужна, когда появляется или исчезает **модуль, пакет backend, раздел frontend (`views/*`, `api/*`), GraphQL-схема, SQL-пакет** — не на каждый класс.

1. **`modules.json`** — модуль/пакет: `id`, `name`, `artifact.location`, `responsibilities`, `status`, `dependsOn`.
2. **Задача** в `project-development.json` — только если это новое направление работ; иначе артефакт относится к задаче текущего плана чата.
3. **План чата** — артефакт упоминается в узле дерева работ, где создан.
4. **Журнал** — лог завершённого блока содержит ссылки (`projectDocsRefs`, `developmentTasks`).
5. **REST** — новый `@RestController` допустим только как исключение из `.cursorrules`; иначе GraphQL.

### Контроль целостности ссылок

Выполняется скриптом `check-docs` (см. «Проверка `check-docs`»), а не вручную. Формат ссылок — `type:path`:
- `projectDocsRefs`: `module:…`, `component:…`, `table:tableName`
- `journalRefs`: `chat:chatId`, `log:logId`
- `developmentTasks`: `task:taskId`
- `aiRuleRefs`: `rule:ruleId`

## Связи между файлами

### Принципы связей

**Все связи выражаются через поле `links` с использованием иерархических путей:**

```json
{
  "links": {
    "projectDocsRefs": ["class:backend.config.Service", "table:users"],
    "journalRefs": ["chat:chat-2025-10-09-001", "log:log-2025-10-09-001"],
    "developmentTasks": ["task:0004", "task:0005"],
    "aiRuleRefs": ["rule:coding-standards"]
  }
}
```

**Формат ссылок:**
- `class:module.component.class` - артефакт кода
- `module:moduleId` - модуль проекта
- `component:module.component` - компонент
- `table:tableName` - таблица БД
- `task:taskId` - задача разработки
- `chat:chatId` или `log:logId` - запись журнала
- `rule:ruleId` - правило AI

### 1. **project-docs.json** → **project-development.json**

Задачи разработки ссылаются на артефакты проекта:

```json
// modules.json (расширение project-docs.json)
{
  "class": {
    "attributes": {
      "id": "DatabaseConfigService",
      "number": "01.01.01",
      "artifact": {
        "location": "com.femsq.database.config.DatabaseConfigService"
      }
    }
  }
}

// project-development.json
{
  "tasks": {
    "items": {
      "0004": {
        "task": {
          "task-attributes": {
            "links": {
              "projectDocsRefs": [
                "class:backend.database-config.DatabaseConfigService"
              ]
            }
          }
        }
      }
    }
  }
}
```

### 2. **project-development.json** → **project-journal.json**

Задачи ссылаются на записи журнала:

```json
// project-development.json
{
  "tasks": {
    "items": {
      "0004": {
        "task": {
          "task-attributes": {
            "links": {
              "journalRefs": [
                "chat:chat-2025-10-09-001",
                "log:log-2025-10-09-001"
              ]
            }
          }
        }
      }
    }
  }
}

// project-journal.json
{
  "sessions": [
    {
      "chat": {
        "chat-attributes": {
          "id": "chat-2025-10-09-001"
        }
      }
    }
  ]
}
```

### 3. **project-journal.json** → **project-development.json**

Записи журнала ссылаются на задачи:

```json
// project-journal.json
{
  "chat": {
    "chat-attributes": {
      "id": "chat-2025-10-09-001",
      "links": {
        "developmentTasks": [
          "task:0004",
          "task:0005"
        ]
      }
    }
  }
}
```

### 4. **project-journal.json** → **project-docs.json**

Записи журнала ссылаются на артефакты и таблицы:

```json
// project-journal.json
{
  "log": {
    "log-attributes": {
      "id": "log-2025-10-09-001",
      "links": {
        "projectDocsRefs": [
          "class:backend.database-config.DatabaseConfigService",
          "table:contractors"
        ]
      }
    }
  }
}
```

### Важно

**Внутренняя организация project-development.json** (деревья структуры с пунктами) - это НЕ связь между файлами, а механизм организации задач для навигации. При изменении статуса задачи он автоматически синхронизируется во всех пунктах структуры, где эта задача используется.

---

## Система ссылок через иерархические пути

### Формат ссылок

Все ссылки используют формат `type:path`, где путь строится из ID элементов через точку.

### Таблица форматов

| Тип | Формат | Пример |
|-----|--------|--------|
| Модуль | `module:id` | `module:backend` |
| Компонент | `component:module.component` | `component:backend.database-config` |
| Класс | `class:module.component.class` | `class:backend.database-config.DatabaseConfigService` |
| Вложенный класс | `class:module.component.class.nested` | `class:backend.config.Service.Validator` |
| Таблица БД | `table:name` | `table:contractors` |
| Задача | `task:id` | `task:0004` |
| Дерево | `tree:number` | `tree:01` |
| Пункт структуры | `item:tree.structure` | `item:01.01.01` |
| Чат | `chat:id` | `chat:chat-2025-10-09-001` |
| Лог | `log:id` | `log:log-2025-10-09-001` |
| Правило AI | `rule:id` | `rule:coding-standards` |

### Правила формирования ID

**Для модулей и компонентов:**
- Использовать kebab-case
- Краткие, но понятные
- Примеры: `backend`, `database-config`, `user-auth`

**Для классов:**
- PascalCase (как в коде)
- Полное имя класса
- Примеры: `DatabaseConfigService`, `ConnectionManager`, `UserRepository`

**Для таблиц:**
- snake_case (как в БД)
- Множественное число
- Примеры: `contractors`, `users`, `order_items`

### Преимущества

- ✅ **Устойчивость** - не зависит от порядка элементов в массивах
- ✅ **Уникальность** - путь через точку гарантирует уникальность
- ✅ **Читаемость** - понятна структура и местоположение
- ✅ **Соответствие коду** - похоже на пути пакетов Java
- ✅ **Гибкость** - можно ссылаться на любой уровень иерархии

## SQL Server и продуктивное окружение

- **Продуктивная БД:** `FishEye`, схема `ags`, MS SQL Server **2012 SP4** (`11.0.7507.2`). Зафиксировано в `project-docs.json` → `database` и `development.environments.machines.prod-fisheye`.
- **Разработка:** Docker `femsq-mssql` (SQL Server 2022) — не является целевой платформой для DDL на prod.
- **SQL-пакеты:** для продуктива обязательна подпапка `MSSQL2012/` в каталоге задачи; см. `docs/deployment/sql-server-deployment-rules.md` и `docs/project/extensions/database/compatibility.json`.
- **Реестр окружений:** `project-docs.json` → `development.environments`; расширение `docs/project/extensions/deployment/environments.json`.
- **Удалённая разработка (Fedora → БД на nb-win):** `docs/development/remote-development-nb-win.md`; после `git pull` — `code/scripts/setup-cursor-mcp.sh`.

## Правила обновления

### Обязательные требования
- **Перед любыми корректировками документации** — изучить правила здесь и в project/project-docs-json-rules.md, development/project-development-json-rules.md, journal/project-journal-json-rules.md.
- **Перед созданием записи чата в журнале** — запросить имя чата у пользователя с вариантами.
- **Точки синхронизации** (раздел выше) обязательны; закрытие плана без них не считается закрытием.
- **При изменении структуры** — обновить соответствующие правила и связанные файлы.

### Формат дат
- **Даты в документах:** `YYYY-MM-DD` (системная дата машины).
- **Метки времени логов:** ISO 8601 с часовым поясом, например `2026-11-17T10:30:00+03:00`.

## Структура файлов документации

### Организация папок (фактическая, 2026-11)
```
docs/
├── project-documentation-rules.md      # Правила ведения документации (этот файл)
├── project/
│   ├── project-docs.json               # Описание системы; extensions/ — modules, database, deployment
│   ├── business-processes.md           # Этапы пользователя (P1, P2, …)
│   ├── glossary.md                     # Словарь терминов
│   ├── decisions/                      # Решения (ADR)
│   ├── architecture/, diagrams/        # Архитектура, диаграммы
│   └── proposals/vba-analysis/         # Сведения об MS Access (VBA, таблицы, запросы)
├── development/
│   ├── project-development.json        # Реестр задач
│   ├── technical/                      # Технические описания (отчёты и др.)
│   └── notes/
│       ├── chats/chat-plan/            # Планы чатов + дорожная карта
│       ├── chats/chat-resume/          # Резюме чатов
│       ├── domain/<домен>/             # Доменные документы (sudz, mastering, …)
│       ├── sql/<YY-MMDD-задача>/       # SQL-пакеты; MSSQL2012/ — для прода
│       ├── UI/, analysis/, audit-log/  # Эскизы экранов, анализ, ревизии
│       └── setup/, ops/                # Окружение, эксплуатация
├── deployment/                         # Инструкции выкладки (db-upgrade-*, checklists)
└── journal/
    └── project-journal.json            # Журнал
```

## Автоматизация и контроль качества

- **Проверка:** `check-docs` (раздел «Проверка `check-docs`») заменяет ручные проверки структурной и ссылочной целостности.
- **Ревизия документации:** при закрытии каждого плана чата и перед каждой выкладкой на прод — прогон `check-docs` и сверка реестра планов дорожной карты. Отдельных календарных ревизий нет.
- **Резервные копии:** git; перед массовой правкой JSON — копия файла рядом (`*.bak-YYYYMMDD`, в `.gitignore`).

## Заключение

Данная система документации обеспечивает:
- **Полноту** - охват всех аспектов проекта
- **Структурированность** - четкая организация информации
- **Трассируемость** - возможность отслеживания изменений
- **Масштабируемость** - возможность расширения системы
- **Удобство использования** - простота навигации и поиска
- **Поддержку разработки правил AI** - как объектов разработки
- **Правила для AI-ассистента** - четкие инструкции для работы с Cursor IDE

Соблюдение данных правил гарантирует качество и актуальность проектной документации на всех этапах разработки системы.

---

**Документ утвержден:** 2025-10-09; редакция 2.1.0 — 2026-11-17  
**Следующий пересмотр:** при закрытии плана docs-sync (блок 14)  
**Ответственный:** Александр
