#!/bin/bash
# Скрипт для настройки JDBC драйверов для Jaspersoft Studio
# Копирует необходимые драйверы в удобное место

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Настройка JDBC драйверов для Jaspersoft Studio ===${NC}"
echo ""

# Директория для драйверов
DRIVERS_DIR="$HOME/jaspersoft-drivers"
mkdir -p "$DRIVERS_DIR"

# Путь к драйверу MS SQL Server в Maven репозитории
MSSQL_DRIVER="$HOME/.m2/repository/com/microsoft/sqlserver/mssql-jdbc/12.8.1.jre11/mssql-jdbc-12.8.1.jre11.jar"

if [ ! -f "$MSSQL_DRIVER" ]; then
    echo -e "${YELLOW}[WARNING] Драйвер не найден в Maven репозитории${NC}"
    echo "Путь: $MSSQL_DRIVER"
    echo ""
    echo "Скачайте драйвер вручную:"
    echo "  https://learn.microsoft.com/en-us/sql/connect/jdbc/download-microsoft-jdbc-driver-for-sql-server"
    echo ""
    echo "Или установите через Maven:"
    echo "  mvn dependency:get -Dartifact=com.microsoft.sqlserver:mssql-jdbc:12.8.1.jre11"
    exit 1
fi

# Копируем драйвер
echo -e "${YELLOW}Копируем MS SQL Server драйвер...${NC}"
cp "$MSSQL_DRIVER" "$DRIVERS_DIR/mssql-jdbc.jar"

echo -e "${GREEN}✓ Драйвер скопирован в: $DRIVERS_DIR/mssql-jdbc.jar${NC}"
echo ""
echo "Теперь в Jaspersoft Studio:"
echo "1. Window → Show View → Repository Explorer"
echo "2. Data Adapters → Edit ваш адаптер"
echo "3. Вкладка Drivers → Add"
echo "4. Укажите путь: $DRIVERS_DIR/mssql-jdbc.jar"
echo "5. Driver Class: com.microsoft.sqlserver.jdbc.SQLServerDriver"
echo "6. Test Connection"
