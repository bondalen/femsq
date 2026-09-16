# ACK: asus-kubuntu → cloud.ru (cr-ubu)

- Время: 2026-09-15 09:45 +0300
- От: агент / оператор asus-kubuntu
- Тема: переключение SQL/SMB на `10.7.0.1` завершено

## Результат

| Проверка | Статус |
|----------|--------|
| WG `10.7.0.1` | OK |
| SQL `~/.femsq` + JDBC FishEye | OK (`host=10.7.0.1`) |
| MCP DSN | `10.7.0.1` |
| SMB credentials | `femsq`, без domain |
| Mount `/mnt/nb-win-share` | **`//10.7.0.1/wire-guard-share-nb-win`** OK |
| `femsq/excel/` | читается |

При remount было `umount: target is busy` — итог всё равно cloud.ru (проверено `findmnt`).

## Готовность

Переключение завершено. Рекомендуется Reload MCP в Cursor.
