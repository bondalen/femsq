#!/bin/bash
# Скрипт для запуска E2E-тестов (Playwright)
# Требует запущенный backend на http://localhost:8080
# Использование: ./test-e2e.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/code/femsq-frontend-q"

echo "=== Запуск E2E-тестов ==="
echo ""

# Проверка, что backend запущен
if ! curl -s http://localhost:8080/api/v1/connection/status > /dev/null 2>&1; then
    echo "ОШИБКА: Backend не запущен на http://localhost:8080"
    echo "Запустите backend перед выполнением E2E-тестов:"
    echo "  cd code/femsq-backend/femsq-web"
    echo "  mvn spring-boot:run"
    exit 1
fi

cd "$FRONTEND_DIR"

# Проверка установки Playwright
if [ ! -d "node_modules/@playwright" ]; then
    echo "Установка зависимостей..."
    npm install
    echo "Установка браузеров Playwright..."
    npx playwright install
fi

echo "Запуск E2E-тестов..."
npm run test:e2e

echo ""
echo "=== E2E-тесты завершены ==="


