#!/bin/bash
# Скрипт для извлечения всех библиотек femsq-* из fat JAR
# Использование: ./extract-femsq-libs.sh [fat-jar-path] [output-dir]
#
# Извлекает все библиотеки femsq-*.jar из fat JAR для обновления на машине пользователя

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Параметры
FAT_JAR="${1:-$PROJECT_ROOT/femsq-backend/femsq-web/target/femsq-web-*-SNAPSHOT.jar}"
OUTPUT_DIR="${2:-$PROJECT_ROOT/femsq-backend/femsq-web/target/extracted-femsq-libs}"

# Находим актуальный fat JAR (исключаем thin и original)
FAT_JAR=$(ls -1 $FAT_JAR 2>/dev/null | grep -v thin | grep -v original | head -1)

if [ -z "$FAT_JAR" ] || [ ! -f "$FAT_JAR" ]; then
    echo -e "${RED}Error: Fat JAR not found: $FAT_JAR${NC}"
    echo "Usage: $0 [fat-jar-path] [output-dir]"
    exit 1
fi

echo -e "${GREEN}=== Извлечение библиотек femsq-* из Fat JAR ===${NC}"
echo "Fat JAR: $FAT_JAR"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Создаём выходную директорию
mkdir -p "$OUTPUT_DIR"

# Извлекаем все библиотеки femsq-*.jar
echo -e "${YELLOW}Извлечение библиотек femsq-*...${NC}"
unzip -j "$FAT_JAR" "BOOT-INF/lib/femsq-*.jar" -d "$OUTPUT_DIR" 2>&1 | grep -v "inflating:" || true

# Проверяем результат
EXTRACTED_JARS=$(ls -1 "$OUTPUT_DIR"/femsq-*.jar 2>/dev/null)

if [ -z "$EXTRACTED_JARS" ]; then
    echo -e "${RED}⚠ Библиотеки femsq-* не найдены в Fat JAR${NC}"
    echo "Проверьте содержимое Fat JAR:"
    unzip -l "$FAT_JAR" | grep "BOOT-INF/lib/femsq" | head -5
    exit 1
fi

# Выводим список извлечённых библиотек
echo -e "${GREEN}✓ Успешно извлечены библиотеки:${NC}"
echo ""
JAR_COUNT=0
for JAR in $EXTRACTED_JARS; do
    JAR_NAME=$(basename "$JAR")
    JAR_SIZE=$(du -h "$JAR" | cut -f1)
    echo -e "  ${GREEN}✓${NC} $JAR_NAME (${JAR_SIZE})"
    JAR_COUNT=$((JAR_COUNT + 1))
done

echo ""
echo -e "${YELLOW}Всего извлечено: $JAR_COUNT библиотек${NC}"
echo ""
echo -e "${YELLOW}Инструкции по обновлению на машине пользователя:${NC}"
echo "1. Скопируйте все извлечённые JAR файлы в папку lib/ на Windows машине"
echo "2. Замените старые версии библиотек femsq-*"
echo "3. Убедитесь, что версии совпадают с версией тонкого JAR"
echo ""
echo "Пример:"
echo "  cp $OUTPUT_DIR/femsq-*.jar /path/to/windows/machine/lib/"
echo ""
