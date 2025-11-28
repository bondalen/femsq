#!/bin/bash
# Скрипт для скачивания нативных библиотек mssql-jdbc_auth.dll
# и добавления их в проект как ресурсы

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== FEMSQ: Скачивание нативных библиотек MS SQL Server JDBC ===${NC}"

# Переходим в корень проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Версия драйвера
JDBC_VERSION="12.8.1"
JDBC_FULL_VERSION="${JDBC_VERSION}.jre11"

# URL для скачивания (официальный сайт Microsoft)
# Альтернативный источник: Maven Central
MAVEN_REPO="https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/${JDBC_FULL_VERSION}"

# Временная директория
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "\n${YELLOW}Скачиваем mssql-jdbc.jar для извлечения DLL...${NC}"

# Скачиваем JAR
JAR_FILE="$TEMP_DIR/mssql-jdbc-${JDBC_FULL_VERSION}.jar"
curl -L -o "$JAR_FILE" "${MAVEN_REPO}/mssql-jdbc-${JDBC_FULL_VERSION}.jar" || {
    echo -e "${RED}Ошибка: не удалось скачать mssql-jdbc.jar${NC}"
    exit 1
}

echo -e "${GREEN}✓ JAR скачан${NC}"

# Проверяем наличие DLL в JAR
echo -e "\n${YELLOW}Проверяем наличие DLL в JAR...${NC}"
DLL_COUNT=$(unzip -l "$JAR_FILE" | grep -E "\.dll$" | wc -l)

if [ "$DLL_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠ DLL не найдены в JAR. Пробуем альтернативный источник...${NC}"
    
    # Пробуем скачать с официального сайта Microsoft
    # Официальный архив: https://learn.microsoft.com/en-us/sql/connect/jdbc/download-microsoft-jdbc-driver-for-sql-server
    echo -e "${YELLOW}Для версии ${JDBC_VERSION} DLL файлы нужно скачать отдельно с официального сайта Microsoft:${NC}"
    echo "  https://learn.microsoft.com/en-us/sql/connect/jdbc/download-microsoft-jdbc-driver-for-sql-server"
    echo ""
    echo -e "${YELLOW}После скачивания архива выполните:${NC}"
    echo "  1. Распакуйте архив"
    echo "  2. Найдите файлы:"
    echo "     - sqljdbc_auth.dll (x64) в папке sqljdbc_${JDBC_VERSION}/enu/x64/"
    echo "     - sqljdbc_auth.dll (x86) в папке sqljdbc_${JDBC_VERSION}/enu/x86/"
    echo "  3. Скопируйте их вручную в:"
    echo "     - code/femsq-backend/femsq-web/src/main/resources/com/microsoft/sqlserver/jdbc/auth/x64/"
    echo "     - code/femsq-backend/femsq-web/src/main/resources/com/microsoft/sqlserver/jdbc/auth/x86/"
    echo ""
    echo -e "${YELLOW}Или используйте скрипт с указанием пути к архиву:${NC}"
    echo "  $0 /path/to/sqljdbc_${JDBC_VERSION}_enu.zip"
    exit 1
fi

# Извлекаем DLL
echo -e "\n${YELLOW}Извлекаем DLL из JAR...${NC}"

# Создаём директории для ресурсов
RESOURCES_DIR="$PROJECT_ROOT/code/femsq-backend/femsq-web/src/main/resources/com/microsoft/sqlserver/jdbc/auth"
mkdir -p "$RESOURCES_DIR/x64"
mkdir -p "$RESOURCES_DIR/x86"

# Извлекаем DLL для x64
unzip -j "$JAR_FILE" "com/microsoft/sqlserver/jdbc/auth/x64/*.dll" -d "$RESOURCES_DIR/x64/" 2>/dev/null || {
    echo -e "${YELLOW}⚠ x64 DLL не найдены в стандартном пути${NC}"
}

# Извлекаем DLL для x86
unzip -j "$JAR_FILE" "com/microsoft/sqlserver/jdbc/auth/x86/*.dll" -d "$RESOURCES_DIR/x86/" 2>/dev/null || {
    echo -e "${YELLOW}⚠ x86 DLL не найдены в стандартном пути${NC}"
}

# Проверяем результат
X64_COUNT=$(find "$RESOURCES_DIR/x64" -name "*.dll" 2>/dev/null | wc -l)
X86_COUNT=$(find "$RESOURCES_DIR/x86" -name "*.dll" 2>/dev/null | wc -l)

if [ "$X64_COUNT" -eq 0 ] && [ "$X86_COUNT" -eq 0 ]; then
    echo -e "${RED}✗ DLL файлы не найдены в JAR${NC}"
    echo ""
    echo -e "${YELLOW}Для версии ${JDBC_VERSION} DLL нужно скачать отдельно:${NC}"
    echo "  1. Перейдите на: https://learn.microsoft.com/en-us/sql/connect/jdbc/download-microsoft-jdbc-driver-for-sql-server"
    echo "  2. Скачайте архив sqljdbc_${JDBC_VERSION}_enu.zip"
    echo "  3. Распакуйте и скопируйте DLL вручную"
    exit 1
fi

echo -e "${GREEN}✓ DLL файлы извлечены:${NC}"
[ "$X64_COUNT" -gt 0 ] && echo "  x64: $X64_COUNT файл(ов)"
[ "$X86_COUNT" -gt 0 ] && echo "  x86: $X86_COUNT файл(ов)"

echo -e "\n${GREEN}✓ Нативные библиотеки добавлены в проект${NC}"
echo "  Путь: $RESOURCES_DIR"
echo ""
echo -e "${YELLOW}Следующий шаг: пересоберите проект${NC}"
echo "  mvn clean package -pl femsq-backend/femsq-web -am -DskipTests"

