# Thin JAR: Быстрый старт

> Статус на 2026-07-16: thin JAR **0.1.0.136** прошёл G8 и soft-deploy rehearsal  
> (`/home/alex/femsq-test/test-26-0716`: GraphQL + CLI/UI `executeAudit` type=5/3).  
> Фикс parity: явная регистрация `graphql/*.graphqls` в `GraphQlConfig`.

## 📊 Результат оптимизации

| Параметр | Было | Стало | Экономия |
|----------|------|-------|----------|
| **Размер JAR** | 51 МБ | **704 КБ** | **98.6%** ✨ |
| **Время обновления** | ~5 мин | ~10 сек | **97%** ⚡ |
| **Библиотеки** | Внутри JAR | В `lib/` (один раз) | Повторно не передаются |

---

## 🚀 Для пользователя (один раз)

### Шаг 1: Извлечь библиотеки из существующего JAR

```bash
cd /home/user/femsq-test

# Извлекаем библиотеки (выполняется ОДИН РАЗ)
bash extract-libs-from-fatjar.sh femsq-web-0.1.0.1-SNAPSHOT.jar
```

**Результат:**
```
✓ Извлечение завершено!
  Библиотек извлечено: 60
  Размер lib/: 50M
```

### Структура после извлечения:
```
/home/user/femsq-test/
├── lib/                              # 50 МБ (библиотеки)
│   ├── spring-boot-3.4.5.jar
│   ├── jasperreports-7.0.1.jar
│   └── ... (60 файлов)
├── femsq-web-0.1.0.1-SNAPSHOT.jar   # Старый Fat JAR (можно удалить)
└── extract-libs-from-fatjar.sh
```

**✅ Готово! Библиотеки извлечены, больше их передавать не нужно.**

---

## 🔄 Для разработчика (каждое обновление)

### Шаг 2: Собрать Thin JAR

```bash
cd /home/alex/projects/java/spring/vue/femsq/code

# Собираем Thin JAR (без библиотек)
./scripts/build-thin-jar.sh
```

**Результат:**
```
✓ Сборка завершена!
  Fat JAR:  51M
  Thin JAR: 704K  ← Только это и передаём!
```

### Шаг 3: Скопировать Thin JAR пользователю

```bash
# Вариант 1: Локально (для теста)
cp code/femsq-backend/femsq-web/target/femsq-web-0.1.0.1-SNAPSHOT-thin.jar \
   /home/user/femsq-test/

# Вариант 2: По сети
scp code/femsq-backend/femsq-web/target/femsq-web-0.1.0.1-SNAPSHOT-thin.jar \
    user@target-machine:/home/user/femsq-test/
```

**Размер передачи: 704 КБ (вместо 51 МБ!)**

---

## ▶️ Запуск (на машине пользователя)

```bash
cd /home/user/femsq-test

# Запускаем с внешними библиотеками
bash run-with-external-libs.sh \
    femsq-web-0.1.0.1-SNAPSHOT-thin.jar \
    ./lib
```

Или просто:
```bash
bash run-with-external-libs.sh
```

**Приложение запустится, используя библиотеки из `lib/`**

---

## 📦 Сравнение размеров

```bash
# На машине пользователя
ls -lh /home/user/femsq-test/

# Вывод:
# -rw-r--r-- 1 user user  51M  ← femsq-web-0.1.0.1-SNAPSHOT.jar (старый)
# -rw-r--r-- 1 user user 704K  ← femsq-web-0.1.0.1-SNAPSHOT-thin.jar (новый!)
# drwxr-xr-x 2 user user  50M  ← lib/ (60 файлов)
```

---

## 🔧 Обновление библиотек (редко)

Обновление библиотек нужно только при:
- Обновлении версии Spring Boot
- Добавлении новых зависимостей

### Как обновить библиотеки:

```bash
# На машине пользователя удаляем старые
rm -rf /home/user/femsq-test/lib

# Передаём новый Fat JAR (один раз)
scp femsq-web-0.1.0.1-SNAPSHOT.jar user@target-machine:/home/user/femsq-test/

# Извлекаем библиотеки заново
ssh user@target-machine
cd /home/user/femsq-test
bash extract-libs-from-fatjar.sh femsq-web-0.1.0.1-SNAPSHOT.jar
```

---

## ✅ Контрольный список

### Первичная настройка (один раз):
- [x] Извлечены библиотеки из Fat JAR → `lib/` (50 МБ)
- [x] Собран Thin JAR (704 КБ)
- [x] Скопирован скрипт запуска `run-with-external-libs.sh`
- [x] Проверен запуск приложения

### Каждое обновление:
- [ ] Собрать Thin JAR: `./scripts/build-thin-jar.sh`
- [ ] Скопировать только Thin JAR (704 КБ)
- [ ] Перезапустить приложение
- [ ] Проверить parity с fat JAR: `/api/v1/connection/status` = 200, `/actuator/health` = UP, `POST /graphql` != 404
- [ ] Только после этого выполнять smoke `executeAudit`

---

## Blocker G8: parity thin vs fat (снят 2026-07-16)

### Симптом (до фикса, JAR `0.1.0.135`)

- thin JAR стартовал, REST/health работали, но `POST /graphql` = **404**
- в логе не было `Loaded ... GraphQL schema` / `GraphQL endpoint HTTP POST /graphql`
- удаление `classpath.idx` / смена launcher не помогали

### Решение

В `GraphQlConfig` добавлен bean `graphQlSchemaResourcesCustomizer()` с явной регистрацией:
- `graphql/ra-schema.graphqls`
- `graphql/og-schema.graphqls`

### Подтверждение G8 (JAR `0.1.0.136`)

1. `build-thin-jar.sh` → thin JAR + внешний `lib/`
2. startup: `Loaded 2 resource(s) in the GraphQL schema`, `POST /graphql` = 200
3. smoke `executeAudit(14)` dry-run SUMMARY:
   - type=5 **exec 1189** (G8 thin-smoke) / **1193** (soft-deploy `test-26-0716`) — COMPLETED, `ra_stg_ra` = 1720
   - type=3 RALP **exec 1191** / **1194** — COMPLETED, `ra_stg_ralp` = 424 (`af_source=1` обязателен)
4. Soft-deploy UI: AuditsView на http://localhost:8080/ — лог и «Выполнить ревизию» OK

---

## 💡 Преимущества

✅ **Экономия трафика:** 704 КБ вместо 51 МБ при каждом обновлении  
✅ **Скорость:** Обновление за 10 секунд вместо 5 минут  
✅ **Простота:** Библиотеки извлекаются один раз из существующего JAR  
✅ **Откат:** Можно вернуться к Fat JAR в любой момент  
✅ **Безопасность:** Библиотеки изолированы и не меняются при обновлениях приложения

---

## 🆘 Решение проблем

### Приложение не запускается

**Проблема:** `ClassNotFoundException`

**Решение:** Проверьте, что библиотеки извлечены:
```bash
ls -la /home/user/femsq-test/lib/ | wc -l
# Должно быть: 60+ файлов
```

### Библиотеки не найдены

**Проблема:** `Error: Could not find or load main class`

**Решение:** Проверьте путь к `lib/`:
```bash
bash run-with-external-libs.sh \
    femsq-web-0.1.0.1-SNAPSHOT-thin.jar \
    ./lib  # Путь должен быть правильным
```

### Нужно обновить библиотеки

**Решение:** Удалите `lib/` и извлеките заново из нового Fat JAR.

---

## 📞 Поддержка

Полная документация: `docs/deployment/thin-jar-migration.md`

**Дата:** 2025-11-26  
**Версия:** 1.0
