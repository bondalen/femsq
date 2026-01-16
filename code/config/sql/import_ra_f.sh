#!/bin/bash
# ============================================================================
# Скрипт импорта данных таблиц ra_f, ra_ft_st, ra_ft_s, ra_ft_sn из MS Access в MS SQL Server
# ============================================================================
# Дата: 2026-01-15
# Автор: Александр
# ============================================================================

set -e

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Импорт данных файлов ревизий в SQL Server${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Путь к файлу базы данных MS Access
ACCESS_DB="${ACCESS_DB:-/home/alex/femsq-test/26-0112_import_Excel/24-1125_ra_R_25-0207.accdb}"

# Пути к CSV файлам
CSV_RA_F="/tmp/ra_f_export.csv"
CSV_RA_FT_ST="/tmp/ra_ft_st_export.csv"
CSV_RA_FT_S="/tmp/ra_ft_s_export.csv"
CSV_RA_FT_SN="/tmp/ra_ft_sn_export.csv"

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

# Проверка наличия mdb-export (mdb-tools)
if ! command -v mdb-export &> /dev/null; then
    echo -e "${RED}✗ mdb-export не найден${NC}"
    echo -e "${YELLOW}Установка: sudo apt-get install mdbtools (Ubuntu/Debian)${NC}"
    echo -e "${YELLOW}           или: brew install mdbtools (macOS)${NC}"
    exit 1
fi

# Функция экспорта таблицы из Access
export_table() {
    local table_name=$1
    local csv_file=$2
    
    if [ -f "$csv_file" ]; then
        echo -e "${BLUE}ℹ CSV файл уже существует: $csv_file${NC}"
        read -p "Перезаписать? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}✓ Используется существующий файл${NC}"
            return 0
        fi
    fi
    
    if [ ! -f "$ACCESS_DB" ]; then
        echo -e "${RED}✗ Файл базы данных не найден: $ACCESS_DB${NC}"
        echo -e "${YELLOW}Укажите путь к файлу Access через переменную ACCESS_DB${NC}"
        echo -e "${YELLOW}Пример: ACCESS_DB=/path/to/database.accdb $0${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Экспорт таблицы $table_name...${NC}"
    if mdb-export "$ACCESS_DB" "$table_name" > "$csv_file" 2>/dev/null; then
        echo -e "${GREEN}✓ Данные экспортированы в $csv_file${NC}"
        return 0
    else
        echo -e "${RED}✗ Ошибка экспорта таблицы $table_name${NC}"
        return 1
    fi
}

# Экспорт таблиц из Access
echo -e "${YELLOW}Экспорт данных из MS Access...${NC}"
echo ""

export_table "ra_ft_st" "$CSV_RA_FT_ST"
export_table "ra_ft_s" "$CSV_RA_FT_S"
export_table "ra_ft_sn" "$CSV_RA_FT_SN"
export_table "ra_f" "$CSV_RA_F"

echo ""

# Подсчет записей для импорта
echo -e "${YELLOW}Количество записей для импорта:${NC}"
for csv_file in "$CSV_RA_FT_ST" "$CSV_RA_FT_S" "$CSV_RA_FT_SN" "$CSV_RA_F"; do
    if [ -f "$csv_file" ]; then
        count=$(( $(wc -l < "$csv_file") - 1 ))
        if [ $count -gt 0 ]; then
            echo -e "  ${BLUE}$(basename $csv_file):${NC} $count записей"
        fi
    fi
done
echo ""

# Запуск Python скрипта импорта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${YELLOW}Запуск импорта...${NC}"
echo ""
python3 "$SCRIPT_DIR/05_import_ra_f_data.py"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Импорт завершён успешно${NC}"
else
    echo ""
    echo -e "${RED}✗ Ошибка при импорте${NC}"
    exit 1
fi
