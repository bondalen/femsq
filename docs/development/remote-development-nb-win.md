# Удалённая разработка: Cursor на Fedora, БД на nb-win

**Последнее обновление:** 2026-07-09

## Схема

```
Fedora (alex-fedora)              WireGuard VPN              nb-win (10.7.0.3)
  Cursor IDE  ───────────────────────────────────────────►  WSL2 + Docker
  DBeaver     ───── TCP 10.7.0.3:1433 ─────────────────────►  femsq-mssql → FishEye
  FEMSQ app   ───── (тот же host:port) ────────────────────►  та же БД
```

Источник данных **не переносится** на Fedora: используется тот же контейнер `femsq-mssql` на nb-win. nb-win должен быть включён и доступен по VPN.

**Excel-файлы ревизий** хранятся на nb-win в общей SMB-шаре и монтируются на обеих машинах в **один и тот же Linux-путь** `/mnt/nb-win-share`. Локальная копия `docs/excel/` в репозитории **не используется** (папка в `.gitignore`).

## Общее хранилище Excel (SMB + единый mount)

| Параметр | Значение |
|----------|----------|
| Windows-папка (nb-win) | `D:\wire-guard-share-nb-win` |
| Имя SMB-шары | `wire-guard-share-nb-win` |
| UNC | `\\10.7.0.3\wire-guard-share-nb-win` |
| Linux mount (обе машины) | `/mnt/nb-win-share` |
| Корень каталогов Excel | `/mnt/nb-win-share/femsq/excel/` |
| Пример снимка (март 2026) | `.../excel/2026_03/` |
| Пример снимка (июль 2026) | `.../excel/2026-07/` |

### Именование подпапок (снимки состояния файлов)

Подпапки в `femsq/excel/` именуются по **трём компонентам**:

1. **Год данных** — за какой отчётный год содержимое файлов.
2. **Год состояния** — на какой момент (год) актуализирован снимок файлов.
3. **Месяц состояния** — месяц снимка (две цифры).

**Правило слияния:** если год данных и год состояния **совпадают**, в имени папки остаётся **один** год, затем месяц.

| Имя папки | Год данных | Год состояния | Месяц | Пояснение |
|-----------|------------|---------------|-------|-----------|
| `2025_2026_01` | 2025 | 2026 | 01 | все три компонента различны |
| `2026_03` | 2026 | 2026 | 03 | годы совпали → `2026` + `_` + `03` |
| `2026-07` | 2026 | 2026 | 07 | то же слияние; в имени использован `-` между годом и месяцем |

Разные снимки позволяют **тестировать ревизию на разных версиях** одних и тех же типов файлов (март vs июль и т.д.) без копирования в репозиторий.

Перед прогоном ревизии обновите в БД `ags.ra_dir.dir` и полные пути `ags.ra_f.af_name` на нужную подпапку — вручную или скриптом:

```bash
./code/scripts/audit-switch-excel-snapshot.sh march   # 2026_03
./code/scripts/audit-switch-excel-snapshot.sh july    # 2026-07
```

### База RALP (`af_type=3`) для dev/smoke

**Мартовский снимок `2026_03` — эталонный перечень документов** (меньший набор). Июльский `2026-07` — расширенный снимок для теста apply/отката.

| Метрика | **Март** `2026_03` | **Июль** `2026-07` |
|---------|-------------------|-------------------|
| Строк в Excel (num+date+cst+og) | **424** | **1262** |
| Staging (valid, cst+og resolved) | **420** | **1248** |
| `ralpRaAu` (при непустом `arrived`) | **408** | **1248** |
| Только в этом файле | 0 | **+838** |
| В обоих файлах | 424 | 424 |
| Разное состояние (arrived/sent/…) в общих | — | **15** |

**Домен dev (мартовская база):** `ralpRa_2026=420`, `ralpRaAu_2026=408` (12 записей без `arrived` — Au не создаётся, как в VBA).

**UAT через UI (2026-07-10):** ревизия `adt_key=14`, exec **1162–1166** — функционально пройден (март dry → июль dry → apply → откат → идемпотентность). **Blocker:** читаемость лога `adt_results` — задача **0049**, chat-plan §9.3.3–9.3.4, `ra-execution-operations.md` → «Читаемость лога в UI».

Скрипты:

```bash
# Сравнение перечней в Excel
python3 code/scripts/compare-ralp-excel-snapshots.py

# Обрезка домена до мартовского перечня (staging exec_key=1152)
# sqlcmd ... -i code/scripts/trim-ralp-domain-to-march-baseline.sql

# Откат к марту после эксперимента с июлем
./code/scripts/rollback-ralp-to-march-baseline.sh
```

| Пример type=3 | `(2026)_Аренда_рабочий.xlsx` (`2026_03` — baseline 420; `2026-07` — apply +838) |
| Пример type=5 | `2026 Свод инф-ции по ОА.xlsm` |

Пути в БД (`ags.ra_dir.dir`, `ags.af.af_name`) указывают на **полный путь внутри mount**, например:
`/mnt/nb-win-share/femsq/excel/2026_03/(2026)_Аренда_рабочий.xlsx`.

### Fedora (CIFS mount)

```bash
# 1. Учётные данные (один раз)
cp docs/development/examples/smbcredentials.example ~/.smbcredentials
nano ~/.smbcredentials   # заполнить password
chmod 600 ~/.smbcredentials

# 2. Монтирование (после git pull или после перезагрузки)
./code/scripts/mount-nb-win-share.sh
# Допустимо и: sudo ./code/scripts/mount-nb-win-share.sh
# Учётные данные всегда берутся из ~/.smbcredentials пользователя (не из /root).

# 3. Проверка
ls -la /mnt/nb-win-share/femsq/excel/2026_03/
```

Требуется WireGuard до `10.7.0.3`. Пакет `cifs-utils` должен быть установлен.

### nb-win (WSL bind mount)

На nb-win шара уже лежит на диске `D:`; в WSL достаточно **bind mount** в тот же путь, что на Fedora:

```bash
# В терминале WSL на nb-win (после git pull или перезагрузки)
./code/scripts/mount-nb-win-share-wsl.sh
```

Скрипт выполняет: `sudo mount --bind /mnt/d/wire-guard-share-nb-win /mnt/nb-win-share`.

Проверка:

```bash
ls -la /mnt/nb-win-share/femsq/excel/2026_03/
```

**Важно:** команды монтирования выполняются в **терминале WSL**, не в PowerShell. Cursor на nb-win (если открыт на WSL-проекте) использует те же пути `/mnt/nb-win-share/...`.

### Быстрый старт после `git pull` (nb-win, WSL)

```bash
cd ~/projects/femsq   # или ваш путь к клону

git pull
./code/scripts/mount-nb-win-share-wsl.sh
./code/scripts/setup-cursor-mcp.sh   # при необходимости
```

## Быстрый старт после `git pull` (Fedora)

```bash
cd /path/to/femsq

# 1. MCP / DBHub для Cursor
chmod +x code/scripts/setup-cursor-mcp.sh code/scripts/setup-dbhub.sh
./code/scripts/setup-cursor-mcp.sh

# 2. Конфигурация FEMSQ (приложение, не в репозитории)
mkdir -p ~/.femsq
cp docs/development/examples/database.properties.alex-fedora ~/.femsq/database.properties

# 3. SMB-шара с Excel (WireGuard должен быть активен)
./code/scripts/mount-nb-win-share.sh

# 4. Проверка сети (WireGuard должен быть активен)
timeout 3 bash -c 'cat < /dev/null > /dev/tcp/10.7.0.3/1433' && echo OK || echo FAIL

# 5. Перезапустить Cursor (MCP DBHub подхватит новый .cursor/mcp.json)
```

## Параметры подключения (alex-fedora)

| Параметр | Значение |
|----------|----------|
| Host | `10.7.0.3` (WireGuard IP nb-win) |
| Port | `1433` |
| Database | `FishEye` |
| Schema | `ags` |
| Username | `sa` |
| Password | dev-пароль из `docs/development/examples/database.properties.alex-fedora` |
| Encrypt | `false`, `trustServerCertificate=true` |

## DBeaver

Новое подключение → Microsoft SQL Server → параметры из таблицы выше.  
Проверка: `SELECT @@VERSION, DB_NAME(), SUSER_SNAME();`

## SSMS на nb-win (winget)

SSMS **не** обновляется через патчи Windows 11; установка и апгрейд — **winget** или Visual Studio Installer.

Пример установки SSMS 22 на `D:\Program_Files\SSMS` (PowerShell от администратора):

```powershell
mkdir D:\Program_Files\SSMS -Force
winget install --id Microsoft.SQLServerManagementStudio.22 -e `
  --accept-package-agreements --accept-source-agreements `
  --override '--installPath "D:\Program_Files\SSMS" --passive --norestart'
```

Подключение в SSMS: `localhost,1433`, база `FishEye`, логин `sa` (пароль из `docs/development/examples/database.properties.nb-win`).

Обновление: `winget upgrade --id Microsoft.SQLServerManagementStudio.22 -e`

На Fedora для скриптов и сеток результатов — **Cursor + расширение MSSQL** (`10.7.0.3`); приёмка `07n`/`07o`/`07p` — **sqlcmd**.

## Cursor / DBHub

- Шаблон MCP: `.cursor/mcp.remote-nb-win.json.example` (DSN с `10.7.0.3`)
- Рабочий файл: `.cursor/mcp.json` (в `.gitignore`, создаётся скриптом)
- Установка DBHub: `./code/scripts/setup-dbhub.sh`

## nb-win (сервер БД)

| Параметр | Значение |
|----------|----------|
| Контейнер | `femsq-mssql` |
| WireGuard интерфейс | `nb-win-cloud-ru` |
| WireGuard IP | `10.7.0.3` |
| Локальный доступ | `localhost:1433` |

Проверка контейнера на nb-win:

```bash
docker ps --filter name=femsq-mssql
```

Если с Fedora порт недоступен — на nb-win (PowerShell от администратора):

```powershell
New-NetFirewallRule -DisplayName "FEMSQ SQL Docker via WireGuard" `
  -Direction Inbound -Protocol TCP -LocalPort 1433 `
  -RemoteAddress 10.7.0.0/24 -Action Allow
```

Подсеть VPN замените на актуальную, если отличается от `10.7.0.0/24`.

## Шаблоны в репозитории

| Файл | Назначение |
|------|------------|
| `.cursor/mcp.json.example` | nb-win, `localhost:1433` |
| `.cursor/mcp.remote-nb-win.json.example` | Fedora, `10.7.0.3:1433` |
| `docs/development/examples/database.properties.nb-win` | FEMSQ на nb-win |
| `docs/development/examples/database.properties.alex-fedora` | FEMSQ на Fedora |
| `docs/development/examples/smbcredentials.example` | Шаблон `~/.smbcredentials` для CIFS |
| `code/scripts/mount-nb-win-share.sh` | CIFS mount на Fedora |
| `code/scripts/mount-nb-win-share-wsl.sh` | bind mount в WSL на nb-win |
| `code/scripts/watch-audit-progress.sh` | мониторинг хода `executeAudit` в терминале |
| `code/scripts/audit-switch-excel-snapshot.sh` | переключение `ra_dir` / пути RALP: `march` \| `july` |
| `code/scripts/rollback-ralp-to-march-baseline.sh` | откат домена RALP к мартовской базе (420/408) |
| `code/scripts/compare-ralp-excel-snapshots.py` | сравнение перечней документов в двух Excel |
| `code/scripts/trim-ralp-domain-to-march-baseline.sql` | обрезка домена до мартовского перечня (420) |
| `code/scripts/smoke-ralp-march-vs-july.sh` | smoke RALP: март dry-run → июль dry-run → июль apply |

## Реестр окружений

- `docs/project/project-docs.json` → `development.environments.machines`
- `docs/project/extensions/deployment/environments.json`

Машины: `nb-win` (хост БД), `alex-fedora` (удалённый клиент).

## См. также

- [deployment-guide.md](deployment-guide.md) — сборка и запуск FEMSQ
- [chat-resume-26-0310.md](notes/chats/chat-resume/chat-resume-26-0310.md) — ODBC из Hyper-V ВМ к `nb-win,1433` (аналогичный принцип)
