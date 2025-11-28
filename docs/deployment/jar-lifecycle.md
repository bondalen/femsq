# Жизненный цикл JAR-файлов FEMSQ

**Версия:** 1.0  
**Дата создания:** 2025-11-27  
**Автор:** Александр

---

## Обзор

FEMSQ использует двухэтапную стратегию развёртывания:
- **Fat JAR** (~51 MB) — для первичной установки на чистой машине
- **Thin JAR** (~700 KB) — для обновлений на машинах с уже установленными библиотеками

## Этап 1: Сборка Fat JAR

### Команда сборки

```bash
cd /path/to/femsq/code
mvn clean package -pl femsq-backend/femsq-web -am
```

### Результат

Создаётся файл `femsq-backend/femsq-web/target/femsq-web-{version}.jar` (~51 MB), содержащий:

- ✅ Все классы приложения
- ✅ Все внешние библиотеки (в `BOOT-INF/lib/`)
- ✅ Нативные библиотеки (в `BOOT-INF/classes/native-libs/`)
- ✅ Фронтенд (в `BOOT-INF/classes/static/`)
- ✅ Встроенные отчёты (в `BOOT-INF/classes/reports/embedded/`)
- ✅ **Метаданные библиотек** (`META-INF/lib-manifest.json`)

### Генерация lib-manifest.json

При сборке автоматически создаётся файл `META-INF/lib-manifest.json` с информацией о:

- Версии приложения и номере сборки
- Списке всех библиотек с версиями из `MANIFEST.MF`
- SHA-256 хэшах для проверки целостности
- Флагах `required/optional` для каждой библиотеки

**Формат:**

```json
{
  "buildInfo": {
    "appVersion": "0.1.0.1-SNAPSHOT",
    "buildTimestamp": "2025-11-27T15:12:56+03:00",
    "buildNumber": "20251127-151256"
  },
  "libraries": [
    {
      "filename": "femsq-database-0.1.0.1-SNAPSHOT.jar",
      "groupId": "com.femsq",
      "artifactId": "femsq-database",
      "version": "0.1.0.1-SNAPSHOT",
      "sha256": "abc123...",
      "size": 123456,
      "required": true
    }
  ]
}
```

---

## Этап 2А: Первичное развёртывание

### Сценарий

Установка на машине, где ничего нет.

### Шаги

1. **Скопировать fat JAR на целевую машину**
   ```bash
   scp femsq-web-0.1.0.1-SNAPSHOT.jar user@target-machine:/path/to/app/
   ```

2. **Запустить приложение**
   
   **Windows:**
   ```cmd
   start.bat
   ```
   
   **Linux:**
   ```bash
   java -jar femsq-web-0.1.0.1-SNAPSHOT.jar
   ```

3. **Автоматическое создание директорий**

   При первом запуске автоматически создаются:
   - `native-libs/` — нативные библиотеки для Windows Authentication
   - `reports/` — внешние отчёты
   - `logs/` — логи приложения
   - `temp/` — временные файлы

4. **Библиотеки остаются внутри JAR**

   Все зависимости находятся в `BOOT-INF/lib/` внутри JAR-файла.

---

## Этап 2Б: Обновление через Thin JAR

### Сценарий

Обновление на машине, где уже установлены библиотеки из предыдущего fat JAR.

### Предварительные условия

- ✅ На целевой машине уже есть папка `lib/` с библиотеками
- ✅ На целевой машине уже есть папка `native-libs/` (если используется Windows Auth)

### Шаги

1. **На машине разработчика: создать thin JAR**
   ```bash
   cd /path/to/femsq/code
   ./scripts/build-thin-jar.sh
   ```
   
   Результат: `femsq-backend/femsq-web/target/femsq-web-{version}-thin.jar` (~700 KB)

2. **Скопировать только thin JAR на целевую машину**
   ```bash
   scp femsq-web-0.1.0.1-SNAPSHOT-thin.jar user@target-machine:/path/to/app/
   ```

3. **Запустить приложение с внешними библиотеками**
   
   **Windows:**
   ```cmd
   java -Dloader.path=lib,native-libs -jar femsq-web-0.1.0.1-SNAPSHOT-thin.jar
   ```
   
   **Linux:**
   ```bash
   java -Dloader.path=lib,native-libs -jar femsq-web-0.1.0.1-SNAPSHOT-thin.jar
   ```
   
   Или использовать скрипт:
   ```bash
   ./run-with-external-libs.sh
   ```

4. **Автоматическая проверка библиотек**

   При запуске thin JAR автоматически выполняются проверки:

   - ✅ **Наличие всех required библиотек** в `lib/`
   - ✅ **Совпадение версий femsq-* модулей** с версией thin JAR
   - ✅ **Совместимость версий внешних библиотек** (>= требуемой)
   - ✅ **Наличие native-libs/** (если требуется Windows Auth)

   **При ошибках:**
   - Критические несоответствия → остановка запуска с сообщением об ошибке
   - Предупреждения → логирование, запуск продолжается

---

## Извлечение библиотек из Fat JAR

Если нужно извлечь библиотеки из fat JAR для последующего использования с thin JAR:

### Linux/Mac

```bash
# Извлечь все библиотеки
unzip -j femsq-web-0.1.0.1-SNAPSHOT.jar 'BOOT-INF/lib/*' -d lib/

# Извлечь native-libs
unzip -j femsq-web-0.1.0.1-SNAPSHOT.jar 'BOOT-INF/classes/native-libs/*' -d native-libs/
```

### Windows (WinRAR/7-Zip)

1. Открыть fat JAR как архив
2. Перейти в `BOOT-INF/lib/`
3. Извлечь все `.jar` файлы в папку `lib/`
4. Перейти в `BOOT-INF/classes/native-libs/`
5. Извлечь все файлы в папку `native-libs/`

### Использование скрипта

```bash
./scripts/extract-libs-from-fatjar.sh femsq-web-0.1.0.1-SNAPSHOT.jar ./target-dir/
```

---

## Проверка версий библиотек

### Механизм проверки

При запуске thin JAR класс `LibraryCompatibilityChecker`:

1. Читает `META-INF/lib-manifest.json` из thin JAR
2. Для каждой библиотеки из манифеста:
   - Проверяет наличие файла в `lib/`
   - Для `femsq-*` модулей: проверяет точное совпадение версии
   - Для внешних библиотек: проверяет совместимость версии (>= требуемой)
   - Опционально: проверяет SHA-256 хэш (если включено)

### Включение проверки SHA-256

По умолчанию проверка SHA-256 отключена. Для включения:

```bash
java -Dfemsq.verify.lib.sha256=true -Dloader.path=lib,native-libs -jar femsq-web-*-thin.jar
```

### Логирование

Результаты проверки логируются:

- **INFO:** Успешная проверка
- **WARN:** Предупреждения (отсутствующие optional библиотеки, несовпадение SHA-256)
- **ERROR:** Критические ошибки (отсутствующие required библиотеки, несовпадение версий femsq-*)

---

## Структура директорий

### После первичной установки (Fat JAR)

```
/path/to/app/
└── femsq-web-0.1.0.1-SNAPSHOT.jar (51 MB, содержит всё)
```

### После извлечения библиотек

```
/path/to/app/
├── femsq-web-0.1.0.1-SNAPSHOT.jar (51 MB, можно удалить)
├── lib/ (120 MB, ~300 файлов)
│   ├── femsq-database-0.1.0.1-SNAPSHOT.jar
│   ├── femsq-reports-0.1.0.1-SNAPSHOT.jar
│   ├── spring-boot-3.4.5.jar
│   └── ...
└── native-libs/ (если используется Windows Auth)
    └── mssql-jdbc_auth.dll
```

### После обновления (Thin JAR)

```
/path/to/app/
├── femsq-web-0.1.0.1-SNAPSHOT-thin.jar (700 KB, новый)
├── lib/ (120 MB, существующие библиотеки)
└── native-libs/ (существующие нативные библиотеки)
```

---

## Рекомендации

### Для разработчиков

1. **Всегда создавайте fat JAR** при выпуске новой версии
2. **Проверяйте наличие lib-manifest.json** в fat JAR перед отправкой
3. **Используйте thin JAR** только для обновлений на машинах с уже установленными библиотеками

### Для пользователей

1. **При первой установке:** используйте fat JAR
2. **При обновлении:** используйте thin JAR (если библиотеки уже извлечены)
3. **Не удаляйте папку lib/** после обновления
4. **Проверяйте логи** при запуске thin JAR на наличие предупреждений

---

## Устранение проблем

### Ошибка: "Required library missing"

**Причина:** В `lib/` отсутствует обязательная библиотека.

**Решение:**
1. Извлечь библиотеки из fat JAR (см. раздел "Извлечение библиотек")
2. Или использовать fat JAR вместо thin JAR

### Ошибка: "Version mismatch for femsq-*"

**Причина:** Версия модуля `femsq-*` в `lib/` не совпадает с версией thin JAR.

**Решение:**
1. Обновить библиотеки из нового fat JAR
2. Или использовать fat JAR для обновления

### Предупреждение: "native-libs directory not found"

**Причина:** Папка `native-libs/` отсутствует, но требуется для Windows Authentication.

**Решение:**
1. Извлечь `native-libs/` из fat JAR
2. Или запустить fat JAR один раз для автоматического создания

---

## Связанные документы

- [Windows Authentication Setup](windows-authentication.md)
- [Скрипты развёртывания](../code/scripts/)
- [Project Documentation](../../project/project-docs.json) — раздел `deployment.jar_lifecycle`

---

**Последнее обновление:** 2025-11-27


