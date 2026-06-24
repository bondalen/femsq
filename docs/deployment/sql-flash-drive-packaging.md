# Формирование флеш-носителя с SQL-пакетом для продуктива

**Файл:** `docs/deployment/sql-flash-drive-packaging.md`  
**Дата:** 2026-06-16  
**lastUpdated:** 2026-06-16  
**Версия:** 1.0  
**Автор:** Александр

**Связанные документы:**

- [`sql-server-deployment-rules.md`](sql-server-deployment-rules.md) — конвенция `MSSQL2012/`, синтаксис 2012
- [`db-upgrade-spMstrg-2606.md`](db-upgrade-spMstrg-2606.md) — порядок деплоя задачи
- [`db-upgrade-spMstrg-2606-deploy-day-checklist.md`](db-upgrade-spMstrg-2606-deploy-day-checklist.md) — чеклист дня деплоя

---

## 1. Когда нужна флешка

Используйте офлайн-пакет, если с рабочей станции разработки **нет сетевого доступа** к продуктивному SQL Server (машина `prod-fisheye`, `SPB-05-NV-SQL1`). Деплой выполняется в **SSMS** под **Windows Authentication**.

Источник SQL в репозитории — папка **`MSSQL2012/`** внутри задачи (`docs/development/notes/sql/{код}/`). Флешка — **снимок релиза**, а не второй источник правды.

---

## 2. Именование папки релиза

```
docs/development/notes/sql/{код-задачи}/{YY-MMDD}_deploy/
```

Пример для `spMstrg_2606`: `26-0616_deploy` (сборка 2026-06-16).

| Элемент | Значение |
|---------|----------|
| `{код-задачи}` | как у SQL-пакета (`26-0604`) |
| `{YY-MMDD}` | дата **сборки** флешки (не дата деплоя на prod) |

---

## 3. Структура на флеш-носителе

После сборки на флешку копируется **вся** папка `{YY-MMDD}_deploy/`:

```
{YY-MMDD}_deploy/
├── README_DEPLOY.txt       ← первый файл: назначение, пароль (без самого пароля)
├── MANIFEST.sha256         ← SHA-256 всех файлов в open/
│
├── open/                   ← рабочая копия для SSMS (без пароля)
│   ├── 01_MSSQL2012/       ← DDL/DML пакет (копия MSSQL2012/)
│   ├── 02_acceptance/      ← скрипты приёмки после деплоя
│   ├── 03_docs/            ← PDF чеклиста + краткая инструкция
│   └── 04_prod_log/        ← шаблоны логов (заполняются на prod)
│
└── archive/                ← резервная копия open/
    ├── {имя}_YYYYMMDD.zip  ← ZIP с паролем (AES, ZipCrypto legacy на Win2012)
    └── {имя}_YYYYMMDD.zip.sha256
```

### Назначение подпапок

| Подпапка | Назначение |
|----------|------------|
| `open/` | Прямая работа в SSMS: **File → Open** по порядку из `01_MSSQL2012/README.md` |
| `archive/` | Резерв при повреждении `open/`; контроль целостности по `.sha256` |

На одном носителе лежат и открытая, и архивная копии: шифрование архива **не защищает** от утери флешки, но даёт резерв и проверку целостности при переносе.

---

## 4. Содержимое `open/`

### 4.1. `01_MSSQL2012/`

Копия **`MSSQL2012/`** целиком (только синтаксис SQL Server 2012). Порядок применения — в `README.md` внутри папки.

**Не включать в первый прогон без gate:** `06b` (SP-path) — только после `07_VERIFY_spFn2_schema.sql` на prod.

**Не включать:** скрипты dev-контура (`CREATE OR ALTER` из корня задачи), `06c` (патч лога `_2605`).

### 4.2. `02_acceptance/`

Скрипты из корня задачи (не дублируются в `MSSQL2012/`):

| Файл | Когда выполнять |
|------|-----------------|
| `07_VERIFY_spMstrg_2606_chain5.sql` | После `06`, эталон `@MounthEndDate='2022-12-31'` |
| `07_VERIFY_spFn2_schema.sql` | Только если применялись `04b`/`05b`/`06b` |

### 4.3. `03_docs/`

| Файл | Источник |
|------|----------|
| `db-upgrade-spMstrg-2606-deploy-day-checklist.pdf` | из `docs/deployment/` (см. §6) |
| `db-upgrade-spMstrg-2606.md` | краткий порядок (копия) |
| `DEV_ACCEPTANCE_SUMMARY.txt` | эталоны dev-приёмки (RS1, RS4, даты) |

### 4.4. `04_prod_log/`

| Файл | Назначение |
|------|------------|
| `deploy_log_TEMPLATE.txt` | таблица: скрипт \| время \| ✓ \| примечание |
| `00_VERIFY_before_OUTPUT.txt` | пустой — вставить вывод precheck |

---

## 5. Архив `archive/`

| Параметр | Значение |
|----------|----------|
| Формат | **ZIP** (встроен в Windows Server 2012 R2 / проводник) |
| Имя | `{task}_MSSQL2012_{YYYYMMDD}.zip`, напр. `spMstrg_2606_MSSQL2012_20260616.zip` |
| Содержимое | дерево `open/` (не весь репозиторий) |
| Пароль | AES-256 через `zip -P` или «Защита паролем» в проводнике Windows |
| Передача пароля | **отдельно** от флешки (устно, другой канал); **не в git**, **не в README** |

После создания архива:

```bash
sha256sum archive/*.zip > archive/*.zip.sha256
```

---

## 6. Сборка пакета (репозиторий)

Скрипт: `docs/development/notes/sql/{код}/{YY-MMDD}_deploy/build_flash_package.sh`

```bash
cd docs/development/notes/sql/26-0604/26-0616_deploy
./build_flash_package.sh
# ZIP с паролем (переменная окружения, не файл в репо):
DEPLOY_ARCHIVE_PASSWORD='…' ./build_flash_package.sh --zip-password
```

Скрипт:

1. Заполняет `open/` из `MSSQL2012/`, acceptance, docs
2. Регенерирует PDF чеклиста (`generate_checklist_pdf.py`)
3. Пишет `MANIFEST.sha256` по `open/`
4. Создаёт `archive/*.zip` (Python `zipfile`, пароль опционально)
5. Пишет `archive/*.zip.sha256`

**Копирование на флешку:** скопировать каталог `26-0616_deploy/` целиком на носитель (например `E:\FEMSQ\26-0616_deploy\`).

---

## 7. Контрольный чеклист сборки

| # | Действие | ✓ |
|---|----------|---|
| F.1 | Dev-приёмка PASS (`run_acceptance_dev_chain5.sh`) | ☐ |
| F.2 | `MSSQL2012/` синхронизирован (`_sync_to_mssql2012.py` при изменениях 03b1/03c) | ☐ |
| F.3 | `./build_flash_package.sh` без ошибок | ☐ |
| F.4 | `MANIFEST.sha256` соответствует `open/` на флешке | ☐ |
| F.5 | PDF чеклиста открывается на nb-win | ☐ |
| F.6 | `01_MSSQL2012/00_VERIFY_before.sql` открывается в SSMS | ☐ |
| F.7 | Пароль архива передан исполнителю отдельно | ☐ |
| F.8 | Precheck prod зафиксирован в PDF/чеклисте | ☐ |

---

## 8. Git: что отслеживать

| Путь | В git |
|------|-------|
| `{YY-MMDD}_deploy/README_DEPLOY.txt` | да |
| `build_flash_package.sh`, `generate_checklist_pdf.py` | да |
| `templates/` (шаблоны `04_prod_log`, эталон PDF) | да |
| `open/` | **нет** (артефакт сборки) |
| `archive/*.zip` | **нет** |
| `archive/*.zip.sha256` | опционально (фиксация релиза) |
| `.venv_pdf/` | **нет** |

Строки в `.gitignore` — см. корневой `.gitignore`, секция `*_deploy/`.

---

## 9. История изменений

| Версия | Дата | Описание |
|--------|------|----------|
| 1.0 | 2026-06-16 | Первый выпуск; ZIP; пакет `26-0616_deploy` для spMstrg_2606 |
