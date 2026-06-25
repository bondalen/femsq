# Удалённая разработка: Cursor на Fedora, БД на nb-win

**Последнее обновление:** 2026-06-25

## Схема

```
Fedora (alex-fedora)              WireGuard VPN              nb-win (10.7.0.3)
  Cursor IDE  ───────────────────────────────────────────►  WSL2 + Docker
  DBeaver     ───── TCP 10.7.0.3:1433 ─────────────────────►  femsq-mssql → FishEye
  FEMSQ app   ───── (тот же host:port) ────────────────────►  та же БД
```

Источник данных **не переносится** на Fedora: используется тот же контейнер `femsq-mssql` на nb-win. nb-win должен быть включён и доступен по VPN.

## Быстрый старт после `git pull` (Fedora)

```bash
cd /path/to/femsq

# 1. MCP / DBHub для Cursor
chmod +x code/scripts/setup-cursor-mcp.sh code/scripts/setup-dbhub.sh
./code/scripts/setup-cursor-mcp.sh

# 2. Конфигурация FEMSQ (приложение, не в репозитории)
mkdir -p ~/.femsq
cp docs/development/examples/database.properties.alex-fedora ~/.femsq/database.properties

# 3. Проверка сети (WireGuard должен быть активен)
timeout 3 bash -c 'cat < /dev/null > /dev/tcp/10.7.0.3/1433' && echo OK || echo FAIL

# 4. Перезапустить Cursor (MCP DBHub подхватит новый .cursor/mcp.json)
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

## Реестр окружений

- `docs/project/project-docs.json` → `development.environments.machines`
- `docs/project/extensions/deployment/environments.json`

Машины: `nb-win` (хост БД), `alex-fedora` (удалённый клиент).

## См. также

- [deployment-guide.md](deployment-guide.md) — сборка и запуск FEMSQ
- [chat-resume-26-0310.md](notes/chats/chat-resume/chat-resume-26-0310.md) — ODBC из Hyper-V ВМ к `nb-win,1433` (аналогичный принцип)
