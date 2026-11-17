# C1 — инвентаризация Access (освоение P2)

**План:** [`chat-plan-26-1117-c1-access-inventory.md`](../../../development/notes/chats/chat-plan/chat-plan-26-1117-c1-access-inventory.md)  
**Порядок снятия:** [`MS-ACCESS-OBJECTS-CAPTURE.md`](../MS-ACCESS-OBJECTS-CAPTURE.md) §4  
**created / lastUpdated:** 2026-11-17

## Содержимое

| Файл | Назначение |
|------|------------|
| `modC1Catalog.bas` | Модуль-каталог: формы, отчёты, запросы, макросы, linked tables → UTF-8 |
| `OPERATOR.md` | Инструкция владельцу (Windows, копия файла) |
| `registry.md` | Реестр функций (заполняется после сбора) |

## Статус сбора (2026-11-17)

| Шаг | Результат |
|-----|-----------|
| `ExportAllModulesC1` | **125** → `VBA-Code-Export/` в репо (UTF-8): 8 Standard + 31 Class + 86 Form |
| `DumpC1MSys` | forms 243, reports 72, queries 342, linked 167, macros 0 → [`raw/`](./raw/) |
| Карта | [`registry.md`](./registry.md) — группы → P2; migrate — в ходе C2–C5 |

## Запуск у владельца (кратко)

1. Копия рабочего `.accdb` / `.mdb`.
2. `modC1VbaExport` → Immediate: `ExportAllModulesC1` → агент перекодирует CP1251→UTF-8.
3. `modC1MSysDump` → Immediate: `DumpC1MSys "…\c1-inventory"`.
4. Папку `c1-inventory` и выгрузку VBA — на шару / в чат.

Подробно — `OPERATOR.md`.
