# План работы чата: Настройка DBeaver для подключения к MS SQL Server с Windows Authentication

**Дата:** 2025-12-17  
**Автор:** Александр  
**Связанные задачи:** (планируется)  
**Связанная документация:** 
- [Windows Authentication в FEMSQ](../../../../deployment/windows-authentication.md)
- [Настройка нативных библиотек MS SQL Server JDBC](../../../../deployment/mssql-native-libs-setup.md)
- [Проблема и решение DBeaver](/home/alex/femsq-test/test-25-1215/dbeaver-jdbc/ПРОБЛЕМА_И_РЕШЕНИЕ.txt)

## Контекст

### Проблема
- На удалённой Linux машине (bondale1@adm.gazprom.ru) DBeaver 24.0.2 не может подключиться к MS SQL Server
- Машина не имеет доступа в интернет, поэтому DBeaver не может скачать JDBC драйвер через Maven
- При попытке использовать драйвер `mssql-jdbc-12.8.1.jre11.jar` из проекта FEMSQ:
  - Класс драйвера не находится (красная полоса в Driver Manager)
- При попытке использовать драйвер `mssql-jdbc-13.2.0.jre11`:
  - Класс находится, но диалог создания подключения зависает

### Анализ проблемы
- **DBeaver 24.0.2** выпущен в феврале 2024 года
- **mssql-jdbc-12.8.1** выпущен в августе 2024 года (на 6 месяцев позже)
- **mssql-jdbc-13.2.0** выпущен в ноябре 2024 года (на 9 месяцев позже)
- **Вывод:** DBeaver 24.0.2 не поддерживает драйверы, выпущенные после его релиза

### Решение
- Использовать драйвер **mssql-jdbc-12.4.1.jre11.jar** (июнь 2024)
  - Указан в DBeaver 24.0.2 по умолчанию
  - Протестирован разработчиками DBeaver
  - Совместим с Java 17.0.12 (RED SOFT)

### Требования к Windows Authentication
- В проекте FEMSQ уже реализована Windows Authentication для Windows-машин
- Используется `mssql-jdbc_auth-12.8.1.x64.dll` с `integratedSecurity=true`
- На Linux требуется настройка Kerberos для Windows Authentication
- **Важно:** Windows Authentication на Linux неизбежно понадобится, порядок работы сервера не изменить

### Разделение задачи
Задача разделена на два этапа:
1. **Задача 1:** Добиться работоспособности драйвера (драйвер видит сервер, сервер отклоняет аутентификацию)
2. **Задача 2:** Решить вопрос с Windows Authentication на Linux машине

### Текущая машина
- **Удалённая машина:** bondale1@adm.gazprom.ru (Linux, Fedora)
- **DBeaver:** 24.0.2
- **Java:** 17.0.12 (RED SOFT)
- **SQL Server:** Требует Windows Authentication (порядок работы сервера не изменить)

### Подготовленные файлы
- **Расположение:** `/home/alex/femsq-test/test-25-1215/dbeaver-jdbc/`
- **Драйверы:**
  - ✅ `mssql-jdbc-12.4.1.jre11.jar` (1.4 МБ) - основной
  - ✅ `mssql-jdbc-12.2.0.jre11.jar` (1.4 МБ) - запасной
- **Документация:**
  - `НАЧНИТЕ_ЗДЕСЬ.txt` - краткая инструкция
  - `УСТАНОВКА_ДРАЙВЕРА.txt` - подробная инструкция
  - `АУТЕНТИФИКАЦИЯ_WINDOWS.txt` - информация о Windows Authentication
  - `ПРЕДЛОЖЕНИЯ_ПО_СТРУКТУРЕ.txt` - предложения по структуре библиотек

## Структурный план (№ 09)

### ✅ **09.0 Этап 0 ― Подготовка библиотек Windows Authentication** ✅

**Цель:** Подготовить все необходимые библиотеки заранее, чтобы не забыть и не перепутать версии

**Статус:** ✅ Завершён (2025-12-17)

- ✅ **09.1 Скачать mssql-jdbc_auth для версии 12.4.1**
  - ✅ 09.1.1 Скачан `mssql-jdbc_auth-12.4.1.x64.dll` с Maven Central
    - URL: `https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc_auth/12.4.1.x64/`
    - Сохранён в `/home/alex/femsq-test/test-25-1215/dbeaver-jdbc/windows-auth/12.4.1/`
    - Размер: 321 KB
    - MD5: `e14e7be14ea4a73c78c199e5c3ec13f5`
    - Тип: PE32+ executable for MS Windows 6.00 (DLL), x86-64
  - ⚠️  09.1.2 `.so` файл НЕ найден в JAR драйвера
    - ⚠️  Требуется скачать отдельно из официального архива Microsoft
    - URL: https://learn.microsoft.com/en-us/sql/connect/jdbc/download-microsoft-jdbc-driver-for-sql-server
    - Архив: `sqljdbc_12.4.1_enu.zip`
    - Путь в архиве: `sqljdbc_12.4.1_enu/enu/x64/sqljdbc_auth.so`
    - После скачивания переименовать: `sqljdbc_auth.so` → `mssql-jdbc_auth-12.4.1.x86_64.so`
  - ✅ 09.1.3 DLL файл проверен и готов к использованию
  - ⏳ 09.1.4 Проверка `.so` файла отложена до его скачивания

- ✅ **09.2 Скопировать библиотеки из проекта FEMSQ (версия 12.8.1)**
  - ✅ 09.2.1 Найдены библиотеки в проекте FEMSQ
    - Путь: `code/femsq-backend/femsq-database/src/main/resources/com/microsoft/sqlserver/jdbc/auth/`
    - Файлы:
      - `x64/mssql-jdbc_auth-12.8.1.x64.dll` (299 KB)
      - `x86/mssql-jdbc_auth-12.8.1.x86.dll` (243 KB)
  - ✅ 09.2.2 Скопированы в папку для справки
    - Сохранены в `/home/alex/femsq-test/test-25-1215/dbeaver-jdbc/windows-auth/12.8.1/`
    - Для справки (на случай если понадобится версия 12.8.1)

- ✅ **09.3 Создать структуру папок**
  - ✅ 09.3.1 Созданы директории для организации библиотек
    ```
    /home/alex/femsq-test/test-25-1215/dbeaver-jdbc/
    ├── windows-auth/
    │   ├── 12.4.1/
    │   │   ├── mssql-jdbc_auth-12.4.1.x64.dll ✅
    │   │   ├── mssql-jdbc_auth-12.4.1.x86_64.so ⚠️  требуется
    │   │   └── README_AUTH_12_4_1.txt ✅
    │   ├── 12.8.1/
    │   │   ├── mssql-jdbc_auth-12.8.1.x64.dll ✅
    │   │   ├── mssql-jdbc_auth-12.8.1.x86.dll ✅
    │   │   └── README_AUTH_12_8_1.txt ✅
    │   └── README.txt ✅
    ```

- ✅ **09.4 Создать документацию по библиотекам**
  - ✅ 09.4.1 Создан `README_AUTH_12_4_1.txt`
    - Инструкция по использованию для задачи 2
    - Описание совместимости версий
    - Инструкция по добавлению в DBeaver
    - Инструкция по скачиванию `.so` файла
  - ✅ 09.4.2 Создан `README_AUTH_12_8_1.txt`
    - Справка о версии из FEMSQ
    - Для справки и сравнения
  - ✅ 09.4.3 Создан `windows-auth/README.txt`
    - Общая информация о структуре
    - Статус файлов
    - Следующие шаги

---

### ⏳ **09.1 Этап 1 ― Базовая работоспособность драйвера**

**Цель:** Драйвер видит сервер, сервер отклоняет аутентификацию (это нормально на данном этапе)

- ⏳ **09.1.1 Перенести драйвер на удалённую машину**
  - ⏳ 09.1.1.1 Скопировать `mssql-jdbc-12.4.1.jre11.jar` на удалённую машину
    - Способ: USB накопитель или сетевая папка
    - Целевое расположение: `/home/bondale1@adm.gazprom.ru/drivers/mssql-jdbc-12.4.1.jre11.jar`
  - ⏳ 09.1.1.2 Проверить права доступа
    - `chmod 644 /home/bondale1@adm.gazprom.ru/drivers/mssql-jdbc-12.4.1.jre11.jar`
  - ⏳ 09.1.1.3 Проверить целостность файла
    - `md5sum mssql-jdbc-12.4.1.jre11.jar` (ожидаемый: `7501e478f012baeb138542cc7a920354`)

- ⏳ **09.1.2 Настроить драйвер в DBeaver (GUI метод)**
  - ⏳ 09.1.2.1 Открыть DBeaver → Database → Driver Manager
  - ⏳ 09.1.2.2 Найти драйвер "MS SQL Server" → "SQL Server" → Edit
  - ⏳ 09.1.2.3 На вкладке "Библиотеки" (Libraries):
    - ⏳ 09.1.2.3.1 Удалить/отключить Maven записи:
      - `com.microsoft.sqlserver:mssql-jdbc:RELEASE [12.4.1.jre11]`
      - `com.microsoft.sqlserver:mssql-jdbc_auth:RELEASE [12.4.1.x64]`
    - ⏳ 09.1.2.3.2 Добавить локальный JAR:
      - Нажать "Добавить Файл" (Add File)
      - Выбрать: `/home/bondale1@adm.gazprom.ru/drivers/mssql-jdbc-12.4.1.jre11.jar`
      - Убедиться что галочка стоит ✓
    - ⏳ 09.1.2.3.3 **НЕ добавлять** `mssql-jdbc_auth` на этом этапе (это для задачи 2)
  - ⏳ 09.1.2.4 На вкладке "Настройки" (Settings):
    - Проверить "Класс драйвера": `com.microsoft.sqlserver.jdbc.SQLServerDriver`
    - Нажать "Найти Класс" (Find Class)
    - ✅ **Ожидаемый результат:** Класс найден без ошибок
  - ⏳ 09.1.2.5 Нажать OK → Перезапустить DBeaver

- ⏳ **09.1.3 Проверить базовое подключение**
  - ⏳ 09.1.3.1 Создать новое подключение:
    - Database → New Database Connection
    - Выбрать "MS SQL Server" → "SQL Server"
    - Нажать "Далее" (Next)
  - ⏳ 09.1.3.2 Заполнить параметры подключения:
    - Host: адрес SQL Server
    - Port: 1433 (по умолчанию)
    - Database: имя базы данных
    - Authentication: SQL Server Authentication (пока не Windows!)
    - Username: любой SQL логин (для проверки)
    - Password: любой пароль (для проверки)
  - ⏳ 09.1.3.3 Нажать "Test Connection"
  - ⏳ 09.1.3.4 **Ожидаемый результат:**
    - ✅ Соединение устанавливается (не "connection refused")
    - ✅ Сервер отвечает
    - ❌ Аутентификация НЕ проходит (это нормально на данном этапе)
    - Ошибка: "Login failed for user" или "Authentication failed"
  - ⏳ 09.1.3.5 Проверить логи DBeaver
    - Путь: `~/.local/share/DBeaverData/workspace6/.metadata/.log`
    - ✅ НЕТ ошибок: `Maven artifact not found`
    - ✅ НЕТ ошибок: `Network unavailable`
    - ✅ НЕТ ошибок: `ClassNotFoundException`
    - ✅ Есть ошибка аутентификации (это нормально)

- ⏳ **09.1.4 Диагностика (если не работает)**
  - ⏳ 09.1.4.1 Проверить доступность SQL Server
    - `telnet <host> 1433` или `nc -zv <host> 1433`
    - Должен быть доступен порт
  - ⏳ 09.1.4.2 Проверить класс драйвера вручную
    - `java -cp mssql-jdbc-12.4.1.jre11.jar com.microsoft.sqlserver.jdbc.SQLServerDriver`
    - Должен выполниться без ошибок
  - ⏳ 09.1.4.3 Попробовать запасной драйвер 12.2.0
    - Если 12.4.1 не работает, использовать `mssql-jdbc-12.2.0.jre11.jar`

**Критерии успеха задачи 1:**
- ✅ Драйвер загружается в DBeaver без ошибок
- ✅ Класс драйвера находится
- ✅ Соединение с сервером устанавливается
- ✅ Сервер отвечает (не "connection refused")
- ❌ Аутентификация НЕ проходит (это нормально, задача 2)

---

### ⏳ **09.2 Этап 2 ― Windows Authentication на Linux**

**Цель:** Настроить Windows Authentication через Kerberos для Linux машины

- ⏳ **09.2.1 Подготовить библиотеку mssql-jdbc_auth для Linux**
  - ⏳ 09.2.1.1 Перенести `mssql-jdbc_auth-12.4.1.x86_64.so` на удалённую машину
    - Расположение: `/home/bondale1@adm.gazprom.ru/drivers/mssql-jdbc_auth-12.4.1.x86_64.so`
  - ⏳ 09.2.1.2 Проверить права доступа
    - `chmod 755 /home/bondale1@adm.gazprom.ru/drivers/mssql-jdbc_auth-12.4.1.x86_64.so`
  - ⏳ 09.2.1.3 Проверить зависимости
    - `ldd mssql-jdbc_auth-12.4.1.x86_64.so`
    - Все зависимости должны быть доступны

- ⏳ **09.2.2 Настроить Kerberos на Linux машине**
  - ⏳ 09.2.2.1 Проверить наличие Kerberos клиента
    - `which kinit` (должен быть установлен)
    - `which klist` (должен быть установлен)
  - ⏳ 09.2.2.2 Настроить `/etc/krb5.conf`
    - Создать или отредактировать файл
    - Настроить realm: `ADM.GAZPROM.RU`
    - Настроить KDC серверы
    - Пример конфигурации (из документации FEMSQ):
      ```ini
      [libdefaults]
          default_realm = ADM.GAZPROM.RU
          dns_lookup_kdc = true
          dns_lookup_realm = false
      
      [realms]
          ADM.GAZPROM.RU = {
              kdc = dc.adm.gazprom.ru
              admin_server = dc.adm.gazprom.ru
          }
      ```
  - ⏳ 09.2.2.3 Проверить подключение к домену
    - `ping dc.adm.gazprom.ru` (должен отвечать)
    - Проверить DNS разрешение

- ⏳ **09.2.3 Получить Kerberos ticket**
  - ⏳ 09.2.3.1 Выполнить `kinit bondale1@ADM.GAZPROM.RU`
    - Ввести пароль доменной учётной записи
    - ✅ **Ожидаемый результат:** Ticket получен успешно
  - ⏳ 09.2.3.2 Проверить ticket
    - `klist` (должен показать активный ticket)
    - Проверить срок действия ticket
  - ⏳ 09.2.3.3 Настроить автоматическое обновление ticket (опционально)
    - Настроить cron для периодического `kinit`

- ⏳ **09.2.4 Добавить библиотеку в DBeaver**
  - ⏳ 09.2.4.1 Открыть DBeaver → Database → Driver Manager
  - ⏳ 09.2.4.2 Найти драйвер "MS SQL Server" → "SQL Server" → Edit
  - ⏳ 09.2.4.3 На вкладке "Библиотеки" (Libraries):
    - ✅ Убедиться что `mssql-jdbc-12.4.1.jre11.jar` добавлен
    - ⏳ 09.2.4.3.1 Добавить `mssql-jdbc_auth-12.4.1.x86_64.so`
      - Нажать "Добавить Файл" (Add File)
      - Выбрать: `/home/bondale1@adm.gazprom.ru/drivers/mssql-jdbc_auth-12.4.1.x86_64.so`
      - Убедиться что галочка стоит ✓
  - ⏳ 09.2.4.4 Нажать OK → Перезапустить DBeaver

- ⏳ **09.2.5 Настроить подключение с Windows Authentication**
  - ⏳ 09.2.5.1 Создать новое подключение или отредактировать существующее
    - Database → New Database Connection (или Edit Connection)
    - Выбрать "MS SQL Server" → "SQL Server"
  - ⏳ 09.2.5.2 Заполнить параметры подключения:
    - Host: адрес SQL Server
    - Port: 1433
    - Database: имя базы данных
    - Authentication: Windows (Active Directory) или Custom
  - ⏳ 09.2.5.3 Настроить Connection String (если Custom):
    ```
    jdbc:sqlserver://{host}:{port};databaseName={database};integratedSecurity=true;authenticationScheme=JavaKerberos
    ```
  - ⏳ 09.2.5.4 Настроить дополнительные параметры (если нужно):
    - Username: `bondale1@ADM.GAZPROM.RU` (если требуется явно)
    - Или оставить пустым (будет использован текущий Kerberos ticket)

- ⏳ **09.2.6 Проверить подключение с Windows Authentication**
  - ⏳ 09.2.6.1 Убедиться что Kerberos ticket активен
    - `klist` (должен показать активный ticket)
  - ⏳ 09.2.6.2 Нажать "Test Connection"
  - ⏳ 09.2.6.3 **Ожидаемый результат:**
    - ✅ Соединение устанавливается
    - ✅ Аутентификация проходит успешно
    - ✅ Подключение к базе данных успешно
    - Сообщение: "Connected"
  - ⏳ 09.2.6.4 Проверить логи DBeaver
    - Путь: `~/.local/share/DBeaverData/workspace6/.metadata/.log`
    - ✅ НЕТ ошибок аутентификации
    - ✅ НЕТ ошибок загрузки библиотеки

- ⏳ **09.2.7 Диагностика (если не работает)**
  - ⏳ 09.2.7.1 Проверить загрузку библиотеки
    - Проверить логи DBeaver на ошибки загрузки `.so`
    - Проверить `java.library.path` в DBeaver
  - ⏳ 09.2.7.2 Проверить Kerberos конфигурацию
    - `kinit -V bondale1@ADM.GAZPROM.RU` (verbose режим)
    - Проверить `/etc/krb5.conf` на ошибки
  - ⏳ 09.2.7.3 Проверить совместимость версий
    - Убедиться что версия драйвера и auth библиотеки совпадают (12.4.1)
  - ⏳ 09.2.7.4 Проверить настройки SQL Server
    - Убедиться что SQL Server настроен для Windows Authentication
    - Проверить что пользователь `bondale1@ADM.GAZPROM.RU` имеет доступ к БД

**Критерии успеха задачи 2:**
- ✅ Kerberos настроен и работает (`kinit`, `klist`)
- ✅ Библиотека `mssql-jdbc_auth-12.4.1.x86_64.so` загружена в DBeaver
- ✅ Подключение с `integratedSecurity=true` устанавливается
- ✅ Аутентификация проходит успешно
- ✅ Можно выполнять запросы к базе данных

---

## Примечания

### Важные замечания

1. **Соответствие версий:**
   - ✅ **ПРАВИЛЬНО:** `mssql-jdbc-12.4.1.jar` + `mssql-jdbc_auth-12.4.1.so`
   - ❌ **НЕПРАВИЛЬНО:** `mssql-jdbc-12.4.1.jar` + `mssql-jdbc_auth-12.8.1.so`
   - Разные версии могут быть несовместимы!

2. **Порядок выполнения:**
   - Сначала задача 1 (базовая работоспособность)
   - Потом задача 2 (Windows Authentication)
   - Не пытаться решить обе задачи одновременно

3. **Подготовка библиотек:**
   - Библиотеки Windows Authentication готовятся заранее (этап 0)
   - Это позволяет не забыть и не перепутать версии
   - Но добавляются в DBeaver только на этапе задачи 2

4. **Опыт из FEMSQ:**
   - В FEMSQ Windows Authentication работает на Windows через `mssql-jdbc_auth.dll`
   - На Linux требуется настройка Kerberos (как в задаче 2)
   - Код в `WindowsIntegratedAuthenticationProvider.java` показывает оба подхода

### Связанные файлы

- **Документация проекта:**
  - `docs/deployment/windows-authentication.md` - Windows Authentication в FEMSQ
  - `docs/deployment/mssql-native-libs-setup.md` - Настройка нативных библиотек
  - `code/femsq-backend/femsq-database/src/main/java/com/femsq/database/auth/WindowsIntegratedAuthenticationProvider.java` - Реализация

- **Подготовленные файлы:**
  - `/home/alex/femsq-test/test-25-1215/dbeaver-jdbc/` - все драйверы и документация

### Следующие шаги

После завершения обеих задач:
- Документировать процесс в `docs/deployment/dbeaver-windows-auth-linux.md`
- Обновить документацию проекта
- Создать резюме чата в `chat-resume/chat-resume-25-1217-dbeaver-windows-auth.md`
