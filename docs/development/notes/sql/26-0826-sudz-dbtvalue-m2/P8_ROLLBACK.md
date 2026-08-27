# P8 — снимок / откат DEV перед B1

**Дата:** 2026-08-26  
**Машина:** nb-win · контейнер `femsq-mssql` Up

## Место на диске (проверка)

| Том | Size | Avail | Заметка |
|-----|------|-------|---------|
| WSL `/` (`/dev/sdf`) | ~1 ТБ | **~890 ГБ** (7% used) | достаточно |
| `/mnt/d` (Windows D:) | 1.6 ТБ | **~1.3 ТБ** | целевой каталог `.bak` |

Ожидаемый размер полного `BACKUP DATABASE [FishEye]`: порядка сотен МБ (архив 2026-05-15 ≈ 126 МБ; с ростом данных — больше).

## Основной способ отката

Скрипт: [`code/scripts/backup-fisheye.sh`](../../../../../code/scripts/backup-fisheye.sh)  
Корень: `/mnt/d/Backups/femsq/database/{daily|manual|before-docker|archive}`

```bash
# Перед apply B1 (после P9 GO, перед шагом SQL):
BACKUP_LABEL=pre-B1-DbtValue-M2 ./code/scripts/backup-fisheye.sh manual
```

Restore (конспект из скрипта): `docker cp` `.bak` → контейнер → `RESTORE DATABASE … WITH REPLACE` (имена файлов/MOVE — по фактическому layout FishEye).

## Запасной способ (без .bak)

1. Пересоздать `sudz` / `test_sudz` из пакетов `docs/development/notes/sql/26-0807-sudz-target-schema/` (+ test-schema).  
2. Прогнать воронку / seed upl **910** и baseline-данные 82/85 по процедуре из P2.  
3. Откатить приложение: checkout коммита **до** P6 (или предыдущий thin JAR).

Дольше, но не требует `.bak`.

## Критерий закрытия P8

- [x] Диск проверен (место есть)  
- [x] Команда backup и путь зафиксированы  
- [x] Запасной путь (пересборка пакетов) описан  
- [ ] Фактический `.bak` перед B1 — выполнить командой выше **в момент GO** (см. P7 шаг 0/1)

**Статус P8 (документация + check диска):** ✅ 2026-08-26  
**Снимок `.bak`:** выполняется владельцем/агентом непосредственно перед apply B1 после P9.
