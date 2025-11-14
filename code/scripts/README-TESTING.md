# Инструкция по запуску тестов FEMSQ

## Быстрый старт

### Unit-тесты (быстро, не требует БД)
```bash
./code/scripts/test-unit.sh
```

### Integration-тесты (требует БД)
```bash
# Убедитесь, что переменные FEMSQ_DB_* установлены
source ~/.bashrc
./code/scripts/test-integration.sh
```

### Все тесты
```bash
./code/scripts/test-all.sh
```

### E2E-тесты (требует запущенный backend)
```bash
./code/scripts/test-e2e.sh
```

## Maven команды

### Unit-тесты
```bash
cd code/femsq-backend
mvn test                    # Все модули
mvn test -pl femsq-web      # Только web модуль
mvn test -pl femsq-database # Только database модуль
```

### Integration-тесты
```bash
cd code/femsq-backend
mvn verify -Pintegration                    # Все модули
mvn verify -Pintegration -pl femsq-web     # Только web модуль
mvn verify -Pintegration -pl femsq-database # Только database модуль
```

### Все тесты с покрытием кода
```bash
cd code/femsq-backend
mvn test -Pci  # Unit-тесты + отчет о покрытии
```

## Переменные окружения для Integration-тестов

```bash
export FEMSQ_DB_HOST=localhost
export FEMSQ_DB_PORT=1433
export FEMSQ_DB_NAME=FishEye
export FEMSQ_DB_SCHEMA=ags_test
export FEMSQ_DB_USER=sa
export FEMSQ_DB_PASSWORD=your_password
export FEMSQ_DB_AUTH_MODE=credentials
```

Или добавьте их в `~/.bashrc` для постоянного использования.

## Когда запускать какие тесты

### При разработке (локально)
- **Unit-тесты**: автоматически при `mvn test` (быстро, < 1 мин)
- **Integration-тесты**: вручную при изменении кода, связанного с БД

### Перед коммитом
- **Unit-тесты**: обязательно
- **Integration-тесты**: опционально (если изменен код БД)

### Перед созданием PR
- **Unit-тесты**: обязательно
- **Integration-тесты**: рекомендуется (если изменен код БД)

### При merge в main
- **Все тесты**: автоматически в CI/CD

## Структура тестов

### Unit-тесты (`*Test.java`)
- Быстрые (< 1 секунды каждый)
- Без внешних зависимостей
- Используют моки
- Запускаются: `mvn test`

### Integration-тесты (`*IT.java`, `*IntegrationTest.java`)
- Требуют реальную БД
- Требуют переменные `FEMSQ_DB_*`
- Запускаются: `mvn verify -Pintegration`

### E2E-тесты (Playwright)
- Требуют запущенный backend
- Проверяют UI через браузер
- Запускаются: `npm run test:e2e` в `code/femsq-frontend`

## Отчеты о покрытии кода

После запуска тестов с профилем `ci`:
```bash
mvn test -Pci
```

Отчеты доступны в:
- `code/femsq-backend/femsq-database/target/site/jacoco/index.html`
- `code/femsq-backend/femsq-web/target/site/jacoco/index.html`

## CI/CD

Тесты автоматически запускаются в GitHub Actions:
- **При каждом PR**: unit-тесты
- **При merge в main**: все тесты + покрытие кода
- **По требованию**: можно запустить integration/E2E тесты через специальные теги в коммите

### Запуск integration-тестов в CI
Добавьте `[test-integration]` в сообщение коммита или название PR.

### Запуск E2E-тестов в CI
Добавьте `[test-e2e]` в сообщение коммита.

## Устранение проблем

### Unit-тесты не запускаются
- Проверьте, что все модули собраны: `mvn clean install -DskipTests`
- Проверьте версию Java: должна быть 21

### Integration-тесты не запускаются
- Проверьте переменные окружения: `env | grep FEMSQ_DB`
- Проверьте доступность БД: `sqlcmd -S localhost,1433 -U sa -P $FEMSQ_DB_PASSWORD -Q "SELECT 1"`
- Проверьте, что seed-скрипт выполнен: `./code/scripts/seedTestData.sh`

### E2E-тесты не запускаются
- Проверьте, что backend запущен: `curl http://localhost:8080/api/v1/connection/status`
- Проверьте установку Playwright: `npx playwright --version`
- Установите браузеры: `npx playwright install`


