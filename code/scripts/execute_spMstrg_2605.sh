#!/bin/bash

# =============================================
# Скрипт выполнения процедуры spMstrg_2605
# через sqlcmd с таймаутом 10 минут (600 секунд)
#
# Замена execute_spMstrg_2408.sh:
#   - Вызывает ags.spMstrg_2605 вместо ags.spMstrg_2408_SaveToTables
#   - Параметры: @ipgCh, @MounthEndDate, @ipgSt (NULL = все стройки), @saveToTables = 1
#   - Результат: заполняет те же таблицы ags.spMstrg_2408_ResultSet1..7
#   - Шаг создания процедуры убран: spMstrg_2605 создаётся из
#     docs/development/notes/sql/26-0508/03_CREATE_PROCEDURE_spMstrg_2605.sql
# Создано: 2026-05-16
# =============================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Имя Docker-контейнера с SQL Server
CONTAINER="femsq-mssql"

# Параметры подключения к БД (внутри контейнера)
DB_SERVER="localhost"
DB_PORT="1433"
DB_NAME="FishEye"
DB_USER="sa"
DB_PASSWORD="kolob_OK1"

# Путь к sqlcmd внутри контейнера
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"

# Параметры процедуры
IPGCH=15
MONTH_END_DATE="2025-07-31"
IPGST=""          # пустая строка = NULL = все стройки; или, например, "12ОПР"

# Таймаут в секундах (10 минут)
TIMEOUT=600

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}Выполнение процедуры ags.spMstrg_2605${NC}"
echo -e "${BLUE}(@saveToTables = 1, заполнение ResultSet-таблиц)${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Проверка наличия docker и контейнера
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ОШИБКА: docker не найден в системе${NC}"
    exit 1
fi

if ! docker ps --filter "name=$CONTAINER" --filter "status=running" -q | grep -q .; then
    echo -e "${RED}ОШИБКА: контейнер $CONTAINER не запущен${NC}"
    echo "Запустите: docker start $CONTAINER"
    exit 1
fi
echo -e "${GREEN}✓ Контейнер $CONTAINER запущен${NC}"
echo ""

# Построение SQL с учётом @ipgSt
if [ -z "$IPGST" ]; then
    IPGST_SQL="NULL"
    echo "Параметры: @ipgCh = $IPGCH, @MounthEndDate = '$MONTH_END_DATE', @ipgSt = NULL (все стройки), @saveToTables = 1"
else
    IPGST_SQL="N'$IPGST'"
    echo "Параметры: @ipgCh = $IPGCH, @MounthEndDate = '$MONTH_END_DATE', @ipgSt = '$IPGST', @saveToTables = 1"
fi

SQL_EXEC="EXEC ags.spMstrg_2605 @ipgCh = $IPGCH, @MounthEndDate = '$MONTH_END_DATE', @ipgSt = $IPGST_SQL, @saveToTables = 1;"

echo "Таймаут: $TIMEOUT секунд ($(($TIMEOUT / 60)) минут)"
echo ""

START_TIME=$(date +%s)

docker exec "$CONTAINER" "$SQLCMD" \
    -S "$DB_SERVER,$DB_PORT" \
    -d "$DB_NAME" \
    -U "$DB_USER" \
    -P "$DB_PASSWORD" \
    -C \
    -Q "$SQL_EXEC" \
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

    # Проверка результатов
    echo -e "${YELLOW}Проверка количества строк в ResultSet-таблицах...${NC}"
    echo ""

    docker exec "$CONTAINER" "$SQLCMD" \
        -S "$DB_SERVER,$DB_PORT" \
        -d "$DB_NAME" \
        -U "$DB_USER" \
        -P "$DB_PASSWORD" \
        -C \
        -Q "SELECT
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet1) AS RS1,
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet2) AS RS2,
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet3) AS RS3,
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet4) AS RS4,
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet5) AS RS5,
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet6) AS RS6,
            (SELECT COUNT(*) FROM ags.spMstrg_2408_ResultSet7) AS RS7;"

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
