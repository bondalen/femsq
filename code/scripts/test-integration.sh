#!/bin/bash
# Скрипт для запуска integration-тестов
# Требует переменные окружения FEMSQ_DB_*
# Использование: ./test-integration.sh [module]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/code/femsq-backend"

MODULE="${1:-all}"

# Проверка переменных окружения
if [ -z "$FEMSQ_DB_PASSWORD" ]; then
    echo "ОШИБКА: Переменная FEMSQ_DB_PASSWORD не установлена"
    echo "Установите переменные окружения FEMSQ_DB_* перед запуском"
    echo ""
    echo "Пример:"
    echo "  export FEMSQ_DB_PASSWORD=your_password"
    echo "  export FEMSQ_DB_HOST=localhost"
    echo "  export FEMSQ_DB_PORT=1433"
    echo "  export FEMSQ_DB_NAME=FishEye"
    echo "  export FEMSQ_DB_SCHEMA=ags_test"
    echo "  export FEMSQ_DB_USER=sa"
    echo "  export FEMSQ_DB_AUTH_MODE=credentials"
    exit 1
fi

echo "=== Запуск Integration-тестов ==="
echo "Модуль: $MODULE"
echo "БД: ${FEMSQ_DB_HOST:-localhost}:${FEMSQ_DB_PORT:-1433}/${FEMSQ_DB_NAME:-FishEye}/${FEMSQ_DB_SCHEMA:-ags_test}"
echo ""

cd "$BACKEND_DIR"

case "$MODULE" in
    database)
        echo "Запуск integration-тестов модуля femsq-database..."
        mvn verify -Pintegration -pl femsq-database
        ;;
    web)
        echo "Запуск integration-тестов модуля femsq-web..."
        mvn verify -Pintegration -pl femsq-web
        ;;
    all)
        echo "Запуск всех integration-тестов..."
        mvn verify -Pintegration
        ;;
    *)
        echo "Неизвестный модуль: $MODULE"
        echo "Использование: $0 [database|web|all]"
        exit 1
        ;;
esac

echo ""
echo "=== Integration-тесты завершены ==="


