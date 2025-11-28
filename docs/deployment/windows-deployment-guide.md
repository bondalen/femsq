# Руководство по развёртыванию тонкого JAR на Windows

**Дата:** 2025-11-28  
**Версия:** 0.1.0.1-SNAPSHOT

## Процесс развёртывания

### Шаг 1: Подготовка файлов

На удалённой машине Windows вам понадобятся:

1. **Тонкий JAR:**
   - `femsq-web-0.1.0.1-SNAPSHOT-thin.jar` (~1.6 MB)

2. **Архив с библиотеками для обновления:**
   - `lib-update-2025-11-28.zip` (11 MB)
   - Содержит 6 библиотек для добавления/замены

3. **Скрипт запуска:**
   - `start.bat` (обновлённый для тонкого JAR)

### Шаг 2: Перенос файлов

Скопируйте на удалённую машину Windows:

```
C:\femsq\
├── femsq-web-0.1.0.1-SNAPSHOT-thin.jar  (новый тонкий JAR)
├── lib-update-2025-11-28.zip           (архив с библиотеками)
├── start.bat                            (скрипт запуска)
└── lib\                                 (существующая папка с библиотеками)
```

### Шаг 3: Обновление библиотек

1. **Распакуйте архив:**
   ```cmd
   cd C:\femsq
   unzip lib-update-2025-11-28.zip
   ```

2. **Удалите старые библиотеки JasperReports:**
   ```cmd
   del lib\jasperreports-6.21.0.jar
   del lib\jasperreports-functions-6.21.0.jar
   ```

3. **Скопируйте новые библиотеки:**
   ```cmd
   copy lib-update\*.jar lib\
   ```

4. **Удалите временную папку:**
   ```cmd
   rmdir /s /q lib-update
   ```

### Шаг 4: Запуск приложения

Запустите приложение:

```cmd
start.bat
```

Или с указанием имени JAR:

```cmd
start.bat femsq-web-0.1.0.1-SNAPSHOT-thin.jar
```

## Структура директории на Windows

```
C:\femsq\
├── femsq-web-0.1.0.1-SNAPSHOT-thin.jar  (тонкий JAR)
├── start.bat                            (скрипт запуска)
├── lib\                                  (79 библиотек, ~53 MB)
│   ├── jasperreports-7.0.3.jar
│   ├── jasperreports-fonts-7.0.3.jar
│   ├── jasperreports-pdf-7.0.3.jar
│   ├── jasperreports-jdt-7.0.3.jar
│   ├── jasperreports-functions-7.0.3.jar
│   ├── ecj-4.4.2.jar
│   └── ... (остальные библиотеки)
├── native-libs\                          (для Windows Authentication, создаётся автоматически)
│   ├── mssql-jdbc_auth-12.8.1.x64.dll   (извлекается из JAR при первом запуске)
│   ├── mssql-jdbc_auth-12.8.1.x86.dll
│   └── sqljdbc_auth.dll
├── logs\                                 (создаётся автоматически)
├── reports\                              (создаётся автоматически)
└── temp\                                 (создаётся автоматически)
```

## Что проверяет start.bat

1. ✅ Наличие тонкого JAR
2. ✅ Наличие папки `lib/` с библиотеками
3. ✅ Наличие хотя бы одного JAR файла в `lib/`
4. ✅ Наличие папки `native-libs/` (опционально, для Windows Auth)

## Особенности запуска

### Spring Boot Loader 3.x

В отличие от Spring Boot 2.x, в версии 3.x `-Dloader.path` не работает. Поэтому `start.bat` использует:

```batch
java -cp "thin-jar.jar;lib\*.jar" org.springframework.boot.loader.launch.JarLauncher
```

Это обеспечивает:
- Правильную загрузку всех библиотек из `lib/`
- Корректную работу Spring Boot Loader
- Поддержку вложенных JAR (BOOT-INF/classes)

### Windows Authentication

Если нужна Windows Authentication для MS SQL Server:

1. Создайте папку `native-libs/`
2. Скопируйте туда DLL файлы:
   - `mssql-jdbc_auth-12.8.1.x64.dll` (для 64-bit)
   - `mssql-jdbc_auth-12.8.1.x86.dll` (для 32-bit)
   - `sqljdbc_auth.dll` (для обратной совместимости)

Скрипт `start.bat` автоматически добавит `native-libs/` в `PATH`.

## Проверка после развёртывания

1. **Запуск приложения:**
   ```cmd
   start.bat
   ```

2. **Проверка логов:**
   - Приложение автоматически проверит версии библиотек при запуске
   - Проверка выполняется через `LibraryCompatibilityChecker`
   - Ошибки версий будут отображены в консоли

3. **Тестирование:**
   - Откройте браузер: `http://localhost:8080`
   - Проверьте генерацию отчёта
   - Убедитесь, что кириллица отображается корректно

## Устранение проблем

### Ошибка: "NoClassDefFoundError"

**Причина:** Библиотеки не найдены в `lib/`

**Решение:**
1. Проверьте наличие папки `lib/`
2. Убедитесь, что в `lib/` есть все 79 библиотек
3. Проверьте, что обновлены библиотеки JasperReports

### Ошибка: "ClassNotFoundException: org.slf4j.LoggerFactory"

**Причина:** Неправильный способ запуска или отсутствие библиотек

**Решение:**
1. Используйте обновлённый `start.bat`
2. Проверьте, что все библиотеки извлечены в `lib/`

### Ошибка: "Windows Authentication не работает"

**Причина:** Отсутствует `native-libs/` или DLL файлы

**Решение:**
1. Папка `native-libs/` создаётся автоматически при первом запуске рядом с тонким JAR
2. DLL файлы извлекаются автоматически из тонкого JAR при первом запуске
3. Если нужно вручную, скопируйте DLL из толстого JAR:
   ```cmd
   jar xf femsq-web-0.1.0.1-SNAPSHOT.jar BOOT-INF\classes\native-libs
   move BOOT-INF\classes\native-libs native-libs
   rmdir /s /q BOOT-INF
   ```
   
**Важно:** `native-libs/` должна быть **рядом с тонким JAR**, а не в `lib/`

## Следующие обновления

Для следующих обновлений:

1. Скопируйте только новый тонкий JAR (~1.6 MB)
2. Замените старый тонкий JAR
3. Запустите `start.bat`

Библиотеки в `lib/` обновлять не нужно, если их версии не изменились.