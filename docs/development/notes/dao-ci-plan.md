**Дата:** 2025-11-10  
**Автор:** Александр  
**Связанные задачи:** task:0003, task:0011, task:0012, task:0013, task:0014, task:0015

## Цели
- Определить, как выполнять интеграционные тесты DAO (og/ogAg) в CI без доступа к продакшн-БД.
- Разделить unit-тесты сервисов и интеграционные тесты DAO по Maven-профилям.
- Подготовить чек-лист переменных окружения и секретов для GitHub Actions.

## Стратегия
1. **Maven профили**  
   - Добавить профиль `ci-unit` (по умолчанию) с запуском `mvn -pl femsq-backend/femsq-database test -DskipITs`.  
   - Добавить профиль `ci-integration` с фазой `verify`, в которой запускаются интеграционные тесты DAO (`*IntegrationTest`). Профиль активируется по флагу `-Pintegration`.
2. **Переменные окружения**  
   - `FEMSQ_DB_HOST`, `FEMSQ_DB_PORT`, `FEMSQ_DB_NAME`, `FEMSQ_DB_USER`, `FEMSQ_DB_PASSWORD`, `FEMSQ_DB_AUTH_MODE`.  
   - В CI секреты хранятся в GitHub Actions (`secrets.FEMSQ_DB_PASSWORD`, `secrets.FEMSQ_DB_USER`).  
   - Для локального запуска предусмотрен скрипт `code/scripts/setup-java-home.sh` и документированная команда из `database-configuration-plan.md`.
3. **GitHub Actions**  
   - Job `build` → `mvn -pl femsq-backend/femsq-database -am -DskipTests compile` (проверка компиляции).  
   - Job `unit-tests` → `mvn -pl femsq-backend/femsq-database -am -Pci-unit test`.  
   - Job `integration-tests` (optional) → запускается вручную (`workflow_dispatch`) или при наличии `secrets.FEMSQ_DB_PASSWORD`; выполняет:
     ```bash
     source code/scripts/setup-java-home.sh
     sqlcmd -S $FEMSQ_DB_HOST,$FEMSQ_DB_PORT -U $FEMSQ_DB_USER -P "$FEMSQ_DB_PASSWORD" -i code/config/sql/ags_test_seed.sql
     mvn -pl femsq-backend/femsq-database -am -Pintegration verify
     ```
4. **Отчётность**  
   - Публиковать журналы Maven (`target/surefire-reports`, `target/failsafe-reports`).  
   - Добавить артефакт с логами SQL-запуска для диагностики.

## Следующие шаги
- Добавить профиль и плагины (Surefire/Failsafe) в `code/femsq-backend/femsq-database/pom.xml`.
- Создать GitHub Actions workflow `.github/workflows/ci-dao.yml` на основе вышеописанного чек-листа.
- Настроить уведомления о падении интеграционных тестов и автоматический перезапуск при временных ошибках БД.
