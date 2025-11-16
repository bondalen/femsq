#!/bin/bash
# Скрипт для установки DBHub локально в проекте
# Использование: ./code/scripts/setup-dbhub.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DBHUB_DIR="$PROJECT_ROOT/.cursor/dbhub"

echo "=== Установка DBHub ==="
echo "Проект: $PROJECT_ROOT"
echo "DBHub директория: $DBHUB_DIR"
echo ""

# Создание директории
if [ ! -d "$DBHUB_DIR" ]; then
    echo "Создание директории .cursor/dbhub..."
    mkdir -p "$DBHUB_DIR"
fi

# Инициализация package.json если нет
if [ ! -f "$DBHUB_DIR/package.json" ]; then
    echo "Инициализация package.json..."
    cd "$DBHUB_DIR"
    npm init -y --silent
    echo "✓ package.json создан"
fi

# Установка DBHub
echo "Установка @bytebase/dbhub..."
cd "$DBHUB_DIR"
npm install @bytebase/dbhub --save --silent

# Проверка установки
if [ -f "$DBHUB_DIR/node_modules/@bytebase/dbhub/dist/index.js" ]; then
    echo "✓ DBHub успешно установлен"
    echo "Путь: $DBHUB_DIR/node_modules/@bytebase/dbhub/dist/index.js"
else
    echo "✗ Ошибка: DBHub не установлен корректно"
    exit 1
fi

echo ""
echo "=== Установка завершена ==="
echo "DBHub готов к использованию в проекте"
