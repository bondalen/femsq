**Дата:** 2025-11-10  
**Автор:** Александр  
**Связанные задачи:** task:0003, task:0004, task:0005, task:0006, task:0010

## Цели
- Работать с уже существующей БД `FishEye` (схема `ags`) без изменения production-структуры; все изменения схем выполняет DBA.
- Поддерживать конфигурацию подключения (`DatabaseConfigurationService`) с параметром `authMode` и безопасным хранением секретов.
- Обеспечить устойчивый пул соединений на базе HikariCP (`ConnectionFactory`, `HikariJdbcConnector`).
- Реализовать фабрику аутентификации (`AuthenticationProviderFactory`) и покрыть её тестами, включая интеграционный smoke-тест с реальной БД.

## Реализовано
- `ConfigurationValidator` валидирует `host/port/database`, учетные данные и `authMode` (`credentials`, `windows-integrated`, `kerberos`).
- `ConnectionFactory` использует HikariCP, поддерживает `createConnection()`, `testConnection()` и корректно закрывает пул.
- `AuthenticationProviderFactory` подключает провайдеры `CredentialsAuthenticationProvider`, `WindowsIntegratedAuthenticationProvider`, `KerberosAuthenticationProvider`.
- Интеграционный тест `ConnectionFactoryIntegrationTest` подключается к `FishEye`/`ags_test`, используя переменные окружения `FEMSQ_DB_*` и подтверждает наличие схемы `ags_test`.

## Настройки окружения
- Обязательная переменная: `FEMSQ_DB_PASSWORD` (не хранить в репозитории, заводить через `export` / менеджер секретов).
- Дополнительные (с дефолтами):  
  `FEMSQ_DB_HOST=localhost`, `FEMSQ_DB_PORT=1433`, `FEMSQ_DB_NAME=FishEye`, `FEMSQ_DB_USER=sa`, `FEMSQ_DB_AUTH_MODE=credentials`.
- Тестовая схема: `ags_test`. В ней создаются копии production-таблиц (`og`, `ogAg`) для интеграционных тестов и наполняются фиктивными данными (см. скрипт `code/config/sql/ags_test_seed.sql`).

## Тестовые данные
- Запуск скрипта наполнения:  
  `source ~/.bashrc && /opt/mssql-tools/bin/sqlcmd -S localhost,1433 -U ${FEMSQ_DB_USER:-sa} -P "$FEMSQ_DB_PASSWORD" -i code/config/sql/ags_test_seed.sql`
- Скрипт безопасно пере-создаёт таблицы `ags_test.og` и `ags_test.ogAg`, выполняет вставку тестовых организаций («Рога, ООО», «Рога и копыта, АО», «Копыта и хвосты, ИП») и агентов (`001`, `002`, `003`).

## Следующие шаги
1. **Health-check и CI**  
   - Подготовить Maven profile для разделения unit/integration тестов.  
   - Добавить smoke-команду в CI (GitHub Actions) для запуска `mvn -P integration test` при наличии секретов и доступной БД.
2. **DAO / Data Access (task:0003)**  
   - Спроектировать слой доступа к данным (интерфейсы/реализации DAO для `og` и `ogAg`).  
   - Подготовить SQL-скрипты создания таблиц и тестовых данных в `ags_test`.  
   - Реализовать CRUD-методы и интеграционные тесты, используя тестовую схему.
3. **Web API подготовка (task:0007)**  
   - Определить REST/GraphQL endpoint для health-check подключения.  
   - Продумать передачу результатов подключения в UI (будущий Vue мастер настройки).

## Проверка
- Команда `source ~/.bashrc && mvn -f code/pom.xml -pl femsq-backend/femsq-database -am test` — выполняет unit и интеграционные тесты (`29 tests`).
