# Архитектура модулей системы подключения к БД

**Дата создания:** 2025-01-27  
**Версия:** 2.0.0  
**Статус:** Проектирование

## Контекст безопасности
- Работа в **безопасной внутренней сети**
- **Без шифрования** - plain text хранение
- **Без аутентификации пользователей**
- Защита через права ОС (chmod 600)

---

## Структура модулей

### Модуль 01: Backend Module
Субмодуль 01.01: Database (femsq-database)
  - 01.01.01 config/ - Управление конфигурацией
  - 01.01.02 connection/ - Пул соединений
  - 01.01.03 auth/ - Провайдеры аутентификации
  - 01.01.04 model/ - Модели данных
  - 01.01.05 exception/ - Исключения

Субмодуль 01.02: Web API (femsq-web)
  - 01.02.01 controller/ - REST контроллеры
  - 01.02.02 lifecycle/ - Инициализация
  - 01.02.03 health/ - Health checks

### Модуль 02: Frontend Module (femsq-frontend)
  - 02.01 components/ - Vue компоненты
  - 02.02 services/ - API клиенты

---

## PlantUML Диаграммы

См. файлы в `docs/project/diagrams/`:
- `database-module-classes.puml` - Диаграмма классов
- `components.puml` - Диаграмма компонентов
- `first-run-sequence.puml` - Последовательность запуска
- `package-structure.puml` - Структура пакетов

---

## Maven структура

```xml
<modules>
    <module>femsq-backend</module>
    <module>femsq-frontend</module>
</modules>

<!-- В femsq-backend/pom.xml -->
<modules>
    <module>femsq-database</module>
    <module>femsq-web</module>
</modules>
```