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
  - 01.01.01 config/ - Управление конфигурацией (`DatabaseConfigurationService`, `ConfigurationValidator`, поддержка `authMode`)
  - 01.01.02 connection/ - Пул соединений (HikariCP, `ConnectionFactory`, `HikariJdbcConnector`, smoke‑тесты)
  - 01.01.03 auth/ - Провайдеры аутентификации (`AuthenticationProviderFactory`, credentials / Windows Integrated / Kerberos)
  - 01.01.04 model/ - Модели данных
  - 01.01.05 exception/ - Исключения

Субмодуль 01.02: Web API (femsq-web)
  - 01.02.01 controller/ - REST контроллеры
  - 01.02.02 lifecycle/ - Инициализация
  - 01.02.03 health/ - Health checks

### Модуль 02: Frontend Module (femsq-frontend-q)
  - 02.01 components/ - Vue компоненты
  - 02.02 services/ - API клиенты

---

## Текущая реализация
- Конфигурация хранится в `~/.femsq/database.properties`, поля `host/port/database`, учетные данные и `authMode` валидируются `ConfigurationValidator`.
- `ConnectionFactory` использует HikariCP (`HikariJdbcConnector`) и `AuthenticationProviderFactory`, поддерживает `createConnection()`, `testConnection()` и корректно освобождает ресурсы.
- Провайдеры аутентификации: `CredentialsAuthenticationProvider`, `WindowsIntegratedAuthenticationProvider`, `KerberosAuthenticationProvider`; выбор стратегии происходит фабрикой по `authMode`.
- Интеграционный тест `ConnectionFactoryIntegrationTest` проверяет соединение с реальной БД и наличие схемы `ags_test` (использует переменные окружения `FEMSQ_DB_*`).

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
</modules>

<!-- В femsq-backend/pom.xml -->
<modules>
    <module>femsq-database</module>
    <module>femsq-web</module>
</modules>
```

> Примечание: фронтенд (`code/femsq-frontend-q`) собирается отдельно через Vite/Quasar
> и встраивается в Spring Boot артефакт через `frontend-maven-plugin` модуля `femsq-web`.