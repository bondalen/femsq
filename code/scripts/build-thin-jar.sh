#!/bin/bash
# Скрипт для сборки Thin JAR (без библиотек)
# Используется для последующих обновлений после извлечения библиотек

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== FEMSQ: Сборка Thin JAR ===${NC}"

# Переходим в корень проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Проект: $PROJECT_ROOT"

# Собираем только классы приложения
echo -e "\n${YELLOW}Сборка модулей femsq-reports и femsq-web...${NC}"
mvn clean package -pl femsq-backend/femsq-reports,femsq-backend/femsq-web -am -DskipTests

# Путь к Fat JAR
FAT_JAR="$PROJECT_ROOT/femsq-backend/femsq-web/target/femsq-web-0.1.0.1-SNAPSHOT.jar"

# Создаём Thin JAR
THIN_JAR="$PROJECT_ROOT/femsq-backend/femsq-web/target/femsq-web-0.1.0.1-SNAPSHOT-thin.jar"
TEMP_DIR="$PROJECT_ROOT/femsq-backend/femsq-web/target/thin-temp"

echo -e "\n${YELLOW}Создаём Thin JAR (без библиотек)...${NC}"

# Извлекаем всё кроме BOOT-INF/lib/
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
unzip -q "$FAT_JAR" -x 'BOOT-INF/lib/*'

# Проверяем наличие lib-manifest.json в JAR или в target/classes
LIB_MANIFEST_SOURCE=""
if [ -f "$TEMP_DIR/BOOT-INF/classes/META-INF/lib-manifest.json" ]; then
    LIB_MANIFEST_SOURCE="$TEMP_DIR/BOOT-INF/classes/META-INF/lib-manifest.json"
elif [ -f "$PROJECT_ROOT/femsq-backend/femsq-web/target/classes/META-INF/lib-manifest.json" ]; then
    LIB_MANIFEST_SOURCE="$PROJECT_ROOT/femsq-backend/femsq-web/target/classes/META-INF/lib-manifest.json"
fi

if [ -n "$LIB_MANIFEST_SOURCE" ]; then
    echo -e "\n${YELLOW}Сохраняем lib-manifest.json для проверки библиотек...${NC}"
    mkdir -p "$TEMP_DIR/META-INF"
    cp "$LIB_MANIFEST_SOURCE" "$TEMP_DIR/META-INF/lib-manifest.json"
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

# Создаём новый JAR
cd "$TEMP_DIR"
jar cfm "$THIN_JAR" META-INF/MANIFEST.MF .

# Удаляем временную директорию
cd "$PROJECT_ROOT"
rm -rf "$TEMP_DIR"

# Подсчитываем размеры
FAT_SIZE=$(du -h "$FAT_JAR" | cut -f1)
THIN_SIZE=$(du -h "$THIN_JAR" | cut -f1)

echo -e "\n${GREEN}✓ Сборка завершена!${NC}"
echo "  Fat JAR:  $FAT_SIZE  ($FAT_JAR)"
echo "  Thin JAR: $THIN_SIZE  ($THIN_JAR)"
echo ""
echo -e "${YELLOW}Экономия при обновлении: $FAT_SIZE → $THIN_SIZE${NC}"
