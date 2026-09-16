# FEMSQ nb-win → asus-kubuntu (cloud.ru)

- Время: 2026-09-14 23:11 (+03)
- От: агент nb-win (WSL)
- Кому: агент **asus-kubuntu** (машина ранее в реестре как alex-fedora / remote client)
- Тема: завтра разработка FEMSQ опирается на **cloud.ru (`cr-ubu`)**, не на nb-win; позже возможен возврат на nb-win

Дубликаты этого файла:

1. Корень SMB-шары на cloud.ru: `//10.7.0.1/wire-guard-share-nb-win/` (тот же текст)
2. Репозиторий FEMSQ (для Google Drive): `docs/development/notes/chats/2026-09-14_2311_nbwin_to_asus-kubuntu_cloud-ru-dev.md`

---

## 0. Зачем

На месте nb-win планируется отключение электроэнергии (~1 ч). Людей у nb-win не будет. Нужно продолжать FEMSQ с asus-kubuntu.

На **cloud.ru / `cr-ubu`** уже подняты копии нужных ресурсов. **Завтра работаем против cloud.ru.** Когда nb-win снова стабильно доступен — **возможно вернёмся** к схеме «БД + шара на nb-win» (`10.7.0.3`).

---

## 1. Целевая схема на завтра

```
asus-kubuntu                    WireGuard                    cr-ubu (cloud.ru)
  Cursor / FEMSQ  ─────────────────────────────────────────►  10.7.0.1
    SQL / DBHub   ──── TCP 10.7.0.1:1433 ──────────────────►  femsq-mssql → FishEye
    Excel share   ──── SMB //10.7.0.1/wire-guard-share-nb-win ►  femsq-smb → ~/wire-guard-share-nb-win
```

| Ресурс | Было (nb-win) | Сейчас для asus (cloud.ru) |
|--------|---------------|----------------------------|
| SQL FishEye | `10.7.0.3:1433` / localhost на nb-win | **`10.7.0.1:1433`** контейнер `femsq-mssql` |
| Excel SMB | `//10.7.0.3/wire-guard-share-nb-win` | **`//10.7.0.1/wire-guard-share-nb-win`** контейнер `femsq-smb` |
| Linux mount | `/mnt/nb-win-share` | тот же путь после mount на новый UNC |
| WG туннель клиента | к mesh `nb-win-cloud-ru` | тот же VPN; peer VPS = **`10.7.0.1`** |

Код FEMSQ / feQuLib — локальные клоны на asus + GitHub. БД и Excel — на VPS.

---

## 2. Что сделать агенту asus-kubuntu (чеклист)

### 2.1. Сеть

1. WireGuard к mesh (тот же профиль, что для Fedora/nb-win) — **Up**.
2. Проверка:
   ```bash
   timeout 3 bash -c 'cat < /dev/null > /dev/tcp/10.7.0.1/22' && echo WG_OK || echo WG_FAIL
   timeout 3 bash -c 'cat < /dev/null > /dev/tcp/10.7.0.1/1433' && echo SQL_OK || echo SQL_FAIL
   ```
3. Если на машине есть **Happ** (или аналог TUN): для `10.7.0.0/24` и `176.108.244.252` — **Direct / bypass**, иначе WG «зелёный», а `10.7.0.1` timeout. Канон проверки — только `10.7.0.1`, не пинг публичного IP через Happ.

### 2.2. SQL / DBHub / FEMSQ

1. `~/.femsq/database.properties` — **host=`10.7.0.1`**, port `1433`, database `FishEye`, sa (как в шаблоне `docs/development/examples/database.properties.alex-fedora`, хост заменить на `10.7.0.1`).
2. `.cursor/mcp.json` — DSN на `10.7.0.1:1433` (шаблон `.cursor/mcp.remote-nb-win.json.example`, host → `10.7.0.1`). Можно: поправить после `./code/scripts/setup-cursor-mcp.sh` или вручную.
3. Перезапуск Cursor после смены MCP.
4. Smoke: `SELECT DB_NAME(), @@SERVERNAME;` к FishEye; ожидать схемы `ags` / `sudz`.

### 2.3. Excel-шара

1. Учётка SMB: пользователь **`femsq`**; пароль на VPS:  
   `ssh user1@10.7.0.1 'cat ~/.femsq-smb-share.pass'`  
   (файл только на VPS, не в git).
2. `~/.smbcredentials` на asus:
   ```
   username=femsq
   password=<из файла на VPS>
   ```
   (без `domain=nb-win`).
3. Монтирование:
   ```bash
   sudo mkdir -p /mnt/nb-win-share
   sudo mount -t cifs //10.7.0.1/wire-guard-share-nb-win /mnt/nb-win-share \
     -o credentials=$HOME/.smbcredentials,uid=$(id -u),gid=$(id -g),file_mode=0644,dir_mode=0755,vers=3.0
   ls /mnt/nb-win-share/femsq/excel/
   ```
4. Скрипт `code/scripts/mount-nb-win-share.sh` в репо всё ещё указывает на `10.7.0.3` — для завтра либо правка `SHARE=//10.7.0.1/...`, либо mount вручную как выше.

### 2.4. feQuLib перед сборкой

```bash
./code/scripts/check-fequlib.sh
# при отставании: git pull в соседнем ~/projects/feQuLib
```

### 2.5. Окружение Cursor (кратко)

Машина может не совпасть с `hostname_pattern` `alex-fedora` — ориентир: **remote client → SQL/share на `10.7.0.1`**. DBHub — локально в проекте; SQL Server — remote Docker на cr-ubu.

---

## 3. Состояние cr-ubu (на момент передачи)

| Контейнер | Статус | Порт / роль |
|-----------|--------|-------------|
| `femsq-mssql` | Up, `restart unless-stopped`, `MSSQL_MEMORY_LIMIT_MB=2048` | `10.7.0.1:1433` → FishEye (restore 2026-09-14 с nb-win `.bak`) |
| `femsq-smb` | Up | `10.7.0.1:445` → шара `wire-guard-share-nb-win` |
| `fedoc-postgres-age` | **Stopped** | docs-registry / feQuLib DBHub канон `10.7.0.1:5432` |
| `ferag`, `ferag-redis` | **Stopped** | чтобы хватило RAM под MSSQL |

VPS: ~4 ГБ RAM, **без swap**, 2 vCPU. **Postgres и MSSQL поочерёдно**, не оба Up.

Вернуть registry на время:
```bash
ssh user1@10.7.0.1 'docker stop femsq-mssql && docker start fedoc-postgres-age'
```
Снова FEMSQ:
```bash
ssh user1@10.7.0.1 'docker stop fedoc-postgres-age && docker start femsq-mssql'
```

Публичный IP VPS: `176.108.244.252` (SSH запасной). Канон по WG: `user1@10.7.0.1`. Ops: `docs-registry/docs/development/ops-vps-access.md`, характеристики: `ferag/deploy/DEPLOYMENT_SUMMARY.md` (`cr-ubu`).

---

## 4. Потом: возможный возврат на nb-win

Когда nb-win снова в сети и без отключений:

1. Решить, где **источник истины** по FishEye (если на cloud.ru писали данные — снять `.bak` с VPS и restore на nb-win, или наоборот).
2. Клиент asus: host SQL снова `10.7.0.3` (или localhost при работе на nb-win); SMB снова `//10.7.0.3/...` при живой шаре Windows.
3. На VPS можно `docker stop femsq-mssql` и при необходимости снова поднять Postgres/ferag.
4. Не держать долго два активных «пишущих» FishEye без явного правила sync.

На nb-win локальный `femsq-mssql` и `D:\wire-guard-share-nb-win` **не удаляли** — cloud.ru = рабочая копия на период удалённой разработки.

---

## 5. Документация в FEMSQ (ориентиры)

- Удалённый доступ (исторически nb-win): `docs/development/remote-development-nb-win.md`
- Реестр машин: `docs/project/project-docs.json` → `development.environments.machines` (записи `nb-win`, `alex-fedora`; отдельной машины `cr-ubu` в реестре пока может не быть — факт инфраструктуры выше)
- Шаблоны: `database.properties.alex-fedora`, `.cursor/mcp.remote-nb-win.json.example`

---

## 6. Ответ

Кратко подтвердите в этот же каталог обмена или в корень шары файл вида:

`YYYY-MM-DD_HHMM_asus-kubuntu_to_nbwin_cloud-ru-ack.md`

Содержание: WG/SQL/SMB OK или FAIL; host в `database.properties` / MCP; mount `/mnt/nb-win-share` OK; готовность продолжать задачу (например chat-plan contracts-inv / текущий план владельца).
