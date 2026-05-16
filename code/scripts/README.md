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

### spMstrg_2605 *(актуальный)*

Заполняет ResultSet-таблицы через `ags.spMstrg_2605` (поддерживает фильтр `@ipgSt`).

**Файл:** `execute_spMstrg_2605.sh`

**Использование:**

```bash
# Выполнить для всех строек (ipgSt = NULL)
./execute_spMstrg_2605.sh

# Или изменить переменные в скрипте:
#   IPGCH=15
#   MONTH_END_DATE="2025-07-31"
#   IPGST=""          # пусто = NULL = все стройки
#   IPGST="12ОПР"    # конкретная группа
```

**Параметры (настраиваются в скрипте):**
- `IPGCH=15` — идентификатор цепи инвестиционных программ
- `MONTH_END_DATE="2025-07-31"` — крайний день месяца для отчёта
- `IPGST=""` — пустая строка = NULL = все стройки; иначе код группы (напр. `12ОПР`)
- `TIMEOUT=600` — таймаут в секундах (10 минут)

**Что делает:**
Вызывает `EXEC ags.spMstrg_2605 @ipgCh=..., @MounthEndDate=..., @ipgSt=..., @saveToTables=1`
→ TRUNCATE + INSERT в `ags.spMstrg_2408_ResultSet1..7`
→ JasperReports читает из этих таблиц при генерации отчёта `mstrgAg_23_Branch_q2m_2408_25`

**Результаты (ipgSt=NULL, ipgCh=15):**
- `spMstrg_2408_ResultSet1` — 12693 строк (полный набор)
- `spMstrg_2408_ResultSet2` — 12693 строк (переупорядоченные столбцы)
- `spMstrg_2408_ResultSet3` — 12693 строк (без ag_, iv_, ia_)
- `spMstrg_2408_ResultSet4` — 0 строк (JOIN трёх месяцев, зависит от данных)
- `spMstrg_2408_ResultSet5` — 1 строка (итоговая фильтрация)
- `spMstrg_2408_ResultSet6` — 0 строк
- `spMstrg_2408_ResultSet7` — 1 строка

**Время выполнения:** ~16–20 сек (на dev, Docker)

---

### spMstrg_2408_SaveToTables *(устаревший, для отката)*

Прежний скрипт — вызывает `ags.spMstrg_2408_SaveToTables` без фильтра `@ipgSt`.  
Оставлен для целей отката (если `_2605`-объекты будут удалены через `05_ROLLBACK.sql`).

**Файлы:**
- `spMstrg_2408_SaveToTables.sql` — SQL-скрипт создания процедуры
- `execute_spMstrg_2408.sh` — Bash-скрипт запуска

**Документация:** `docs/solutions/spMstrg_2408_execution.md`

---

**Дата последнего обновления:** 2026-05-16
