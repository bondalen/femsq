#!/bin/bash
# Скрипт запуска приложения с внешними библиотеками
# Использование: ./run-with-external-libs.sh [thin-jar-path] [lib-dir]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== FEMSQ: Запуск с внешними библиотеками ===${NC}"

# Параметры
THIN_JAR="${1:-femsq-web-0.1.0.1-SNAPSHOT-thin.jar}"
LIB_DIR="${2:-./lib}"

# Проверки
if [ ! -f "$THIN_JAR" ]; then
    echo -e "${RED}ERROR: JAR файл не найден: $THIN_JAR${NC}"
    exit 1
fi

if [ ! -d "$LIB_DIR" ]; then
    echo -e "${RED}ERROR: Директория lib не найдена: $LIB_DIR${NC}"
    echo "Запустите сначала: ./extract-libs-from-fatjar.sh"
    exit 1
fi

# Подсчитываем библиотеки
LIB_COUNT=$(ls -1 "$LIB_DIR"/*.jar 2>/dev/null | wc -l)
if [ "$LIB_COUNT" -eq 0 ]; then
    echo -e "${RED}ERROR: В $LIB_DIR нет JAR файлов${NC}"
    exit 1
fi

echo "Thin JAR: $THIN_JAR"
echo "Библиотеки: $LIB_DIR ($LIB_COUNT файлов)"
echo ""

# Запуск
echo -e "${YELLOW}Запуск приложения...${NC}"
java -Dloader.path="$LIB_DIR" -jar "$THIN_JAR"
