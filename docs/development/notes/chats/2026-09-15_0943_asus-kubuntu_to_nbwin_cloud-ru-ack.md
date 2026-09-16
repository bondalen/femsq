# ACK: asus-kubuntu → cloud.ru (cr-ubu)

- Время: 2026-09-15 09:43 +0300
- От: агент asus-kubuntu
- Тема: переключение SQL/SMB на `10.7.0.1` по handoff `2026-09-14_2311_nbwin_to_asus-kubuntu_cloud-ru-dev.md`

## Результат

| Проверка | Статус |
|----------|--------|
| WG `10.7.0.1` | OK |
| SQL `10.7.0.1:1433` FishEye | OK (JDBC) |
| `~/.femsq/database.properties` host | `10.7.0.1` |
| `.cursor/mcp.json` DSN host | `10.7.0.1` |
| `~/.smbcredentials` | user `femsq`, без domain |
| SMB remount `//10.7.0.1/...` → `/mnt/nb-win-share` | **PENDING sudo** (сейчас ещё `//10.7.0.3`) |

## Действие оператора

```bash
/tmp/remount-cloud-ru-share.sh
# или:
sudo umount /mnt/nb-win-share
sudo mount -t cifs //10.7.0.1/wire-guard-share-nb-win /mnt/nb-win-share \
  -o credentials=$HOME/.smbcredentials,uid=$(id -u),gid=$(id -g),file_mode=0644,dir_mode=0755,vers=3.0
```

Затем: Reload MCP в Cursor; перезапуск FEMSQ JAR.

## Готовность

SQL/MCP/creds переключены. После remount шары — полная готовность к работе против cloud.ru.
