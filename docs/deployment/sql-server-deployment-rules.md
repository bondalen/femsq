# Правила разработки и применения SQL-скриптов для FishEye

**Дата:** 2026-05-18  
**Версия:** 1.0  
**Целевая платформа:** MS SQL Server **2012 SP4** (`11.0.7507.2`) — продуктивный сервер

---

## 1. Источники правды

| Документ | Назначение |
|----------|------------|
| `docs/project/project-docs.json` → `database`, `development.environments` | Версия prod, машины, ссылки |
| `docs/project/extensions/database/compatibility.json` | Ограничения 2012, workarounds |
| `docs/project/extensions/deployment/environments.json` | Краткий реестр dev/prod |
| `docs/deployment/db-upgrade-*.md` | Порядок работ по конкретной задаче |
| `docs/deployment/sql-flash-drive-packaging.md` | **Формирование флеш-носителя** для офлайн-деплоя |

---

## 2. Два контура SQL Server

| Контур | Версия (факт) | Назначение |
|--------|---------------|------------|
| **Продуктив** | SQL Server 2012 SP4 | Единственная цель для DDL/DML пакетов, меняющих объекты `ags.*` |
| **Разработка** | SQL Server 2022 в Docker (`femsq-mssql`) | Быстрые тесты, DBHub; синтаксис 2016+ **не** переносить на prod без адаптации |

Рекомендация для dev: `ALTER DATABASE FishEye SET COMPATIBILITY_LEVEL = 110` — как на продуктиве.

---

## 3. Структура папки SQL-пакета

```
docs/development/notes/sql/{код-задачи}/
├── README.md                 (опционально)
├── 00_VERIFY_before.sql
├── 01_...sql
├── 02_...sql
├── 03_...sql
├── 04_VERIFY_after.sql
├── 05_ROLLBACK.sql
├── 06_...sql                 (опционально)
└── MSSQL2012/                ← ОБЯЗАТЕЛЬНО для продуктива 2012
    ├── README.md
    └── 00 … 06               (те же имена, синтаксис SQL Server 2012)
```

**Правило:** корневая папка может содержать `CREATE OR ALTER` и `DROP IF EXISTS` (удобно на dev).  
Подпапка **`MSSQL2012/`** — единственный набор для применения на продуктиве.

Пример: `docs/development/notes/sql/26-0508/MSSQL2012/`

---

## 4. Запрещено на продуктиве (SQL Server 2012)

| Конструкция | С | Замена |
|-------------|---|--------|
| `CREATE OR ALTER` | 2016 SP1 | `IF OBJECT_ID(...) DROP` + `GO` + `CREATE` |
| `DROP … IF EXISTS` | 2016 | `IF OBJECT_ID(N'ags.name', N'P'/'IF') IS NOT NULL DROP …` |
| `STRING_SPLIT`, JSON-функции | 2016+ | См. `compatibility.json` |

Полный список: `docs/project/extensions/database/compatibility.json` → `limitations_2012`.

---

## 5. Чеклист при создании нового SQL-пакета

1. [ ] Прочитать `compatibility.json` и зафиксировать целевую версию **11.0.7507.2**.
2. [ ] Разработать/протестировать логику на dev (Docker 2022 допустим).
3. [ ] Создать или обновить подпапку **`MSSQL2012/`** (без `CREATE OR ALTER`, без `DROP IF EXISTS`).
4. [ ] Добавить `00_VERIFY_before.sql` с проверкой `@@VERSION` и `package_compat`.
5. [ ] Прогнать `00` → `01`–`03` → `04` на dev в папке `MSSQL2012/` (если есть контейнер).
6. [ ] Оформить `docs/deployment/db-upgrade-{task}.md` и чеклист дня деплоя.
7. [ ] На продуктиве: бэкап → `MSSQL2012/00`–`04` → приёмка → клиенты (Access/FEMSQ).
8. [ ] При офлайн-доставке: собрать флешку по [`sql-flash-drive-packaging.md`](sql-flash-drive-packaging.md).

---

## 7. Флеш-носитель для офлайн-деплоя

Когда с рабочей станции нет доступа к продуктивному SQL Server, пакет `MSSQL2012/` переносят на **флеш-носитель** в структуре `{YY-MMDD}_deploy/` (подпапки `open/` и `archive/`).

| Документ | Содержание |
|----------|------------|
| [`sql-flash-drive-packaging.md`](sql-flash-drive-packaging.md) | Полный порядок: структура, ZIP, PDF, git, чеклист сборки |
| `{код}/{YY-MMDD}_deploy/build_flash_package.sh` | Скрипт сборки (пример: `26-0604/26-0616_deploy/`) |

**Правило:** в git — рецепт сборки и шаблоны; `open/` и `archive/*.zip` — артефакты, не коммитятся.

---

## 8. Проверка версии перед деплоем

```sql
SELECT @@VERSION;
SELECT SERVERPROPERTY('ProductMajorVersion') AS major_version;
-- Для пакета MSSQL2012: major_version должен быть 11
```

В `00_VERIFY_before.sql` (MSSQL2012) ожидается: `package_compat = OK for MSSQL2012 package`.

---

## История изменений

| Версия | Дата | Описание |
|--------|------|----------|
| 1.0 | 2026-05-18 | Первый выпуск; конвенция MSSQL2012/ после опыта spMstrg_2605 |
| 1.1 | 2026-06-16 | §7 флеш-носитель; ссылка на sql-flash-drive-packaging.md |
