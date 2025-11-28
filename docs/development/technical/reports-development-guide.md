# Руководство по разработке отчётов FEMSQ

**Версия:** 1.0.0  
**Дата:** 2025-11-21  
**Автор:** Александр  

---

## Обзор

Данное руководство описывает процесс разработки отчётов для системы FEMSQ с использованием JasperReports.

**Связанные документы:**
- [ADR 003: Выбор движка генерации отчётов](../../project/decisions/adr-003-reporting-engine.md)
- [Проектная документация](../../project/project-docs.json) → модуль Reports

---

## Быстрый старт

### 1. Установите Jaspersoft Studio

**Скачать:** [https://community.jaspersoft.com/download](https://community.jaspersoft.com/download)

**Linux:**
```bash
wget https://sourceforge.net/projects/jasperstudio/.../TIB_js-studiocomm_6.21.0_linux_x86_64.tar.gz
tar -xzf TIB_js-studiocomm_6.21.0_linux_x86_64.tar.gz
cd TIB_js-studiocomm_6.21.0/
./Jaspersoft\ Studio
```

### 2. Создайте первый отчёт

1. File → New → Jasper Report → Blank A4
2. Добавьте SQL запрос к БД FEMSQ
3. Создайте простую таблицу
4. Preview → PDF

### 3. Создайте метаданные JSON

```json
{
  "report": {
    "id": "my-first-report",
    "name": "Мой первый отчёт",
    "description": "Тестовый отчёт",
    "files": {
      "template": "my-first-report.jrxml"
    },
    "parameters": []
  }
}
```

### 4. Разверните

```bash
cp my-first-report.* ./reports/templates/
# Подождать 1 минуту → отчёт появится в каталоге
```

---

## Архитектура системы отчётов

Подробнее см. [ADR 003](../../project/decisions/adr-003-reporting-engine.md)

**Компоненты:**
- **Jaspersoft Studio** - визуальный дизайнер (разработчик)
- **JRXML файлы** - шаблоны отчётов (XML)
- **JSON метаданные** - описание параметров и интеграции
- **JasperReports Engine** - генерация PDF/Excel/HTML (backend)
- **ReportsCatalog.vue** - каталог отчётов (frontend)

**Workflow:**
```
Разработчик → Jaspersoft Studio → JRXML + JSON → Git
                                                    ↓
Production сервер ← ./reports/templates/ ← Git pull
                           ↓
              ReportDiscoveryService (hot-reload)
                           ↓
              ReportGenerationService → PDF
```

---

## Создание нового отчёта

### Шаг 1: Планирование

Определите:
- **Цель:** Что показывает отчёт?
- **Данные:** Какие таблицы?
- **Параметры:** Фильтры для пользователя
- **Формат:** PDF/Excel/HTML
- **Интеграция:** Каталог или контекстное меню

### Шаг 2: JRXML в Jaspersoft Studio

**SQL запрос:**
```sql
SELECT id, name, created_at
FROM contractors
WHERE created_at BETWEEN $P{START_DATE} AND $P{END_DATE}
ORDER BY name
```

**Параметры:**
- `START_DATE` (java.sql.Date)
- `END_DATE` (java.sql.Date)

**Bands:**
- Title: Заголовок отчёта
- Column Header: Заголовки колонок
- Detail: Строки данных
- Page Footer: Номер страницы

### Шаг 3: Метаданные JSON

**Файл:** `contractor-report.json`

```json
{
  "report": {
    "id": "contractor-report",
    "name": "Отчёт по контрагентам",
    "description": "Список контрагентов за период",
    "category": "contractors",
    "files": {
      "template": "contractor-report.jrxml"
    },
    "parameters": [
      {
        "name": "START_DATE",
        "type": "date",
        "label": "Дата начала",
        "required": true,
        "defaultValue": "${firstDayOfMonth}"
      },
      {
        "name": "END_DATE",
        "type": "date",
        "label": "Дата окончания",
        "required": true,
        "defaultValue": "${lastDayOfMonth}"
      }
    ],
    "uiIntegration": {
      "showInReportsList": true
    },
    "tags": ["контрагенты"]
  }
}
```

### Шаг 4: Тестирование

1. Preview в Jaspersoft Studio
2. Проверить данные, форматирование
3. Проверить производительность

### Шаг 5: Развёртывание

```bash
# Скопировать на сервер
scp contractor-report.* user@server:/app/reports/templates/

# Или через Git
git add contractor-report.*
git commit -m "feat: добавлен отчёт по контрагентам"
git push
# На сервере: git pull
```

---

## Формат метаданных

### Типы параметров

| Тип | UI Component | Пример |
|-----|--------------|--------|
| `date` | Date Picker | `2025-11-21` |
| `string` | Input | `"текст"` |
| `long` | Number Input | `12345` |
| `boolean` | Switch | `true` |
| `enum` | Select | `["opt1", "opt2"]` |

### Выражения в defaultValue

| Выражение | Значение |
|-----------|----------|
| `${today}` | Сегодня |
| `${firstDayOfMonth}` | 1-е число месяца |
| `${lastDayOfMonth}` | Последний день месяца |
| `${firstDayOfQuarter}` | 1-й день квартала |

---

## Лучшие практики

### Производительность

✅ **Хорошо:**
- Оптимизированные SQL запросы
- Ограничение данных параметрами
- Подотчёты 2-3 уровня максимум

❌ **Плохо:**
- Загрузка всех данных без фильтров
- Подотчёты глубже 5 уровней
- Сложные вычисления в JRXML

### UX

✅ **Хорошо:**
- Описания параметров
- Разумные defaults
- Превью отчётов

❌ **Плохо:**
- Много параметров (>7)
- Технические термины

---

## Troubleshooting

### Отчёт не появляется

1. Проверить путь: `./reports/templates/`
2. Проверить права: `chmod 644 *.jrxml *.json`
3. Подождать 1 минуту (hot-reload)
4. Проверить логи: `grep Report application.log`

### Ошибка компиляции

1. Preview в Jaspersoft Studio
2. Проверить SQL синтаксис
3. Проверить типы параметров

### Медленная генерация

1. Оптимизировать SQL
2. Добавить индексы в БД
3. Ограничить данные

### Кракозябры (кириллица)

1. Encoding UTF-8 в JRXML
2. Font "DejaVu Sans"
3. Dependency `jasperreports-fonts`

---

## Ссылки

- [JasperReports Documentation](https://community.jaspersoft.com/documentation)
- [Jaspersoft Studio Guide](https://community.jaspersoft.com/wiki/jaspersoft-studio-user-guide)
- [ADR 003](../../project/decisions/adr-003-reporting-engine.md)

---

**Версия:** 1.0.0  
**Дата:** 2025-11-21  
**Автор:** Александр
