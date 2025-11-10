**Дата:** 2025-11-10  
**Автор:** Александр  
**Связанные задачи:** task:0004, task:0005, task:0006, task:0010

## Цели
- Поддерживать конфигурацию подключения (`DatabaseConfigurationService`) с параметром `authMode` и безопасным хранением секретов.
- Обеспечить устойчивый пул соединений на базе HikariCP (`ConnectionFactory`, `HikariJdbcConnector`).
- Реализовать фабрику аутентификации (`AuthenticationProviderFactory`) и покрыть её тестами, включая интеграционный smoke-тест с реальной БД.

## Реализовано
- `ConfigurationValidator` валидирует `host/port/database`, учетные данные и `authMode` (`credentials`, `windows-integrated`, `kerberos`).
- `ConnectionFactory` использует HikariCP, поддерживает `createConnection()`, `testConnection()` и корректно закрывает пул.
- `AuthenticationProviderFactory` подключает провайдеры `CredentialsAuthenticationProvider`, `WindowsIntegratedAuthenticationProvider`, `KerberosAuthenticationProvider`.
- Интеграционный тест `ConnectionFactoryIntegrationTest` подключается к `FishEye`/`ags_test`, используя переменные окружения `FEMSQ_DB_*`.

## Настройки окружения
- Обязательная переменная: `FEMSQ_DB_PASSWORD` (не хранить в репозитории, заводить через `export` / менеджер секретов).
- Дополнительные (с дефолтами):  
  `FEMSQ_DB_HOST=localhost`, `FEMSQ_DB_PORT=1433`, `FEMSQ_DB_NAME=FishEye`, `FEMSQ_DB_USER=sa`, `FEMSQ_DB_AUTH_MODE=credentials`.

## Следующие шаги
1. **MS SQL Driver / Health**  
   - Подготовить profile для интеграционных тестов (разделить unit и integration).  
   - Добавить smoke-команду в CI (GitHub Actions) для запуска `mvn test` при наличии секретов.
2. **DAO / Data Access (task:0003)**  
   - Спроектировать слой доступа к данным (интерфейсы репозиториев, transaction scope).  
   - Определить минимальные таблицы/процедуры для начального функционала.  
   - Подготовить миграции (через Liquibase или SQL-скрипты) для схем `FishEye` и `ags_test`.
3. **Web API подготовка (task:0007)**  
   - Определить REST/GraphQL endpoint для проверки соединения.  
   - Продумать передачу конфигурации с UI (будущий Vue мастер настройки).

## Проверка
- Команда `source ~/.bashrc && mvn -f code/pom.xml -pl femsq-backend/femsq-database -am test` — выполняет unit и интеграционные тесты (`29 tests`).
