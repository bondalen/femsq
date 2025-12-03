#!/bin/bash
# Скрипт для извлечения femsq-reports JAR из fat JAR
# Использование: ./extract-femsq-reports-jar.sh [version]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Определяем версию
if [ -n "$1" ]; then
    VERSION="$1"
else
    # Извлекаем версию из pom.xml
    VERSION=$(grep -oP '<version>\K[^<]+' "$CODE_ROOT/pom.xml" | head -1 | sed 's/-SNAPSHOT//')
fi

FAT_JAR="$CODE_ROOT/femsq-backend/femsq-web/target/femsq-web-${VERSION}-SNAPSHOT.jar"
REPORTS_JAR_NAME="femsq-reports-${VERSION}-SNAPSHOT.jar"
OUTPUT_DIR="$CODE_ROOT/femsq-backend/femsq-web/target/extracted-libs"
OUTPUT_FILE="$OUTPUT_DIR/$REPORTS_JAR_NAME"

if [ ! -f "$FAT_JAR" ]; then
    echo "Error: Fat JAR not found: $FAT_JAR"
    exit 1
fi

echo -e "${GREEN}=== Извлечение femsq-reports JAR ===${NC}"
echo "Fat JAR: $FAT_JAR"
echo "Version: $VERSION"
echo ""

# Создаём выходную директорию
mkdir -p "$OUTPUT_DIR"

# Извлекаем femsq-reports JAR из fat JAR
echo -e "${YELLOW}Извлечение $REPORTS_JAR_NAME...${NC}"
unzip -j "$FAT_JAR" "BOOT-INF/lib/$REPORTS_JAR_NAME" -d "$OUTPUT_DIR" 2>&1 | grep -v "inflating" || true

if [ -f "$OUTPUT_FILE" ]; then
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo -e "${GREEN}✓ Успешно извлечён: $OUTPUT_FILE ($SIZE)${NC}"
    echo ""
    echo "Скопируйте этот файл в lib/ на машине Windows:"
    echo "  cp $OUTPUT_FILE /path/to/windows/lib/"
else
    echo -e "${YELLOW}Ошибка: Файл не найден после извлечения${NC}"
    echo "Проверьте, что в fat JAR есть: BOOT-INF/lib/$REPORTS_JAR_NAME"
    exit 1
fi
