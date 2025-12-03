#!/bin/bash
# Скрипт для извлечения femsq-reports JAR из fat JAR
# Использование: ./extract-femsq-reports.sh [fat-jar-path] [output-dir]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Параметры
FAT_JAR="${1:-$PROJECT_ROOT/femsq-backend/femsq-web/target/femsq-web-*-SNAPSHOT.jar}"
OUTPUT_DIR="${2:-$PROJECT_ROOT/femsq-backend/femsq-web/target/extracted-libs}"

# Находим актуальный fat JAR (исключаем thin и original)
FAT_JAR=$(ls -1 $FAT_JAR 2>/dev/null | grep -v thin | grep -v original | head -1)

if [ -z "$FAT_JAR" ] || [ ! -f "$FAT_JAR" ]; then
    echo "Error: Fat JAR not found: $FAT_JAR"
    echo "Usage: $0 [fat-jar-path] [output-dir]"
    exit 1
fi

echo -e "${GREEN}=== Извлечение femsq-reports из Fat JAR ===${NC}"
echo "Fat JAR: $FAT_JAR"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Создаём выходную директорию
mkdir -p "$OUTPUT_DIR"

# Извлекаем femsq-reports JAR
echo -e "${YELLOW}Извлечение femsq-reports JAR...${NC}"
unzip -j "$FAT_JAR" "BOOT-INF/lib/femsq-reports-*.jar" -d "$OUTPUT_DIR" 2>&1 | grep -v "inflating:" || true

# Проверяем результат
EXTRACTED_JAR=$(ls -1 "$OUTPUT_DIR"/femsq-reports-*.jar 2>/dev/null | head -1)

if [ -n "$EXTRACTED_JAR" ]; then
    echo -e "${GREEN}✓ Успешно извлечён: $(basename "$EXTRACTED_JAR")${NC}"
    echo "  Размер: $(du -h "$EXTRACTED_JAR" | cut -f1)"
    echo "  Путь: $EXTRACTED_JAR"
    echo ""
    echo "Скопируйте этот JAR в папку lib/ на Windows машине, заменив старый femsq-reports-0.1.0.1-SNAPSHOT.jar"
else
    echo -e "${YELLOW}⚠ femsq-reports JAR не найден в Fat JAR${NC}"
    echo "Проверьте содержимое Fat JAR:"
    unzip -l "$FAT_JAR" | grep "femsq-reports" | head -5
    exit 1
fi
