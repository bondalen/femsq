# ags.impIpgLoadMonf — помесячные файлы агентов (C2 §6.3)

**Дата:** 2026-11-27  
**Задача:** 0081  
**Стенд:** `FishEye_prod_noM6`  
**Note:** `docs/development/notes/chats/chat-plan/notes/26-1127-c2-o6-ldm-monf.md`  
**Контракт имён:** O1 excel-load §2 (`impIpgLoad` 1:* `Monf` → `ipgUtPl`)

## Скрипты

| Файл | Контур |
|------|--------|
| `open/01_CREATE_impIpgLoadMonf.sql` | DEV (2022+) |
| `MSSQL2012/01_CREATE_impIpgLoadMonf.sql` | Prod-совместимый (2012) |

Идемпотентно: CREATE только если объекта нет. На прод — только из `MSSQL2012/` при выкладке.
