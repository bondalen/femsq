# ags.impIpgLoad / ags.impIpg — каркас загрузки годовой ИП (C2 §3.1.6.1)

**Дата:** 2026-11-24  
**Задача:** 0081  
**Стенд:** `FishEye_prod_noM6`  
**Контракт:** `docs/development/notes/chats/chat-plan/notes/26-1124-c2-o1-excel-load-contract.md`  
**Прод:** не применять до решения о выкладке O1 (пакет 2012-совместим).

## Назначение

| Таблица | Роль |
|--------|------|
| `ags.impIpgLoad` | сессия загрузки под `ipg` (путь к Excel) |
| `ags.impIpg` | тело разбора (разделы/листья); ПТСФ = `iiRowKind='S'` |

`impIpgLoadMonf` — вне этого пакета (этап 2 / O2).

## Скрипты

| Файл | Контур |
|------|--------|
| `open/01_CREATE_impIpgLoad.sql` | DEV (2022+) |
| `MSSQL2012/01_CREATE_impIpgLoad.sql` | Prod-совместимый (2012) |

Идемпотентно: CREATE только если объекта нет.
