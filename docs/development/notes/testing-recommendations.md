# Рекомендации по совершенствованию системы тестов FEMSQ

**Дата:** 2025-11-13  
**Автор:** Александр

## Обзор

Создана комплексная система тестирования с автоматизацией запуска тестов в нужное время.

## Реализованные улучшения

### 1. Maven профили для разделения тестов

#### Профиль `unit` (по умолчанию)
- Запускает только unit-тесты (`*Test.java`)
- Быстро (< 1 минуты)
- Не требует внешних зависимостей
- Команда: `mvn test`

#### Профиль `integration`
- Запускает только integration-тесты (`*IT.java`, `*IntegrationTest.java`)
- Требует переменные `FEMSQ_DB_*`
- Команда: `mvn verify -Pintegration`

#### Профиль `ci`
- Запускает unit-тесты + генерирует отчеты о покрытии кода
- Команда: `mvn test -Pci`
- Отчеты: `target/site/jacoco/index.html`

### 2. Скрипты для удобного запуска

Созданы скрипты в `code/scripts/`:

- **`test-unit.sh`** - запуск unit-тестов
  ```bash
  ./code/scripts/test-unit.sh [database|web|all]
  ```

- **`test-integration.sh`** - запуск integration-тестов
  ```bash
  ./code/scripts/test-integration.sh [database|web|all]
  ```

- **`test-all.sh`** - запуск всех тестов
  ```bash
  ./code/scripts/test-all.sh
  ```

- **`test-e2e.sh`** - запуск E2E-тестов
  ```bash
  ./code/scripts/test-e2e.sh
  ```

### 3. GitHub Actions CI/CD

Создан workflow `.github/workflows/ci.yml` с автоматическим запуском:

#### Job: `unit-tests`
- **Когда**: При каждом PR и push
- **Что делает**: Запускает все unit-тесты
- **Время**: ~2-3 минуты

#### Job: `integration-tests`
- **Когда**: 
  - При push в main/develop
  - При PR с тегом `[test-integration]` в названии/коммите
- **Что делает**: 
  - Поднимает MS SQL Server в Docker
  - Настраивает тестовую БД
  - Запускает integration-тесты
- **Время**: ~5-10 минут

#### Job: `e2e-tests`
- **Когда**: 
  - При merge в main
  - При коммите с тегом `[test-e2e]`
- **Что делает**: 
  - Собирает backend
  - Запускает backend
  - Запускает E2E-тесты Playwright
- **Время**: ~10-15 минут

#### Job: `code-coverage`
- **Когда**: При merge в main
- **Что делает**: Генерирует отчеты о покрытии кода
- **Время**: ~3-5 минут

## Время запуска тестов

### При локальной разработке

| Действие | Тесты | Команда |
|----------|-------|---------|
| **Быстрая проверка** | Unit | `./code/scripts/test-unit.sh` |
| **Перед коммитом** | Unit + Integration | `./code/scripts/test-all.sh` |
| **Перед PR** | Unit + Integration | `./code/scripts/test-all.sh` |
| **Перед релизом** | Все | `./code/scripts/test-all.sh && ./code/scripts/test-e2e.sh` |

### В CI/CD

| Событие | Unit | Integration | E2E | Coverage |
|---------|------|-------------|-----|----------|
| **PR создан** | ✅ Автоматически | ⚠️ По требованию | ❌ Нет | ❌ Нет |
| **PR с [test-integration]** | ✅ | ✅ Автоматически | ❌ Нет | ❌ Нет |
| **Merge в main** | ✅ | ✅ | ✅ | ✅ |
| **Push в main** | ✅ | ✅ | ✅ | ✅ |

## Рекомендации по использованию

### Для разработчиков

1. **При разработке**: Запускайте unit-тесты часто (`mvn test`)
2. **Перед коммитом**: Запускайте все тесты (`./code/scripts/test-all.sh`)
3. **При изменении БД кода**: Обязательно запускайте integration-тесты
4. **Перед PR**: Убедитесь, что все тесты проходят

### Для CI/CD

1. **Unit-тесты**: Запускаются автоматически при каждом PR
2. **Integration-тесты**: Запускаются автоматически при merge в main
3. **E2E-тесты**: Запускаются автоматически при merge в main
4. **Coverage**: Генерируется автоматически при merge в main

### Принудительный запуск тестов в CI

Если нужно запустить integration-тесты в PR, добавьте в название PR или коммит:
- `[test-integration]` - запустит integration-тесты
- `[test-e2e]` - запустит E2E-тесты

## Структура файлов

```
code/
├── scripts/
│   ├── test-unit.sh              # Unit-тесты
│   ├── test-integration.sh       # Integration-тесты
│   ├── test-all.sh               # Все тесты
│   ├── test-e2e.sh               # E2E-тесты
│   └── README-TESTING.md         # Инструкция
├── femsq-backend/
│   ├── femsq-database/
│   │   └── pom.xml               # Профиль integration
│   └── femsq-web/
│       └── pom.xml               # Профили integration, ci
.github/
└── workflows/
    └── ci.yml                    # CI/CD конфигурация
docs/development/notes/
├── testing-strategy.md            # Стратегия тестирования
├── testing-improvements-summary.md # Резюме улучшений
└── testing-recommendations.md    # Этот файл
```

## Дальнейшие улучшения (опционально)

### 1. Теги JUnit 5
Добавить теги для более гибкой категоризации:
```java
@Tag("unit")
@Tag("fast")
@Test
void testMethod() { ... }
```

### 2. Testcontainers
Использовать Testcontainers для автоматического поднятия БД в тестах (упростит CI)

### 3. Pre-commit hooks
Автоматический запуск unit-тестов перед коммитом

### 4. Параллельный запуск
Настроить параллельный запуск тестов для ускорения

### 5. Интеграция с Codecov
Автоматическая загрузка отчетов о покрытии в Codecov

## Заключение

Система тестирования теперь:
- ✅ Разделена по типам (unit/integration/e2e)
- ✅ Автоматизирована через CI/CD
- ✅ Имеет удобные скрипты для разработчиков
- ✅ Запускается в нужное время автоматически
- ✅ Генерирует отчеты о покрытии кода

Все тесты проверяются в нужное время через GitHub Actions и могут быть запущены вручную через скрипты.


