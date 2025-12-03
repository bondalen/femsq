#!/bin/bash
# Скрипт для сборки Thin JAR (без библиотек)
# Используется для последующих обновлений после извлечения библиотек
# Автоматически увеличивает четвёртую цифру версии перед сборкой

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== FEMSQ: Сборка Thin JAR ===${NC}"

# Переходим в корень проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Скрипт находится в code/scripts/, поэтому PROJECT_ROOT = code/
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CODE_ROOT="$PROJECT_ROOT"
cd "$CODE_ROOT"

echo "Проект: $CODE_ROOT"

# Автоматически увеличиваем версию
echo -e "\n${YELLOW}Увеличение версии...${NC}"
"$SCRIPT_DIR/increment-version.sh"

# Получаем новую версию (после увеличения)
NEW_VERSION=$(grep -oP '<version>\K[^<]+' "$CODE_ROOT/pom.xml" | head -1)
# Убираем -SNAPSHOT для имени файла
VERSION_SHORT="${NEW_VERSION%-SNAPSHOT}"

if [ -z "$VERSION_SHORT" ] || [ "$VERSION_SHORT" = "$NEW_VERSION" ]; then
    echo "Error: Failed to extract version from pom.xml"
    echo "Current version line: $(grep '<version>' "$CODE_ROOT/pom.xml" | head -1)"
    exit 1
fi

echo -e "${GREEN}Версия: $NEW_VERSION (short: $VERSION_SHORT)${NC}"

# Собираем весь проект (все модули должны быть собраны с одинаковой версией)
echo -e "\n${YELLOW}Сборка всего проекта...${NC}"
mvn clean package -Dmaven.test.skip=true -pl femsq-backend/femsq-web -am

# Путь к Fat JAR
FAT_JAR="$CODE_ROOT/femsq-backend/femsq-web/target/femsq-web-${VERSION_SHORT}-SNAPSHOT.jar"

# Создаём Thin JAR
THIN_JAR="$CODE_ROOT/femsq-backend/femsq-web/target/femsq-web-${VERSION_SHORT}-SNAPSHOT-thin.jar"
TEMP_DIR="$CODE_ROOT/femsq-backend/femsq-web/target/thin-temp"

echo -e "\n${YELLOW}Создаём Thin JAR (без библиотек)...${NC}"

# Извлекаем всё кроме BOOT-INF/lib/ и native-libs
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
unzip -q "$FAT_JAR" -x 'BOOT-INF/lib/*' \
    'BOOT-INF/classes/com/microsoft/sqlserver/jdbc/auth/*' \
    'BOOT-INF/classes/native-libs/*'

# Проверяем наличие lib-manifest.json в JAR или в target/classes
LIB_MANIFEST_SOURCE=""
if [ -f "$TEMP_DIR/BOOT-INF/classes/META-INF/lib-manifest.json" ]; then
    LIB_MANIFEST_SOURCE="$TEMP_DIR/BOOT-INF/classes/META-INF/lib-manifest.json"
elif [ -f "$CODE_ROOT/femsq-backend/femsq-web/target/classes/META-INF/lib-manifest.json" ]; then
    LIB_MANIFEST_SOURCE="$CODE_ROOT/femsq-backend/femsq-web/target/classes/META-INF/lib-manifest.json"
fi

if [ -n "$LIB_MANIFEST_SOURCE" ]; then
    echo -e "\n${YELLOW}Сохраняем lib-manifest.json для проверки библиотек...${NC}"
    mkdir -p "$TEMP_DIR/META-INF"
    cp "$LIB_MANIFEST_SOURCE" "$TEMP_DIR/META-INF/lib-manifest.json"
    # Проверяем, что файл скопирован
    if [ -f "$TEMP_DIR/META-INF/lib-manifest.json" ]; then
        echo -e "${GREEN}✓ lib-manifest.json скопирован в META-INF/${NC}"
    else
        echo -e "${YELLOW}⚠ Предупреждение: не удалось скопировать lib-manifest.json${NC}"
    fi
else
    echo -e "\n${YELLOW}Предупреждение: lib-manifest.json не найден${NC}"
    echo "         Проверка версий библиотек будет пропущена при запуске thin JAR"
fi

# Обновляем MANIFEST.MF для использования внешних библиотек
MANIFEST_FILE="$TEMP_DIR/META-INF/MANIFEST.MF"
if [ -f "$MANIFEST_FILE" ]; then
    echo -e "\n${YELLOW}Обновляем MANIFEST.MF...${NC}"
    # Добавляем Class-Path с относительным путём к lib/
    sed -i '/Spring-Boot-Classes:/a Class-Path: lib/' "$MANIFEST_FILE"
fi

# Проверяем наличие классов Spring Boot Loader (критично для запуска)
if [ ! -f "$TEMP_DIR/org/springframework/boot/loader/launch/JarLauncher.class" ]; then
    echo -e "${RED}Error: Spring Boot Loader classes not found!${NC}"
    echo "         JarLauncher.class должен быть в org/springframework/boot/loader/launch/"
    echo "         Проверьте процесс извлечения из Fat JAR"
    exit 1
fi
echo -e "${GREEN}✓ Spring Boot Loader classes found${NC}"

# Создаём новый JAR
cd "$TEMP_DIR"
echo -e "\n${YELLOW}Создаём Thin JAR из временной директории...${NC}"
jar cfm "$THIN_JAR" META-INF/MANIFEST.MF .

# Убеждаемся, что lib-manifest.json включён в JAR (если он был скопирован)
if [ -f "$TEMP_DIR/META-INF/lib-manifest.json" ]; then
    echo -e "${GREEN}✓ Проверяем наличие lib-manifest.json в JAR...${NC}"
    if unzip -l "$THIN_JAR" | grep -q "META-INF/lib-manifest.json"; then
        echo -e "${GREEN}✓ lib-manifest.json найден в тонком JAR${NC}"
    else
        echo -e "${YELLOW}⚠ lib-manifest.json не найден в JAR, добавляем вручную...${NC}"
        cd "$TEMP_DIR"
        jar uf "$THIN_JAR" META-INF/lib-manifest.json
        echo -e "${GREEN}✓ lib-manifest.json добавлен в JAR${NC}"
    fi
fi

# Удаляем временную директорию
cd "$CODE_ROOT"
rm -rf "$TEMP_DIR"

# Подсчитываем размеры
FAT_SIZE=$(du -h "$FAT_JAR" | cut -f1)
THIN_SIZE=$(du -h "$THIN_JAR" | cut -f1)

echo -e "\n${GREEN}✓ Сборка завершена!${NC}"
echo "  Fat JAR:  $FAT_SIZE  ($FAT_JAR)"
echo "  Thin JAR: $THIN_SIZE  ($THIN_JAR)"
echo ""
echo -e "${YELLOW}Экономия при обновлении: $FAT_SIZE → $THIN_SIZE${NC}"
