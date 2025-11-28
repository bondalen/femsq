# Руководство по обновлению библиотек для тонкого JAR

**Дата:** 2025-11-28  
**Версия приложения:** 0.1.0.1-SNAPSHOT  
**Изменение:** Обновление JasperReports с 6.21.0 до 7.0.3

## Общая информация

- **Старое количество библиотек:** 60
- **Новое количество библиотек:** 79
- **Добавлено:** 19 библиотек
- **Обновлено:** 1 основная библиотека (JasperReports)
- **Удалено:** 0 библиотек

## БИБЛИОТЕКИ ДЛЯ ДОБАВЛЕНИЯ

### JasperReports 7.0.3 (новые модули)

1. **jasperreports-pdf-7.0.3.jar** (152 KB)
   - Новый модуль для экспорта в PDF
   - Обязательно для работы отчётов

2. **jasperreports-jdt-7.0.3.jar** (19 KB)
   - Модуль JDT компилятора для JasperReports
   - Обязательно для компиляции отчётов

3. **jasperreports-fonts-7.0.3.jar** (4.9 MB)
   - Шрифты для поддержки кириллицы
   - Обязательно для корректного отображения русских текстов в отчётах

### Компилятор для отчётов

4. **ecj-4.4.2.jar** (2.3 MB)
   - Eclipse Compiler for Java
   - Используется для компиляции JRXML отчётов в .jasper файлы
   - Обязательно для работы системы отчётов

## БИБЛИОТЕКИ ДЛЯ ЗАМЕНЫ (обновление версий)

### Основные обновления

1. **jasperreports-7.0.3.jar** (3.8 MB)
   - **Было:** jasperreports-6.21.0.jar
   - **Стало:** jasperreports-7.0.3.jar
   - **Критично:** Обязательно заменить, старая версия несовместима

2. **jasperreports-functions-7.0.3.jar** (40 KB)
   - **Было:** jasperreports-functions-6.21.0.jar (если была)
   - **Стало:** jasperreports-functions-7.0.3.jar
   - Обновить до новой версии

## ПОЛНЫЙ СПИСОК БИБЛИОТЕК (79 файлов)

### Обязательные библиотеки приложения

- `femsq-database-0.1.0.1-SNAPSHOT.jar` (531 KB) - **ОБЯЗАТЕЛЬНО**
- `femsq-reports-0.1.0.1-SNAPSHOT.jar` (88 KB) - **ОБЯЗАТЕЛЬНО**

### Spring Boot и Spring Framework

- spring-boot-3.4.5.jar
- spring-boot-autoconfigure-3.4.5.jar
- spring-boot-jarmode-tools-3.4.5.jar
- spring-core-6.2.6.jar
- spring-context-6.1.19.jar
- spring-web-6.2.6.jar
- spring-webmvc-6.2.6.jar
- spring-aop-6.2.6.jar
- spring-expression-6.2.6.jar
- spring-graphql-1.3.5.jar
- spring-jcl-6.2.6.jar

### JasperReports 7.0.3

- jasperreports-7.0.3.jar ⚠️ **ОБНОВИТЬ**
- jasperreports-fonts-7.0.3.jar ➕ **ДОБАВИТЬ**
- jasperreports-pdf-7.0.3.jar ➕ **ДОБАВИТЬ**
- jasperreports-jdt-7.0.3.jar ➕ **ДОБАВИТЬ**
- jasperreports-functions-7.0.3.jar ⚠️ **ОБНОВИТЬ**

### Компиляторы

- ecj-4.4.2.jar ➕ **ДОБАВИТЬ**
- ecj-3.21.0.jar (может остаться для совместимости)

### База данных

- mssql-jdbc-12.8.1.jre11.jar
- HikariCP-5.1.0.jar

### Логирование

- slf4j-api-2.0.16.jar
- logback-classic-1.5.18.jar
- logback-core-1.5.18.jar
- log4j-api-2.24.3.jar
- log4j-to-slf4j-2.24.3.jar
- jul-to-slf4j-2.0.17.jar

### Jackson (JSON/XML)

- jackson-core-2.18.2.jar
- jackson-databind-2.18.2.jar
- jackson-annotations-2.18.2.jar
- jackson-dataformat-xml-2.18.2.jar
- jackson-datatype-jdk8-2.18.3.jar
- jackson-datatype-jsr310-2.18.3.jar
- jackson-module-parameter-names-2.18.3.jar

### GraphQL

- graphql-java-22.0.jar
- graphql-java-extended-scalars-22.0.jar
- java-dataloader-3.3.0.jar

### Валидация

- hibernate-validator-8.0.2.Final.jar
- jakarta.validation-api-3.0.2.jar
- jakarta.annotation-api-2.1.1.jar
- classmate-1.5.1.jar
- jboss-logging-3.4.3.Final.jar

### PDF генерация

- openpdf-1.3.32.jar
- xmpcore-6.1.11.jar

### Batik (SVG обработка для JasperReports)

- batik-anim-1.18.jar
- batik-awt-util-1.18.jar
- batik-bridge-1.18.jar
- batik-constants-1.18.jar
- batik-css-1.18.jar
- batik-dom-1.18.jar
- batik-ext-1.18.jar
- batik-gvt-1.18.jar
- batik-i18n-1.18.jar
- batik-parser-1.18.jar
- batik-script-1.18.jar
- batik-shared-resources-1.18.jar
- batik-svg-dom-1.18.jar
- batik-util-1.18.jar
- batik-xml-1.18.jar

### Apache Commons

- commons-beanutils-1.9.4.jar
- commons-collections-3.2.2.jar
- commons-collections4-4.4.jar
- commons-io-2.11.0.jar
- commons-logging-1.3.0.jar

### Tomcat (встроенный)

- tomcat-embed-core-10.1.40.jar
- tomcat-embed-el-10.1.40.jar
- tomcat-embed-websocket-10.1.40.jar

### Другие

- xmlgraphics-commons-2.10.jar
- xml-apis-ext-1.3.04.jar
- woodstox-core-7.0.0.jar
- stax2-api-4.2.2.jar
- snakeyaml-2.3.jar
- reactive-streams-1.0.3.jar
- reactor-core-3.6.16.jar
- micrometer-commons-1.14.5.jar
- micrometer-observation-1.14.5.jar
- context-propagation-1.1.3.jar

## ИНСТРУКЦИЯ ПО ОБНОВЛЕНИЮ

### Вариант 1: Полная замена (рекомендуется)

1. **Создайте резервную копию** текущей папки `lib/`:
   ```bash
   cp -r lib lib.backup
   ```

2. **Удалите старые библиотеки JasperReports:**
   ```bash
   rm -f lib/jasperreports-6.21.0.jar
   rm -f lib/jasperreports-functions-6.21.0.jar
   ```

3. **Добавьте новые библиотеки** из нового толстого JAR:
   ```bash
   # Извлеките библиотеки из нового толстого JAR
   unzip -j new-fat-jar.jar 'BOOT-INF/lib/*' -d lib/
   ```

### Вариант 2: Ручное обновление

1. **Удалите старые версии:**
   - `jasperreports-6.21.0.jar` (если есть)
   - `jasperreports-functions-6.21.0.jar` (если есть)

2. **Добавьте новые библиотеки:**
   - `jasperreports-7.0.3.jar`
   - `jasperreports-fonts-7.0.3.jar` ➕
   - `jasperreports-pdf-7.0.3.jar` ➕
   - `jasperreports-jdt-7.0.3.jar` ➕
   - `jasperreports-functions-7.0.3.jar`
   - `ecj-4.4.2.jar` ➕

## ПРОВЕРКА ПОСЛЕ ОБНОВЛЕНИЯ

После обновления библиотек проверьте:

1. **Запуск приложения:**
   ```bash
   ./run-with-external-libs.sh
   ```

2. **Проверка версий библиотек:**
   - Приложение автоматически проверит версии при запуске через `LibraryCompatibilityChecker`
   - Проверка выполняется на основе `lib-manifest.json` из тонкого JAR

3. **Тестирование отчётов:**
   - Сгенерируйте тестовый отчёт
   - Проверьте, что кириллица отображается корректно
   - Убедитесь, что PDF формируется без ошибок

## ВАЖНЫЕ ЗАМЕЧАНИЯ

⚠️ **Критично:** Обновление JasperReports с 6.21.0 до 7.0.3 требует обязательного добавления новых модулей:
- `jasperreports-pdf-7.0.3.jar` - без него PDF не будет генерироваться
- `jasperreports-jdt-7.0.3.jar` - без него отчёты не будут компилироваться
- `jasperreports-fonts-7.0.3.jar` - без него кириллица не будет отображаться

⚠️ **Совместимость:** Старые версии JasperReports 6.21.0 **несовместимы** с новым тонким JAR. Обязательно замените все библиотеки JasperReports.

## АВТОМАТИЧЕСКОЕ ОБНОВЛЕНИЕ

Для автоматического обновления используйте скрипт:

```bash
./extract-libs-from-fatjar.sh new-fat-jar.jar .
```

Этот скрипт:
1. Извлечёт все библиотеки из нового толстого JAR
2. Заменит старые библиотеки новыми
3. Сохранит правильную структуру папки `lib/`