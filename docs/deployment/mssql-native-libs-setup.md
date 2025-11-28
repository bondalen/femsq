# Настройка нативных библиотек MS SQL Server JDBC

**Дата:** 2025-11-28  
**Версия:** 1.0

## Проблема

В версии `mssql-jdbc` 12.8.1 нативные библиотеки (`mssql-jdbc_auth.dll`) **не включены** в основной JAR файл. Они должны быть добавлены в проект отдельно для поддержки Windows Authentication на Windows-машинах.

## Решение

### Вариант 1: Автоматическое добавление (рекомендуется)

1. **Скачайте официальный архив драйвера:**
   - Перейдите на: https://learn.microsoft.com/en-us/sql/connect/jdbc/download-microsoft-jdbc-driver-for-sql-server
   - Скачайте архив `sqljdbc_12.8.1_enu.zip` (или актуальную версию)

2. **Распакуйте архив** и найдите DLL файлы:
   - `sqljdbc_12.8.1_enu/x64/sqljdbc_auth.dll` (для 64-битных систем)
   - `sqljdbc_12.8.1_enu/x86/sqljdbc_auth.dll` (для 32-битных систем)

3. **Скопируйте DLL в проект:**
   ```bash
   # Создайте директории (если их нет)
   mkdir -p code/femsq-backend/femsq-web/src/main/resources/com/microsoft/sqlserver/jdbc/auth/x64
   mkdir -p code/femsq-backend/femsq-web/src/main/resources/com/microsoft/sqlserver/jdbc/auth/x86
   
   # Скопируйте DLL файлы
   cp sqljdbc_12.8.1_enu/x64/sqljdbc_auth.dll \
      code/femsq-backend/femsq-web/src/main/resources/com/microsoft/sqlserver/jdbc/auth/x64/
   
   cp sqljdbc_12.8.1_enu/x86/sqljdbc_auth.dll \
      code/femsq-backend/femsq-web/src/main/resources/com/microsoft/sqlserver/jdbc/auth/x86/
   ```

4. **Переименуйте файлы** (опционально, для совместимости):
   ```bash
   # В папке x64
   cd code/femsq-backend/femsq-web/src/main/resources/com/microsoft/sqlserver/jdbc/auth/x64
   cp sqljdbc_auth.dll mssql-jdbc_auth.dll
   
   # В папке x86
   cd ../x86
   cp sqljdbc_auth.dll mssql-jdbc_auth.dll
   ```

5. **Пересоберите проект:**
   ```bash
   mvn clean package -pl femsq-backend/femsq-web -am -DskipTests
   ```

### Вариант 2: Использование скрипта

Используйте скрипт `download-mssql-native-libs.sh` (если DLL доступны в Maven Central):

```bash
cd code/scripts
./download-mssql-native-libs.sh
```

**Примечание:** Для версии 12.8.1 скрипт может не найти DLL в Maven Central, так как они не включены в основной JAR. В этом случае используйте Вариант 1.

## Проверка

После сборки проверьте, что DLL включены в fat JAR:

```bash
unzip -l code/femsq-backend/femsq-web/target/femsq-web-0.1.0.1-SNAPSHOT.jar | grep -i "\.dll\|native-libs"
```

Должны быть видны:
- `BOOT-INF/classes/native-libs/mssql-jdbc_auth.dll` (или `sqljdbc_auth.dll`)
- `BOOT-INF/classes/com/microsoft/sqlserver/jdbc/auth/x64/...`
- `BOOT-INF/classes/com/microsoft/sqlserver/jdbc/auth/x86/...`

## Как это работает

1. **При сборке:**
   - `NativeLibsExtractor` ищет DLL в ресурсах проекта (`src/main/resources/com/microsoft/sqlserver/jdbc/auth/`)
   - Копирует их в `target/classes/native-libs/`
   - Они автоматически включаются в fat JAR

2. **При запуске на Windows:**
   - `NativeLibraryLoader` извлекает DLL из JAR в папку `native-libs/` рядом с JAR
   - Добавляет путь к `java.library.path`
   - Загружает библиотеку через `System.load()`
   - Создаёт копии с разными именами для максимальной совместимости

3. **На Linux:**
   - DLL не требуются (используется JavaKerberos)
   - Папка `native-libs/` всё равно создаётся для совместимости

## Структура ресурсов

```
code/femsq-backend/femsq-web/src/main/resources/
└── com/
    └── microsoft/
        └── sqlserver/
            └── jdbc/
                └── auth/
                    ├── x64/
                    │   ├── mssql-jdbc_auth.dll
                    │   └── sqljdbc_auth.dll (опционально)
                    └── x86/
                        ├── mssql-jdbc_auth.dll
                        └── sqljdbc_auth.dll (опционально)
```

## Важные замечания

1. **Версия DLL должна соответствовать версии драйвера:**
   - Для `mssql-jdbc` 12.8.1 используйте DLL из `sqljdbc_12.8.1_enu.zip`
   - Не смешивайте версии!

2. **Архитектура:**
   - `x64` - для 64-битных Windows систем
   - `x86` - для 32-битных Windows систем (редко используется)

3. **Имена файлов:**
   - Драйвер может искать библиотеку под разными именами
   - `NativeLibraryLoader` создаёт копии с разными именами автоматически

## Проверка работы

После развертывания на Windows-машине:

1. Запустите приложение
2. Проверьте логи - должно быть сообщение:
   ```
   Successfully loaded mssql-jdbc_auth library for Windows Authentication
   ```
3. Попробуйте подключиться к SQL Server с `integratedSecurity=true`

## Альтернатива: без DLL

Если DLL не добавлены, приложение будет использовать JavaKerberos для аутентификации, что может работать, но с ограничениями:
- Может потребоваться дополнительная настройка Kerberos
- Некоторые функции Windows Authentication могут быть недоступны

## Ссылки

- [Microsoft JDBC Driver Download](https://learn.microsoft.com/en-us/sql/connect/jdbc/download-microsoft-jdbc-driver-for-sql-server)
- [Windows Authentication Configuration](https://learn.microsoft.com/en-us/sql/connect/jdbc/connecting-with-ssl-encryption)
- [Native Library Loading](https://learn.microsoft.com/en-us/sql/connect/jdbc/connecting-with-ssl-encryption)

