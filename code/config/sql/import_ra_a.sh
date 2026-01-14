#!/bin/bash
# ============================================================================
# Скрипт импорта данных таблицы ra_a из MS Access в MS SQL Server
# ============================================================================
# Дата: 2026-01-12
# Автор: Александр
# ============================================================================

set -e

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Импорт данных ra_a в SQL Server${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Проверка наличия pyodbc
if ! python3 -c "import pyodbc" 2>/dev/null; then
    echo -e "${RED}✗ pyodbc не установлен${NC}"
    echo -e "${YELLOW}Установка: pip3 install --user pyodbc${NC}"
    echo ""
    read -p "Установить pyodbc сейчас? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pip3 install --user pyodbc
    else
        echo -e "${RED}Импорт невозможен без pyodbc${NC}"
        exit 1
    fi
fi

# Проверка CSV файла
CSV_FILE="/tmp/ra_a_export.csv"
if [ ! -f "$CSV_FILE" ]; then
    echo -e "${RED}✗ CSV файл не найден: $CSV_FILE${NC}"
    echo -e "${YELLOW}Экспорт данных из Access...${NC}"
    mdb-export /home/alex/femsq-test/26-0112_import_Excel/24-1125_ra_R_25-0207.accdb "ra_a" > "$CSV_FILE"
    echo -e "${GREEN}✓ Данные экспортированы${NC}"
fi

echo -e "${YELLOW}Количество записей для импорта: $(( $(wc -l < "$CSV_FILE") - 1 ))${NC}"
echo ""

# Запуск Python скрипта импорта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/03_import_ra_a_data.py"

echo ""
echo -e "${GREEN}✓ Импорт завершён${NC}"
