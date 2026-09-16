# Decommission: FEMSQ на cloud.ru / cr-ubu

**Дата:** 2026-09-16  
**Решение:** временный контур (отключение nb-win) отыграл роль; постоянная работа на слабой VM нецелесообразна. Канон снова **nb-win**.

## Снято на cr-ubu (2026-09-16)

| Объект | Действие |
|--------|----------|
| контейнер `femsq-mssql` | stop + rm |
| volume `femsq-mssql-data` | rm (bak cloud.ru→nb-win **не** делали — по решению владельца) |
| контейнер `femsq-smb` + образ `dperson/samba` | rm |
| `~/FishEye_xfer.bak`, `~/.femsq-smb-share.pass` | rm |
| содержимое шары `~/wire-guard-share-nb-win` | очищено |

## Оставлено на cr-ubu

- Пустая папка `~/wire-guard-share-nb-win/` + `agent-exchange/` + `README-dropbox.txt` — **только** обмен файлами, не хост FishEye/Excel.
- WireGuard peer `10.7.0.1` без изменений.
- Снова Up: `fedoc-postgres-age`, `ferag`, `ferag-redis` (как до эксперимента).

## Канон разработки снова

| Ресурс | Host |
|--------|------|
| SQL FishEye | nb-win `10.7.0.3:1433` / localhost на nb-win |
| Excel SMB | `//10.7.0.3/wire-guard-share-nb-win` → `/mnt/nb-win-share` |

На **asus-kubuntu** вернуть `~/.femsq/database.properties` и `.cursor/mcp.json` на `10.7.0.3`, remount SMB на `10.7.0.3` (не `10.7.0.1`).

## История

- Handoff: [2026-09-14_2311_nbwin_to_asus-kubuntu_cloud-ru-dev.md](./2026-09-14_2311_nbwin_to_asus-kubuntu_cloud-ru-dev.md)
- ACK: [2026-09-15_0943…](./2026-09-15_0943_asus-kubuntu_to_nbwin_cloud-ru-ack.md), [2026-09-15_0945…](./2026-09-15_0945_asus-kubuntu_to_nbwin_cloud-ru-ack.md)
