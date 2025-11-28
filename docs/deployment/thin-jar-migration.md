# Миграция на Thin JAR: Руководство

## Обзор

Данное руководство описывает процесс миграции с Fat JAR (51 МБ) на Thin JAR (~1.5 МБ) для минимизации объёма передаваемых обновлений.

### Преимущества Thin JAR

| Параметр | Fat JAR | Thin JAR |
|----------|---------|----------|
| Размер при обновлении | 51 МБ | ~1.5 МБ |
| Экономия | - | **97%** |
| Первичный деплой | 51 МБ | 51 МБ (один раз) |
| Последующие обновления | 51 МБ | **1.5 МБ** |

---

## Этап 1: Миграция на машине пользователя (ОДИН РАЗ)

### Предварительные условия
- Существующий Fat JAR уже установлен на машине пользователя
- Доступ к терминалу на машине пользователя

### Шаг 1.1: Извлечение библиотек

На машине **пользователя** выполните:

```bash
# Переходим в директорию с текущим JAR
cd /home/user/femsq-test  # или путь к вашему JAR

# Извлекаем библиотеки из существующего Fat JAR
bash extract-libs-from-fatjar.sh femsq-web-0.1.0.1-SNAPSHOT.jar
```

**Результат:**
```
=== FEMSQ: Извлечение библиотек из Fat JAR ===
Fat JAR: femsq-web-0.1.0.1-SNAPSHOT.jar
Целевая директория: .

Создаём директорию ./lib...
Извлекаем библиотеки из BOOT-INF/lib/...
Перемещаем библиотеки...

✓ Извлечение завершено!
  Библиотек извлечено: 61
  Размер lib/: 50M
  Директория: ./lib
```

### Шаг 1.2: Проверка структуры

Убедитесь, что структура выглядит так:

```
/home/user/femsq-test/
├── lib/                              # 50 МБ (библиотеки)
│   ├── spring-boot-3.4.5.jar
│   ├── spring-web-6.2.6.jar
│   ├── jasperreports-7.0.1.jar
│   └── ... (всего 61 файл)
├── femsq-web-0.1.0.1-SNAPSHOT.jar   # 51 МБ (старый Fat JAR)
└── extract-libs-from-fatjar.sh
```

**Важно:** Старый Fat JAR больше не нужен после извлечения библиотек!

---

## Этап 2: Сборка Thin JAR на машине разработчика

### Шаг 2.1: Сборка Thin JAR

На машине **разработчика** выполните:

```bash
cd /home/alex/projects/java/spring/vue/femsq/code

# Собираем Thin JAR
./scripts/build-thin-jar.sh
```

**Результат:**
```
=== FEMSQ: Сборка Thin JAR ===
Проект: /home/alex/projects/java/spring/vue/femsq/code

Сборка модулей femsq-reports и femsq-web...
[INFO] BUILD SUCCESS

Создаём Thin JAR (без библиотек)...
Обновляем MANIFEST.MF...

✓ Сборка завершена!
  Fat JAR:  51M  (femsq-web-0.1.0.1-SNAPSHOT.jar)
  Thin JAR: 1.5M (femsq-web-0.1.0.1-SNAPSHOT-thin.jar)

Экономия при обновлении: 51M → 1.5M
```

### Шаг 2.2: Проверка Thin JAR

```bash
ls -lh code/femsq-backend/femsq-web/target/ | grep thin

# Ожидаемый результат:
# -rw-r--r-- 1 alex alex 1.5M ... femsq-web-0.1.0.1-SNAPSHOT-thin.jar
```

---

## Этап 3: Деплой Thin JAR

### Шаг 3.1: Копирование на машину пользователя

```bash
# На машине разработчика
scp code/femsq-backend/femsq-web/target/femsq-web-0.1.0.1-SNAPSHOT-thin.jar \
    user@target-machine:/home/user/femsq-test/

# Копируем также скрипт запуска
scp code/scripts/run-with-external-libs.sh \
    user@target-machine:/home/user/femsq-test/
```

**Размер передачи: ~1.5 МБ** (вместо 51 МБ!)

### Шаг 3.2: Запуск на машине пользователя

```bash
cd /home/user/femsq-test

# Запускаем с внешними библиотеками
bash run-with-external-libs.sh \
    femsq-web-0.1.0.1-SNAPSHOT-thin.jar \
    ./lib
```

**Вывод:**
```
=== FEMSQ: Запуск с внешними библиотеками ===
Thin JAR: femsq-web-0.1.0.1-SNAPSHOT-thin.jar
Библиотеки: ./lib (61 файлов)

Запуск приложения...
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
```

---

## Этап 4: Последующие обновления

### Процесс обновления (каждый раз)

1. **На машине разработчика:**
   ```bash
   cd /home/alex/projects/java/spring/vue/femsq/code
   ./scripts/build-thin-jar.sh
   ```

2. **Копируем только Thin JAR (1.5 МБ):**
   ```bash
   scp code/femsq-backend/femsq-web/target/femsq-web-0.1.0.1-SNAPSHOT-thin.jar \
       user@target-machine:/home/user/femsq-test/
   ```

3. **На машине пользователя перезапускаем:**
   ```bash
   # Останавливаем текущее приложение (Ctrl+C)
   
   # Запускаем обновлённую версию
   bash run-with-external-libs.sh \
       femsq-web-0.1.0.1-SNAPSHOT-thin.jar \
       ./lib
   ```

**Время обновления: ~10-15 секунд** (вместо минут для 51 МБ)

---

## Обновление библиотек

### Когда нужно обновлять lib/?

Обновление `lib/` требуется только при:
- Изменении версий Spring Boot
- Добавлении новых зависимостей
- Обновлении major версий библиотек

### Как обновить библиотеки?

**Вариант 1: Полное обновление (рекомендуется при major изменениях)**

```bash
# На машине пользователя удаляем старые библиотеки
rm -rf /home/user/femsq-test/lib

# Копируем новый Fat JAR
scp femsq-web-0.1.0.1-SNAPSHOT.jar user@target-machine:/home/user/femsq-test/

# Извлекаем библиотеки заново
ssh user@target-machine
cd /home/user/femsq-test
bash extract-libs-from-fatjar.sh femsq-web-0.1.0.1-SNAPSHOT.jar
```

**Вариант 2: Инкрементальное обновление (при minor изменениях)**

```bash
# На машине разработчика извлекаем новые библиотеки
cd code/femsq-backend/femsq-web/target
mkdir -p temp-libs
unzip -q femsq-web-0.1.0.1-SNAPSHOT.jar 'BOOT-INF/lib/*' -d temp-libs
mv temp-libs/BOOT-INF/lib/*.jar temp-libs/

# Копируем только новые/изменённые библиотеки
rsync -av --update temp-libs/ user@target-machine:/home/user/femsq-test/lib/
```

---

## Автоматизация с помощью версионирования

### Скрипт умного обновления

Создайте файл `smart-deploy.sh`:

```bash
#!/bin/bash
# Умный деплой: определяет, нужно ли обновлять библиотеки

REMOTE_USER="user"
REMOTE_HOST="target-machine"
REMOTE_DIR="/home/user/femsq-test"

# Текущая версия библиотек
LIB_VERSION_FILE="code/femsq-backend/femsq-web/lib-version.txt"
REMOTE_LIB_VERSION=$(ssh $REMOTE_USER@$REMOTE_HOST "cat $REMOTE_DIR/lib-version.txt 2>/dev/null || echo '0'")
LOCAL_LIB_VERSION=$(cat $LIB_VERSION_FILE)

if [ "$REMOTE_LIB_VERSION" != "$LOCAL_LIB_VERSION" ]; then
    echo "Требуется обновление библиотек: $REMOTE_LIB_VERSION -> $LOCAL_LIB_VERSION"
    # Полное обновление
    scp code/femsq-backend/femsq-web/target/femsq-web-0.1.0.1-SNAPSHOT.jar \
        $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/
    ssh $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && bash extract-libs-from-fatjar.sh"
    scp $LIB_VERSION_FILE $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/
else
    echo "Библиотеки актуальны, копируем только Thin JAR"
    scp code/femsq-backend/femsq-web/target/femsq-web-0.1.0.1-SNAPSHOT-thin.jar \
        $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/
fi
```

---

## Откат к Fat JAR

Если возникли проблемы, можно вернуться к Fat JAR:

```bash
# На машине пользователя
cd /home/user/femsq-test

# Запускаем старый Fat JAR (если сохранили)
java -jar femsq-web-0.1.0.1-SNAPSHOT.jar

# Или копируем новый Fat JAR с машины разработчика
```

---

## FAQ

### Q: Можно ли удалить старый Fat JAR после извлечения библиотек?
**A:** Да, после успешного извлечения библиотек старый Fat JAR не нужен. Но рекомендуется сохранить одну копию на случай отката.

### Q: Что если изменилась только одна библиотека?
**A:** Можно скопировать только изменённую библиотеку в `lib/`, но проще использовать инкрементальное обновление с `rsync`.

### Q: Работает ли это на Windows?
**A:** Да, но вместо `bash` скриптов используйте PowerShell или `.bat` файлы. Принцип тот же.

### Q: Можно ли использовать разные версии библиотек для разных приложений?
**A:** Да, создайте отдельные директории `lib/` для каждого приложения.

---

## Контрольный список миграции

- [ ] Извлечены библиотеки из существующего Fat JAR на машине пользователя
- [ ] Создана директория `lib/` с 61 библиотекой (~50 МБ)
- [ ] Собран Thin JAR на машине разработчика (~1.5 МБ)
- [ ] Успешно запущено приложение с внешними библиотеками
- [ ] Проверена работоспособность всех функций
- [ ] Обновлены скрипты деплоя
- [ ] Документированы изменения

---

**Дата создания:** 2025-11-24  
**Версия:** 1.0  
**Автор:** Александр
