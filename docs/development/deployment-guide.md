# Руководство по развертыванию FEMSQ (Full-Stack)

## Быстрый старт

```bash
# 1. Сборка Full-Stack JAR-файла (backend + frontend)
cd code
mvn clean package -DskipTests

# 2. Создание файла конфигурации
mkdir -p ~/.femsq
cat > ~/.femsq/database.properties << EOF
host=localhost
port=1433
database=FishEye
schema=ags
username=sa
password=your_password
authMode=credentials
EOF

# 3. Запуск приложения
java -jar femsq-backend/femsq-web/target/femsq-web-0.1.0-SNAPSHOT.jar

# 4. Проверка работоспособности
# Frontend доступен на http://localhost:8080/
# API доступен на http://localhost:8080/api/v1/connection/status
curl http://localhost:8080/api/v1/connection/status
```

## Сборка Full-Stack JAR-файла

### Требования
- Java 21 или выше
- Maven 3.6+
- Node.js 22.x и npm 10.x (устанавливаются автоматически через `frontend-maven-plugin`)

### Сборка из корня проекта

**Важно:** Сборка должна выполняться из директории `code/`, так как frontend находится на том же уровне, что и backend.

```bash
cd /home/alex/projects/java/spring/vue/femsq/code
mvn clean package -DskipTests
```

Или с тестами:
```bash
mvn clean package
```

### Процесс сборки

Сборка включает следующие этапы:

1. **Установка Node.js и npm** (автоматически через `frontend-maven-plugin`)
   - Версия Node.js: v22.20.0
   - Версия npm: 10.9.3

2. **Сборка frontend** (автоматически через `frontend-maven-plugin`)
   - Выполняется `npm install --legacy-peer-deps --include=dev`
   - Выполняется `npm run build`
   - Результат: `femsq-frontend-q/dist/`

3. **Копирование статических ресурсов** (автоматически через `maven-resources-plugin`)
   - Копирование из `femsq-frontend-q/dist/` в `femsq-web/target/classes/static/`

4. **Сборка backend** (стандартный Maven процесс)
   - Компиляция Java-кода
   - Создание JAR-файла

5. **Создание executable JAR** (через `spring-boot-maven-plugin`)
   - Упаковка всех зависимостей в fat JAR
   - Включение статических ресурсов в JAR

### Результат сборки

JAR-файл будет создан в:
```
code/femsq-backend/femsq-web/target/femsq-web-0.1.0-SNAPSHOT.jar
```

Это "fat JAR" (executable JAR), который содержит:
- Все зависимости backend (Spring Boot, GraphQL, и т.д.)
- Скомпилированный frontend (Vue.js приложение)
- Статические ресурсы (HTML, CSS, JS, шрифты, иконки)

**Размер JAR:** ~29MB (включая все зависимости и frontend)

### Проверка содержимого JAR

Для проверки, что frontend включен в JAR:

```bash
jar tf femsq-backend/femsq-web/target/femsq-web-0.1.0-SNAPSHOT.jar | grep "static/"
```

Должны быть видны файлы:
- `BOOT-INF/classes/static/index.html`
- `BOOT-INF/classes/static/assets/...`
- `BOOT-INF/classes/static/favicon.svg`

## Подготовка конфигурации базы данных

### Создание файла конфигурации

Создайте properties-файл с конфигурацией базы данных. Например, `database.properties`:

```properties
host=localhost
port=1433
database=FishEye
schema=ags
username=sa
password=your_password
authMode=credentials
```

**Важно:** 
- Файл должен быть в формате Java Properties (key=value)
- Поля `username` и `password` опциональны для режимов `windows-integrated` и `kerberos`
- `schema` опционально (по умолчанию используется схема из конфигурации)
- `port` опционально (по умолчанию 1433)

### Расположение файла конфигурации

Файл конфигурации можно разместить:
1. В текущей директории (где запускается jar)
2. В домашней директории пользователя: `~/.femsq/db-config.json`
3. В любом месте, указав путь через системное свойство `-Dfemsq.config.path`

## Запуск приложения

### Базовый запуск

```bash
java -jar femsq-web-0.1.0-SNAPSHOT.jar
```

### Запуск с указанием пути к конфигурации

```bash
java -Dfemsq.config.path=/path/to/database.properties \
     -jar femsq-web-0.1.0-SNAPSHOT.jar
```

Или через переменную окружения:
```bash
export FEMSQ_CONFIG_PATH=/path/to/database.properties
java -jar femsq-web-0.1.0-SNAPSHOT.jar
```

### Запуск с изменением порта

```bash
java -Dserver.port=8081 \
     -jar femsq-web-0.1.0-SNAPSHOT.jar
```

### Запуск с изменением уровня логирования

```bash
java -Dlogging.level.com.femsq=DEBUG \
     -jar femsq-web-0.1.0-SNAPSHOT.jar
```

### Комбинированный запуск (рекомендуется для production)

```bash
java -Dfemsq.config.path=/etc/femsq/database.properties \
     -Dserver.port=8080 \
     -Dlogging.level.com.femsq=INFO \
     -Xms512m -Xmx1024m \
     -jar femsq-web-0.1.0-SNAPSHOT.jar
```

## Проверка работоспособности

### 1. Проверка frontend

Откройте в браузере:
```
http://localhost:8080/
```

Должен открыться Vue.js интерфейс приложения. Проверьте:
- Загрузка главной страницы
- Работа Vue Router (переходы между `/organizations`, `/connection`)
- Загрузка статических ресурсов (CSS, JS, шрифты)

### 2. Проверка API endpoints

#### Проверка статуса подключения

```bash
curl http://localhost:8080/api/v1/connection/status
```

Ожидаемый ответ:
```json
{
  "connected": true,
  "schema": "ags",
  "database": "FishEye",
  "message": "Подключение активно"
}
```

#### Проверка получения организаций

```bash
curl "http://localhost:8080/api/v1/organizations?page=0&size=10&sort=ogNm,asc"
```

Ожидаемый ответ:
```json
{
  "content": [...],
  "page": 0,
  "size": 10,
  "totalElements": 425,
  "totalPages": 43
}
```

### 3. Проверка GraphQL endpoint

```bash
curl -X POST http://localhost:8080/graphql \
     -H "Content-Type: application/json" \
     -d '{"query": "{ organizations { ogKey ogName } }"}'
```

### 4. Проверка GraphiQL (интерактивный интерфейс)

Откройте в браузере:
```
http://localhost:8080/graphiql
```

### 5. Проверка статических ресурсов

```bash
# Проверка index.html
curl http://localhost:8080/index.html

# Проверка статических assets
curl http://localhost:8080/static/assets/index-*.js
curl http://localhost:8080/static/assets/index-*.css
```

### 6. Проверка SPA routing

Проверьте, что Vue Router работает корректно:
- Откройте `http://localhost:8080/organizations` - должна открыться страница организаций
- Откройте `http://localhost:8080/connection` - должна открыться страница подключения
- API-запросы должны идти на `/api/v1/...` (относительные пути)

## Устранение проблем

### Проблема: "Cannot connect to database"

**Решение:**
1. Проверьте, что SQL Server запущен и доступен
2. Проверьте правильность параметров подключения в файле конфигурации
3. Проверьте сетевую доступность (firewall, порты)
4. Проверьте логи приложения на наличие ошибок

### Проблема: "Configuration file not found"

**Решение:**
1. Убедитесь, что файл конфигурации существует
2. Проверьте путь, указанный в `-Dfemsq.config.path` или `FEMSQ_CONFIG_PATH`
3. Проверьте права доступа к файлу
4. По умолчанию система ищет файл в:
   - Домашней директории: `~/.femsq/database.properties`
5. Приоритет поиска конфигурации:
   - Системное свойство `-Dfemsq.config.path` (наивысший приоритет)
   - Переменная окружения `FEMSQ_CONFIG_PATH`
   - Дефолтный путь `~/.femsq/database.properties`

### Проблема: "Port already in use"

**Решение:**
1. Измените порт через `-Dserver.port=8081`
2. Или остановите процесс, использующий порт 8080:
   ```bash
   # Linux
   lsof -ti:8080 | xargs kill -9
   
   # Или найдите процесс
   netstat -tulpn | grep 8080
   ```

### Проблема: "OutOfMemoryError"

**Решение:**
Увеличьте размер heap памяти:
```bash
java -Xms1g -Xmx2g -jar femsq-web-0.1.0-SNAPSHOT.jar
```

## Запуск как системный сервис (Linux)

### Создание systemd service

Создайте файл `/etc/systemd/system/femsq.service`:

```ini
[Unit]
Description=FEMSQ Backend Application
After=network.target

[Service]
Type=simple
User=femsq
WorkingDirectory=/opt/femsq
ExecStart=/usr/bin/java -Dfemsq.config.path=/etc/femsq/database.properties -jar /opt/femsq/femsq-web-0.1.0-SNAPSHOT.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Управление сервисом

```bash
# Запуск
sudo systemctl start femsq

# Остановка
sudo systemctl stop femsq

# Статус
sudo systemctl status femsq

# Автозапуск при загрузке
sudo systemctl enable femsq

# Просмотр логов
sudo journalctl -u femsq -f
```

## Безопасность

### Рекомендации для production

1. **Файл конфигурации:**
   - Разместите в защищенной директории (например, `/etc/femsq/`)
   - Установите права доступа: `chmod 600 database.properties`
   - Ограничьте доступ: `chown femsq:femsq database.properties`

2. **Пароли:**
   - Не храните пароли в открытом виде в файле конфигурации
   - Рассмотрите использование переменных окружения или секретов

3. **Сеть:**
   - Используйте firewall для ограничения доступа
   - Рассмотрите использование HTTPS (требует дополнительной настройки)

4. **Логирование:**
   - Не логируйте пароли и чувствительные данные
   - Настройте ротацию логов

## Мониторинг

### Проверка здоровья приложения

```bash
# Проверка статуса подключения
curl http://localhost:8080/api/v1/connection/status

# Проверка доступности API
curl http://localhost:8080/api/v1/organizations?page=0&size=1
```

### Логирование

Логи выводятся в консоль (stdout). Для перенаправления в файл:

```bash
java -jar femsq-web-0.1.0-SNAPSHOT.jar > /var/log/femsq/app.log 2>&1
```

Или с использованием systemd (автоматически логируется в journald).

## Дополнительные параметры JVM

### Для production окружения

```bash
java -Dfemsq.config.path=/etc/femsq/database.properties \
     -Xms1g -Xmx2g \
     -XX:+UseG1GC \
     -XX:MaxGCPauseMillis=200 \
     -XX:+HeapDumpOnOutOfMemoryError \
     -XX:HeapDumpPath=/var/log/femsq/heapdump.hprof \
     -jar femsq-web-0.1.0-SNAPSHOT.jar
```

### Параметры для отладки

```bash
java -Dfemsq.config.path=/path/to/database.properties \
     -Dlogging.level.com.femsq=DEBUG \
     -Dlogging.level.org.springframework.web=DEBUG \
     -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005 \
     -jar femsq-web-0.1.0-SNAPSHOT.jar
```

Затем подключитесь через IDE на порт 5005 для удаленной отладки.

