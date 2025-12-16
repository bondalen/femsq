#!/bin/bash

# =============================================
# Скрипт выполнения процедуры spMstrg_2408_SaveToTables
# через sqlcmd с таймаутом 10 минут (600 секунд)
# Создано: 2025-12-04
# =============================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Параметры подключения к БД
DB_SERVER="localhost"
DB_PORT="1433"
DB_NAME="FishEye"
DB_USER="sa"
DB_PASSWORD="kolob_OK1"

# Параметры процедуры
IPGCH=15
MONTH_END_DATE="2025-07-31"

# Таймаут в секундах (10 минут)
TIMEOUT=600

# Путь к SQL-скрипту
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_SCRIPT="${SCRIPT_DIR}/spMstrg_2408_SaveToTables.sql"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}Выполнение процедуры spMstrg_2408_SaveToTables${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Проверка наличия sqlcmd
if ! command -v sqlcmd &> /dev/null; then
    echo -e "${RED}ОШИБКА: sqlcmd не найден в системе${NC}"
    echo "Установите MS SQL Server Command Line Tools"
    exit 1
fi

echo -e "${GREEN}✓ sqlcmd найден: $(which sqlcmd)${NC}"
echo ""

# Проверка наличия SQL-скрипта
if [ ! -f "$SQL_SCRIPT" ]; then
    echo -e "${RED}ОШИБКА: SQL-скрипт не найден: $SQL_SCRIPT${NC}"
    exit 1
fi

echo -e "${GREEN}✓ SQL-скрипт найден: $SQL_SCRIPT${NC}"
echo ""

# Шаг 1: Создание модифицированной процедуры
echo -e "${YELLOW}Шаг 1: Создание модифицированной процедуры...${NC}"
echo "Подключение: $DB_SERVER:$DB_PORT/$DB_NAME"
echo ""

/opt/mssql-tools/bin/sqlcmd \
    -S "$DB_SERVER,$DB_PORT" \
    -d "$DB_NAME" \
    -U "$DB_USER" \
    -P "$DB_PASSWORD" \
    -i "$SQL_SCRIPT" \
    -t $TIMEOUT

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Процедура успешно создана${NC}"
    echo ""
else
    echo -e "${RED}✗ Ошибка при создании процедуры${NC}"
    exit 1
fi

# Шаг 2: Выполнение процедуры с сохранением результатов
echo -e "${YELLOW}Шаг 2: Выполнение процедуры с параметрами...${NC}"
echo "Параметры: @ipgCh = $IPGCH, @MounthEndDate = '$MONTH_END_DATE'"
echo "Таймаут: $TIMEOUT секунд ($(($TIMEOUT / 60)) минут)"
echo ""

START_TIME=$(date +%s)

/opt/mssql-tools/bin/sqlcmd \
    -S "$DB_SERVER,$DB_PORT" \
    -d "$DB_NAME" \
    -U "$DB_USER" \
    -P "$DB_PASSWORD" \
    -Q "EXEC ags.spMstrg_2408_SaveToTables @ipgCh = $IPGCH, @MounthEndDate = '$MONTH_END_DATE';" \
    -t $TIMEOUT

SQLCMD_EXIT_CODE=$?
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
ELAPSED_MINUTES=$((ELAPSED_TIME / 60))
ELAPSED_SECONDS=$((ELAPSED_TIME % 60))

echo ""

if [ $SQLCMD_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Процедура успешно выполнена${NC}"
    echo "Время выполнения: ${ELAPSED_MINUTES}м ${ELAPSED_SECONDS}с"
    echo ""
    
    # Шаг 3: Проверка результатов
    echo -e "${YELLOW}Шаг 3: Проверка результатов в таблицах...${NC}"
    echo ""
    
    /opt/mssql-tools/bin/sqlcmd \
        -S "$DB_SERVER,$DB_PORT" \
        -d "$DB_NAME" \
        -U "$DB_USER" \
        -P "$DB_PASSWORD" \
        -Q "SELECT 
            TABLE_NAME, 
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet1) AS RS1_Count,
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet2) AS RS2_Count,
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet3) AS RS3_Count,
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet4) AS RS4_Count,
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet5) AS RS5_Count,
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet6) AS RS6_Count
        FROM (SELECT 'Результаты' AS TABLE_NAME) t;" \
        -h-1
    
    echo ""
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}Выполнение завершено успешно${NC}"
    echo -e "${GREEN}=============================================${NC}"
    exit 0
else
    echo -e "${RED}✗ Ошибка при выполнении процедуры${NC}"
    echo "Код ошибки: $SQLCMD_EXIT_CODE"
    echo "Время выполнения до ошибки: ${ELAPSED_MINUTES}м ${ELAPSED_SECONDS}с"
    exit 1
fi
