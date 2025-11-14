#!/bin/bash
# Скрипт для запуска всех тестов (unit + integration)
# Требует переменные окружения FEMSQ_DB_* для integration-тестов
# Использование: ./test-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/code/femsq-backend"

echo "=== Запуск всех тестов ==="
echo ""

cd "$BACKEND_DIR"

# Шаг 1: Unit-тесты (быстро, не требует БД)
echo "=== Шаг 1: Unit-тесты ==="
mvn test
echo ""

# Шаг 2: Integration-тесты (требует БД)
if [ -n "$FEMSQ_DB_PASSWORD" ]; then
    echo "=== Шаг 2: Integration-тесты ==="
    echo "БД: ${FEMSQ_DB_HOST:-localhost}:${FEMSQ_DB_PORT:-1433}/${FEMSQ_DB_NAME:-FishEye}/${FEMSQ_DB_SCHEMA:-ags_test}"
    mvn verify -Pintegration
    echo ""
else
    echo "=== Шаг 2: Integration-тесты пропущены ==="
    echo "Переменная FEMSQ_DB_PASSWORD не установлена"
    echo "Для запуска integration-тестов установите переменные FEMSQ_DB_*"
    echo ""
fi

echo "=== Все тесты завершены ==="


