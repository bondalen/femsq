#!/bin/bash
# Скрипт для автоматического увеличения четвёртой цифры версии
# Использование: ./increment-version.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROOT_POM="$PROJECT_ROOT/code/pom.xml"
BACKEND_POM="$PROJECT_ROOT/code/femsq-backend/pom.xml"

if [ ! -f "$ROOT_POM" ]; then
    echo "Error: $ROOT_POM not found"
    exit 1
fi

# Извлекаем текущую версию
CURRENT_VERSION=$(grep -oP '<version>\K[^<]+' "$ROOT_POM" | head -1)
echo "Current version: $CURRENT_VERSION"

# Извлекаем части версии
IFS='.' read -ra VERSION_PARTS <<< "${CURRENT_VERSION%-SNAPSHOT}"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"
BUILD="${VERSION_PARTS[3]:-0}"

# Увеличиваем четвёртую цифру
NEW_BUILD=$((BUILD + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}.${NEW_BUILD}-SNAPSHOT"

echo "New version: $NEW_VERSION"

# Обновляем версию во всех pom.xml файлах проекта
# Обновляем как основную версию, так и версию в секции <parent>
find "$PROJECT_ROOT/code" -name "pom.xml" -type f | while read pom_file; do
    UPDATED=false
    # Обновляем основную версию
    if grep -q "<version>${CURRENT_VERSION}</version>" "$pom_file"; then
        sed -i "s|<version>${CURRENT_VERSION}</version>|<version>${NEW_VERSION}</version>|g" "$pom_file"
        UPDATED=true
    fi
    # Обновляем версию в секции <parent>
    if grep -q "<version>${CURRENT_VERSION}</version>" "$pom_file"; then
        sed -i "s|<version>${CURRENT_VERSION}</version>|<version>${NEW_VERSION}</version>|g" "$pom_file"
        UPDATED=true
    fi
    if [ "$UPDATED" = true ]; then
        echo "Updated $pom_file"
    fi
done

echo "Version incremented successfully: $CURRENT_VERSION -> $NEW_VERSION"
