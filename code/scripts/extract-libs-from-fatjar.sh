#!/bin/bash
# Скрипт для извлечения библиотек из существующего Fat JAR
# Запускается ОДИН РАЗ на машине пользователя

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FEMSQ: Извлечение библиотек из Fat JAR ===${NC}"

# Параметры
FAT_JAR="${1:-femsq-web-0.1.0.1-SNAPSHOT.jar}"
TARGET_DIR="${2:-.}"

# Проверка существования JAR
if [ ! -f "$FAT_JAR" ]; then
    echo "ERROR: JAR файл не найден: $FAT_JAR"
    echo "Использование: $0 <fat-jar-path> [target-directory]"
    exit 1
fi

echo "Fat JAR: $FAT_JAR"
echo "Целевая директория: $TARGET_DIR"

# Создаём директорию для библиотек
LIB_DIR="$TARGET_DIR/lib"
echo -e "\n${YELLOW}Создаём директорию $LIB_DIR...${NC}"
mkdir -p "$LIB_DIR"

# Извлекаем библиотеки
echo -e "${YELLOW}Извлекаем библиотеки из BOOT-INF/lib/...${NC}"
unzip -q "$FAT_JAR" 'BOOT-INF/lib/*' -d "$TARGET_DIR/temp-extract"

# Перемещаем библиотеки в lib/
echo -e "${YELLOW}Перемещаем библиотеки...${NC}"
mv "$TARGET_DIR/temp-extract/BOOT-INF/lib/"*.jar "$LIB_DIR/"

# Удаляём временную директорию
rm -rf "$TARGET_DIR/temp-extract"

# Подсчитываем результат
LIB_COUNT=$(ls -1 "$LIB_DIR"/*.jar 2>/dev/null | wc -l)
LIB_SIZE=$(du -sh "$LIB_DIR" | cut -f1)

echo -e "\n${GREEN}✓ Извлечение завершено!${NC}"
echo "  Библиотек извлечено: $LIB_COUNT"
echo "  Размер lib/: $LIB_SIZE"
echo "  Директория: $LIB_DIR"

echo -e "\n${YELLOW}Теперь можно использовать Thin JAR для обновлений!${NC}"
echo "Следующие обновления будут весить ~1.5 МБ вместо 51 МБ"
