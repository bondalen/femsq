# SQL Scripts

Скрипты для работы с базой данных FishEye

## Резервное копирование FishEye

**Скрипт:** `backup-fisheye.sh` — `BACKUP DATABASE` в контейнере `femsq-mssql`, копия `.bak` на диск **D:** (вне `docker_data.vhdx`).

**Каталог (WSL):** `/mnt/d/Backups/femsq/database/` → `daily` | `manual` | `before-docker` | `archive`

```bash
./backup-fisheye.sh              # daily, ротация 7 копий
./backup-fisheye.sh manual         # перед SQL-изменениями
./backup-fisheye.sh before-docker  # перед обновлением Docker Desktop
./backup-fisheye.sh archive        # долгосрочные снимки
BACKUP_LABEL=метка ./backup-fisheye.sh manual
```

Пароль: `~/.femsq/database.properties` или `FEMSQ_DB_PASSWORD` / `SA_PASSWORD`.

**Первый архивный бэкап (2026-05-15):** `D:\Backups\femsq\database\archive\FishEye_20260515_first.bak` (~126 МБ).

---

## Скрипты выполнения процедур

### spMstrg_2408_SaveToTables

Модифицированная версия процедуры `ags.spMstrg_2408` для сохранения результатов в таблицы.

**Файлы:**
- `spMstrg_2408_SaveToTables.sql` - SQL-скрипт создания процедуры
- `execute_spMstrg_2408.sh` - Bash-скрипт для выполнения с таймаутом 10 минут

**Использование:**

```bash
# Выполнить процедуру с параметрами по умолчанию
./execute_spMstrg_2408.sh
```

**Параметры (настраиваются в скрипте):**
- `IPGCH=15` - Идентификатор цепи инвестиционных программ
- `MONTH_END_DATE="2025-07-31"` - Крайний день месяца для отчёта
- `TIMEOUT=600` - Таймаут в секундах (10 минут)

**Результаты:**
- `ags.spMstrg_2408_ResultSet1` - Полный набор данных (12693 записей, 179 столбцов)
- `ags.spMstrg_2408_ResultSet2` - Переупорядоченные столбцы (12693 записей, 179 столбцов)
- `ags.spMstrg_2408_ResultSet3` - Столбцы без ag_, iv_, ia_ (12693 записей, 220 столбцов)
- `ags.spMstrg_2408_ResultSet4` - Данные с JOIN для трёх месяцев (744 записи, 44 столбца)
- `ags.spMstrg_2408_ResultSet5` - Данные с фильтрацией "всего" (32 записи, 44 столбца)
- `ags.spMstrg_2408_ResultSet6` - Данные с источниками освоения (32 записи, 51 столбец)

**Время выполнения:** ~2 минуты (126 секунд)

**Документация:** См. `docs/solutions/spMstrg_2408_execution.md`

---

**Дата последнего обновления:** 2026-05-15
