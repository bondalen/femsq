#!/bin/bash
# Скрипт для запуска unit-тестов
# Использование: ./test-unit.sh [module]
# module: database, web, или все (по умолчанию)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/code/femsq-backend"

MODULE="${1:-all}"

echo "=== Запуск Unit-тестов ==="
echo "Модуль: $MODULE"
echo ""

cd "$BACKEND_DIR"

case "$MODULE" in
    database)
        echo "Запуск unit-тестов модуля femsq-database..."
        mvn test -pl femsq-database
        ;;
    web)
        echo "Запуск unit-тестов модуля femsq-web..."
        mvn test -pl femsq-web
        ;;
    all)
        echo "Запуск всех unit-тестов..."
        mvn test
        ;;
    *)
        echo "Неизвестный модуль: $MODULE"
        echo "Использование: $0 [database|web|all]"
        exit 1
        ;;
esac

echo ""
echo "=== Unit-тесты завершены ==="


