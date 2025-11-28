#!/bin/bash
# Скрипт для сравнения библиотек и определения изменений
# Использование: ./compare-libs.sh <old-lib-dir> <new-lib-dir> [lib-manifest.json]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

OLD_DIR="${1:-}"
NEW_DIR="${2:-}"
MANIFEST="${3:-}"

if [ -z "$OLD_DIR" ] || [ -z "$NEW_DIR" ]; then
    echo -e "${RED}Использование: $0 <old-lib-dir> <new-lib-dir> [lib-manifest.json]${NC}"
    exit 1
fi

echo -e "${GREEN}=== Сравнение библиотек ===${NC}"
echo "Старая директория: $OLD_DIR"
echo "Новая директория: $NEW_DIR"
echo ""

# Создаём временные файлы со списками библиотек
OLD_LIST=$(mktemp)
NEW_LIST=$(mktemp)

if [ -d "$OLD_DIR" ]; then
    ls -1 "$OLD_DIR"/*.jar 2>/dev/null | xargs -n1 basename | sort > "$OLD_LIST" || touch "$OLD_LIST"
else
    echo -e "${YELLOW}Предупреждение: Старая директория не найдена: $OLD_DIR${NC}"
    touch "$OLD_LIST"
fi

if [ -d "$NEW_DIR" ]; then
    ls -1 "$NEW_DIR"/*.jar 2>/dev/null | xargs -n1 basename | sort > "$NEW_LIST" || touch "$NEW_LIST"
else
    echo -e "${RED}ERROR: Новая директория не найдена: $NEW_DIR${NC}"
    exit 1
fi

OLD_COUNT=$(wc -l < "$OLD_LIST" | tr -d ' ')
NEW_COUNT=$(wc -l < "$NEW_LIST" | tr -d ' ')

echo -e "${BLUE}Старых библиотек: $OLD_COUNT${NC}"
echo -e "${BLUE}Новых библиотек: $NEW_COUNT${NC}"
echo ""

# Находим новые библиотеки (есть в новом, нет в старом)
echo -e "${GREEN}=== БИБЛИОТЕКИ ДЛЯ ДОБАВЛЕНИЯ ===${NC}"
NEW_LIBS=$(comm -13 "$OLD_LIST" "$NEW_LIST")
if [ -z "$NEW_LIBS" ]; then
    echo "Нет новых библиотек"
else
    echo "$NEW_LIBS" | while read lib; do
        echo -e "${GREEN}+ $lib${NC}"
    done
fi
echo ""

# Находим удалённые библиотеки (есть в старом, нет в новом)
echo -e "${RED}=== БИБЛИОТЕКИ ДЛЯ УДАЛЕНИЯ ===${NC}"
REMOVED_LIBS=$(comm -23 "$OLD_LIST" "$NEW_LIST")
if [ -z "$REMOVED_LIBS" ]; then
    echo "Нет удалённых библиотек"
else
    echo "$REMOVED_LIBS" | while read lib; do
        echo -e "${RED}- $lib${NC}"
    done
fi
echo ""

# Находим обновлённые библиотеки (есть в обоих, но версии могут отличаться)
echo -e "${YELLOW}=== БИБЛИОТЕКИ ДЛЯ ПРОВЕРКИ ВЕРСИЙ ===${NC}"
COMMON_LIBS=$(comm -12 "$OLD_LIST" "$NEW_LIST")
if [ -z "$COMMON_LIBS" ]; then
    echo "Нет общих библиотек для проверки"
else
    echo "$COMMON_LIBS" | while read lib; do
        # Извлекаем имя без версии для сравнения
        BASE_NAME=$(echo "$lib" | sed -E 's/-[0-9].*\.jar$//' | sed -E 's/\.jar$//')
        OLD_VER=$(echo "$lib" | grep -oE '[0-9]+\.[0-9]+[^.]*' | head -1 || echo "unknown")
        NEW_VER=$(grep "^$BASE_NAME" "$NEW_LIST" | grep -oE '[0-9]+\.[0-9]+[^.]*' | head -1 || echo "unknown")
        
        if [ "$OLD_VER" != "$NEW_VER" ] && [ "$OLD_VER" != "unknown" ] && [ "$NEW_VER" != "unknown" ]; then
            echo -e "${YELLOW}~ $BASE_NAME: $OLD_VER → $NEW_VER${NC}"
        fi
    done
fi

# Если указан manifest, показываем требуемые библиотеки
if [ -n "$MANIFEST" ] && [ -f "$MANIFEST" ]; then
    echo ""
    echo -e "${BLUE}=== БИБЛИОТЕКИ ИЗ MANIFEST (обязательные) ===${NC}"
    REQUIRED=$(grep -A1 '"required" : true' "$MANIFEST" | grep '"filename"' | sed 's/.*"filename" : "\(.*\)".*/\1/' | tr -d ',' | tr -d ' ')
    if [ -n "$REQUIRED" ]; then
        echo "$REQUIRED" | while read lib; do
            if [ -f "$NEW_DIR/$lib" ]; then
                echo -e "${GREEN}✓ $lib${NC}"
            else
                echo -e "${RED}✗ $lib (ОТСУТСТВУЕТ!)${NC}"
            fi
        done
    fi
fi

# Удаляем временные файлы
rm -f "$OLD_LIST" "$NEW_LIST"

echo ""
echo -e "${GREEN}=== ИТОГО ===${NC}"
NEW_COUNT=$(echo "$NEW_LIBS" | grep -c . || echo "0")
REMOVED_COUNT=$(echo "$REMOVED_LIBS" | grep -c . || echo "0")
echo "Добавить: $NEW_COUNT"
echo "Удалить: $REMOVED_COUNT"
echo "Проверить версии: $(echo "$COMMON_LIBS" | wc -l | tr -d ' ')"