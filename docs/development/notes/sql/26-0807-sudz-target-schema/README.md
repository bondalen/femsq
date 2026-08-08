# Целевая схема СУДЗ — `sudz` (DEV)

**Дата:** 2026-08-07  
**Задача:** 0066  
**Спецификация:** [08-target-schema.md](../../domain/sudz/08-target-schema.md)

## Решение по размещению (S48 / 0066 + S48a)

| Контур | Схема | Решение |
|--------|-------|---------|
| **DEV (целевой контур MVP)** | **`sudz`** | Отдельная схема; объекты и витрины для GraphQL/UI |
| **Лаборатория** | `test_sudz` | Сохраняется; не удалять; эксперименты |
| **Живое легаси на DEV** | `ags` | FK с `sudz`; новые таблицы СУДЗ в `ags` на DEV **пока не** создаём |
| **Прод (S48a)** | **`ags`** | Объекты СУДЗ вливаются в **`ags`**; пакет `MSSQL2012/` = `sudz.*`→`ags.*` + синтаксис 2012 |

Схему `sudz` / `test_sudz` на прод **не** переносим. Скрипты этого каталога — клон пакета `26-0807-sudz-test-schema` с заменой `test_sudz` → `sudz` (только DEV).

## Применение на DEV

```bash
# из корня репозитория; пароль из ~/.femsq/database.properties
PASS=…   # sa
for f in docs/development/notes/sql/26-0807-sudz-target-schema/[0-9]*.sql; do
  echo "=== $f ==="
  docker exec -i femsq-mssql /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$PASS" -d FishEye -I -b -C < "$f" || exit 1
done
```

Или: `./apply-dev.sh` (если положен рядом).

## Smoke

```sql
EXEC sudz.Yr_DbtChanges @yr = 901;
EXEC sudz.Yr_DbtChangesD644 @yr = 901, @curr_upl = 902;
EXEC sudz.Yr_DbtChangesD644Svod @yr = 900, @curr_upl = 805;
```

Ожидание: строки долгов **82** / **85** как в `test_sudz`.

## MSSQL2012

Подкаталог `MSSQL2012/` — пакет для **прода** (SQL Server 2012 SP4).

Целевая схема на проде — **`ags`** (решение владельца S48a): скрипты = содержимое DEV/`sudz` с заменой `sudz.` → `ags.`, плюс:

1. Заменить `CREATE OR ALTER` → `IF OBJECT_ID… DROP` + `CREATE` (или `ALTER` при существовании).
2. Убрать/заменить конструкции новее 2012 (`STRING_AGG` → `FOR XML PATH` уже есть в части скриптов).
3. Согласовать имена с уже живыми `ags.invDbt` / `ags.cnInvCmm*` (оживление vs новые имена — чеклист cutover).
4. Прогнать на инстансе с `COMPATIBILITY_LEVEL = 110`.

**Пока:** cutover 0066 на DEV выполнен в схеме `sudz`; `MSSQL2012/` наполняется при подготовке прод-деплоя.
