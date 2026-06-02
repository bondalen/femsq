# Скриншоты ошибок ODBC/SQL Server (локально на nb-win)

**В Git не коммитятся** — только markdown-документы и при необходимости текстовые артефакты диагностики.

## Базовые пути (nb-win)

| Среда | Путь |
|-------|------|
| WSL | `/home/alex/projects/femsq/docs/sql_err/images/` |
| Проводник Windows | `\\wsl.localhost\Ubuntu\home\alex\projects\femsq\docs\sql_err\images\` |

Если дистрибутив WSL не `Ubuntu`, замените сегмент в UNC-пути на имя вашего дистрибутива.

## Документы в репозитории (Git)

| Файл | Назначение |
|------|------------|
| [rds-odbc-error-analysis.md](rds-odbc-error-analysis.md) | Полный анализ, цепочка уровней, лечение |
| [vba-fix-proposal.md](vba-fix-proposal.md) | Предложения по правкам VBA |
| [README.md](README.md) | Этот каталог и пути к скринам |

Резюме чата: [chat-resume-26-0602-rds-odbc-access-errors.md](../../development/notes/chats/chat-resume/chat-resume-26-0602-rds-odbc-access-errors.md)

## Каталог скриншотов (локальные файлы)

### Корень `images/`

| Файл | Содержание |
|------|------------|
| `26-0601-001.PNG` | ODBC / подключение к FishEye |
| `26-0601-002.PNG` | Сообщение об ошибке (общий контекст) |
| `26-0601-003.PNG` | Дополнительный диалог ошибки |
| `26-0601-004_тест_источника_данных_Windows.PNG` | Тест DSN Windows — неудача |
| `26-0601-005_тест_источника_данных_Windows.PNG` | Тест DSN — детали ошибки |

### `images/26-0601-002_Акты/`

| Файл | Содержание |
|------|------------|
| `26-0601-002_Акты_001.PNG` | Ошибка в сценарии актов |
| `26-0601-002_Акты_002.PNG` | Продолжение сценария |
| `26-0601-002_Акты_003.PNG` | Продолжение сценария |

### `images/tcp/`

| Файл | Содержание |
|------|------------|
| `photo_5255842203169396943_y.jpg` | Настройка / тест DSN с TCP |
| `photo_5255842203169396944_y.jpg` | Tests failed, Named Pipes / TCP |
| `photo_5255842203169396945_y.jpg` | Детали ошибки провайдера |
| `photo_5255842203169396946_y.jpg` | Контекст ODBC Administrator |
| `photo_5255842203169396948_y.jpg` | Доп. скрин теста |
| `photo_5255842203169396949_y.jpg` | Доп. скрин теста |

### `images/tcp/2/`

| Файл | Содержание |
|------|------------|
| `26-0601-003_tcp_001.PNG` | Event ID 4227 — TCP port exhaustion на `NV-SK-TSW112` |
| `Новый текстовый документ.txt` | Вывод `netsh winsock show catalog` |

**Пример полного пути (Windows):**  
`\\wsl.localhost\Ubuntu\home\alex\projects\femsq\docs\sql_err\images\tcp\2\26-0601-003_tcp_001.PNG`

---

*Создано: 2026-06-02*
