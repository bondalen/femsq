# Таблица Access: `CnInvDbtUplFileSh`

**Статус:** структура + данные сняты (2026-08-11 / разбор 2026-08-12).  
**Источник:** [`CnInvDbtUplFileSh.dump.utf8.txt`](./CnInvDbtUplFileSh.dump.utf8.txt), [`CnInvDbtUplFileSh.csv`](./CnInvDbtUplFileSh.csv)  
**Тип:** локальная Access. Description таблицы: «листы файла».  
**Записей:** 114 (= 19 файлов × 6 листов).  
**UI:** подвкладка «перечень листов» формы `File_f`.

## Назначение

Список Excel-листов в файле свода: имя листа, счёт ГК (`ags.accnt`), флаг «проверять?» (`cidufsTest`). При `cidufFlTbl` загрузчик обходит только листы с `cidufsTest=True`.

## Поля

| Поле | DAO | Size | Req | Default | Caption / Description |
|------|-----|------|-----|---------|------------------------|
| `cidufsKey` | dbLong, **PK**, Autoincrement (Attr 17) | 4 | нет | — | — |
| `cidufsFile` | dbLong, **FK** → `CnInvDbtUplFile.cidufKey` | 4 | **да** | — | файл |
| `cidufsSheet` | dbText | 255 | **да** | — | лист (в данных = номер счёта, напр. `606012`) |
| `cidufsAccount` | dbLong | 4 | **да** | — | счёт → lookup `ags_accnt.account_key` (combo) |
| `cidufsTest` | dbBoolean | 1 | нет | No | проверять? |

## Индексы / связи

| | |
|--|--|
| PK | `cidufsKey` |
| FK index | `cidufsFile` → `CnInvDbtUplFile.cidufKey` (Relation уже в дампе File) |

## Данные (факты)

- У каждого из 19 `cidufsFile` ровно **6** листов: `606012`, `606022`, `761010`, `762210`, `767501`, `767502`.
- `cidufsAccount`: 19, 21, 23, 24, 28, 29 (ключи `ags.accnt`).
- **Все** `cidufsTest=True` в текущем снимке.
- CSV ~3.6 KB — в git ок.

## Для FEMSQ / SQL

- Staging 1:N к шапке File / к `upl_key` (через File).
- `cidufsAccount` → FK на `ags.accnt` (или `account_key` в `sudz` зеркале).
- Имя листа ≠ обязательно равно `account_num`, но в практике совпадает.

**lastUpdated:** 2026-08-12
