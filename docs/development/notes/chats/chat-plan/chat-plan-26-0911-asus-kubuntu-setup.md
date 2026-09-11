# План: донастройка окружения FEMSQ на asus-kubuntu (Kubuntu 24.04)

**Дата создания:** 2026-09-11  
**Последнее обновление:** 2026-09-11  
**Проект:** FEMSQ  
**Версия плана:** 1.0.0  
**Автор:** Александр  
**Статус плана:** ✅ этапы 0–6 завершены (2026-09-11)  
**Связанная документация:**
- [remote-development-nb-win.md](../../../remote-development-nb-win.md) — схема удалённой разработки (Fedora + Kubuntu → nb-win)
- [project-docs.json](../../../../project/project-docs.json) → `development.environments.machines`
- `.cursorrules` — проверка окружения при старте чата
- Шаблон БД: [database.properties.alex-fedora](../../../examples/database.properties.alex-fedora)
- Скрипты: `code/scripts/setup-cursor-mcp.sh`, `setup-dbhub.sh`, `check-fequlib.sh`, `mount-nb-win-share.sh`

**Резюме чата:** [chat-resume-26-0911-asus-kubuntu-setup.md](../chat-resume/chat-resume-26-0911-asus-kubuntu-setup.md)

---

## 0. Зачем

Проект открыт на **новой машине** `asus-kubuntu` (Ubuntu 24.04.5 LTS / Kubuntu). В реестре `development.environments.machines` её нет; автопроверка окружения не может выбрать профиль.

По факту машина уже работает в режиме **удалённой станции** (как `alex-fedora`): WireGuard → Docker SQL на nb-win (`10.7.0.3:1433`), SMB-шара Excel смонтирована. Не хватает toolchain (Java/Maven/Node), конфига приложения, клона feQuLib и записи в реестре.

**Цель чата:** довести `asus-kubuntu` до полноценной удалённой рабочей станции FEMSQ и зафиксировать это в документации/скриптах.

**Вне scope:**
- локальный Docker SQL на Kubuntu (не нужен, пока есть nb-win);
- Kerberos SSO к prod (опционально позже);
- перенос данных с nb-win / смена источника БД.

---

## 1. Снимок проверки (2026-09-11)

| Компонент | Статус | Комментарий |
|-----------|--------|-------------|
| Hostname / OS | `asus-kubuntu` / Ubuntu 24.04.5 | ✅ в реестре (2026-09-11) |
| WireGuard `vps-vpn` | ✅ | IP `10.7.0.2`, ping `10.7.0.3` OK |
| SQL `10.7.0.3:1433` | ✅ | remote Docker `femsq-mssql` на nb-win |
| SQL `localhost:1433` | ❌ | ожидаемо (локального контейнера нет) |
| SMB `/mnt/nb-win-share` | ✅ | CIFS, excel-снимки на месте |
| DBHub (`.cursor/dbhub`) | ✅ | `dist/index.js` есть |
| `.cursor/mcp.json` | ✅ | DSN на `10.7.0.3` (как Fedora) |
| `~/.femsq/database.properties` | ✅ | из шаблона Fedora, mode 600 |
| Java / Maven | ✅ | Temurin 21.0.12.1 + Maven 3.9.11 в `~/.local` |
| Node.js | ✅ | v20.19.5 / npm 10.8.2 в `~/.local/node` |
| feQuLib | ✅ | `/home/alex/projects/java/spring/vue/feQuLib` (= origin/main) |
| Docker | ❌ | для remote-режима не обязателен |
| `sqlcmd` / mssql-tools | ❌ | опционально |
| RAM | ⚠️ 7,7 GiB | Cursor уже занимает большую долю |

**Профиль по умолчанию:** клон `alex-fedora` (`database.type = remote_docker`, host `10.7.0.3`).

---

## 2. Принципы

| Принцип | Суть |
|--------|------|
| **Один источник данных** | Dev-БД остаётся на nb-win; на Kubuntu не поднимаем второй `femsq-mssql`, пока явно не решим иначе. |
| **Как Fedora** | Конфиги, MCP DSN, SMB mount, `database.properties` — по шаблону remote-nb-win. |
| **Реестр прежде скриптов** | Hostname должен быть в `machines` и в `setup-cursor-mcp.sh`, иначе автопроверка снова «не найдена». |
| **Не коммитить секреты** | `.cursor/mcp.json`, `~/.femsq/database.properties`, `~/.smbcredentials` — вне git. |
| **feQuLib снаружи** | Не копировать компоненты lib в FEMSQ; клон + `check-fequlib.sh`. |

---

## 3. Фазы

| Фаза | Название | Статус |
|------|----------|--------|
| **0** | Аудит окружения | ✅ 2026-09-11 |
| **1** | Регистрация машины в проекте | ✅ 1.1–1.2, 1.4; 1.3 пропущен (fedora-шаблон) |
| **2** | Toolchain: Java 21, Maven, Node 20 | ✅ user-local `~/.local` (без sudo) |
| **3** | Конфиг приложения + проверка MCP | ✅ |
| **4** | Клон feQuLib + smoke-проверка | ✅ |
| **5** | Документация remote-dev (Kubuntu) | ✅ |
| **6** | Приёмка: сборка / запуск / SQL | ✅ JAR 0.1.0.270, health 200 |
| **O** | Опционально: sqlcmd, Docker, RAM | ☐ |

---

## 4. Детальный план

### Этап 0 ― Аудит ✅

- [x] **0.1** Прочитать `development.environments.machines`
- [x] **0.2** Сопоставить hostname/OS
- [x] **0.3** Проверить DBHub, MCP, WireGuard, SQL, SMB, toolchain, feQuLib
- [x] **0.4** Создать этот план чата

### Этап 1 ― Регистрация `asus-kubuntu` ✅

**Цель:** автопроверка и скрипты узнают машину как remote-станцию.

- [x] **1.1** Добавить машину `asus-kubuntu` в `docs/project/project-docs.json` (+ `environments.json`, `check_order`)
- [x] **1.2** Обновить `code/scripts/setup-cursor-mcp.sh` → remote-шаблон для `asus-kubuntu`
- [x] **1.3** Отдельный шаблон properties — пропущен; используем `database.properties.alex-fedora`
- [x] **1.4** Журнал: chat `chat-2026-09-11-001` «Донастройка asus-kubuntu»

### Этап 2 ― Toolchain ✅

**Цель:** `java`, `mvn`, `node`, `npm` в PATH.

- [x] **2.1–2.3** Без sudo (нет пароля/`curl`): Temurin 21.0.12.1, Maven 3.9.11, Node 20.19.5 → `~/.local/{jdk-21,maven,node}`
- [x] **2.4** `~/.bashrc`: пути на `~/.local`; `FEMSQ_DB_HOST=10.7.0.3`
- [x] **2.5** Проверено: java / mvn / node / npm в login-shell

**Примечание:** позже можно перейти на apt (`openjdk-21-jdk`, `maven`, `curl` + NodeSource).

### Этап 3 ― Конфиг приложения и MCP ✅

- [x] **3.1** `~/.femsq/database.properties` из `database.properties.alex-fedora` (mode 600)
- [x] **3.2** `./code/scripts/setup-cursor-mcp.sh` → remote-шаблон
- [x] **3.3** MCP-файл на месте (перезагрузка MCP в Cursor — вручную при необходимости)
- [x] **3.4** Smoke SQL: `FishEye` на `10.7.0.3`, SQL Server 2022 CU23

### Этап 4 ― feQuLib ✅

- [x] **4.1** Клон: `git@github.com:bondalen/fequlib.git` → `/home/alex/projects/java/spring/vue/feQuLib`  
  (не `~/projects/feQuLib` — нужен сосед `../feQuLib` относительно корня FEMSQ)
- [x] **4.2** `./code/scripts/check-fequlib.sh` — sync с `origin/main`, FemsqTree OK
- [x] **4.3** pull не потребовался (уже на `origin/main`)

### Этап 5 ― Документация ✅

- [x] **5.1** [remote-development-nb-win.md](../../../remote-development-nb-win.md): схема Fedora+Kubuntu, quick start, реестр машин
- [x] **5.2** `lastUpdated` доки / план
- [x] **5.3** [chat-resume-26-0911-asus-kubuntu-setup.md](../chat-resume/chat-resume-26-0911-asus-kubuntu-setup.md)

### Этап 6 ― Приёмка ✅

- [x] **6.1** `check-fequlib.sh` + сборка `0.1.0.270-SNAPSHOT` (fat JAR 83M)  
  - Фикс: `echarts`/`vue-echarts` в `femsq-frontend-q`; `npm install` в feQuLib; `dedupe` в `vite.config.ts`
- [x] **6.2** Запуск JAR → `GET /api/v1/connection/status` → HTTP 200, `connected=true`, `FishEye`/`ags` (процесс остановлен после проверки)
- [x] **6.3** Чеклист окружения: hostname, toolchain, props, MCP, DBHub, feQuLib, SMB, WireGuard, SQL — OK

### Этап O ― Опционально ☐

| # | Что | Когда |
|---|-----|--------|
| O.1 | `mssql-tools` / `sqlcmd` | частые ручные SQL вне Cursor |
| O.2 | Локальный Docker `femsq-mssql` | работа без nb-win / offline |
| O.3 | `krb5-user` | SSO к prod с Linux |
| O.4 | Увеличить RAM до 16+ GiB | комфорт Cursor + Maven + Vite на 8 GiB тесно |

---

## 5. Решения (зафиксировать в чате)

| # | Вопрос | Варианты | Решение |
|---|--------|----------|---------|
| D1 | Профиль машины | A: отдельная запись `asus-kubuntu`; B: alias к Fedora | **A** (2026-09-11) |
| D2 | Источник БД | remote nb-win / локальный Docker | **remote** (подтверждено health 2026-09-11) |
| D3 | Node: apt vs nvm/NodeSource | — | **user-local Node 20.19.5 в `~/.local/node`** (без sudo; 2026-09-11) |
| D4 | Делать ли задачу в `project-development.json` | да / нет (инфра без feature-id) | **нет** (инфра-чат; журнал chat-2026-09-11-001) |

---

## 6. Следующий шаг (рекомендация)

Окружение готово. Опционально: apt/`curl`/sqlcmd, ротация GitHub-токена, RAM 16+.  
Рабочая разработка — по текущим feature-задачам (например СУДЗ).

---

## 7. Лог сессий

| Дата | Что сделано |
|------|-------------|
| 2026-09-11 | Аудит окружения на `asus-kubuntu`; создан план `chat-plan-26-0911-asus-kubuntu-setup.md` |
| 2026-09-11 | Этап 1.1–1.2: машина в `project-docs.json` + `environments.json`; `setup-cursor-mcp.sh` узнаёт `asus-kubuntu` |
| 2026-09-11 | Журнал: chat-2026-09-11-001; этап 2: JDK/Maven/Node в `~/.local`, правки `~/.bashrc` |
| 2026-09-11 | Этапы 3–4: `~/.femsq/database.properties`, SQL smoke OK, feQuLib клон + check OK |
| 2026-09-11 | Этапы 5–6: remote-dev дока + resume; JAR 0.1.0.270; health 200 FishEye/ags; echarts fix |)
