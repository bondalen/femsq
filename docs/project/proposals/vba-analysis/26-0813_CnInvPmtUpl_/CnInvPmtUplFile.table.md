# Таблица Access: `CnInvPmtUplFile`

**Статус:** структура + данные (slim) сняты (2026-08-13).  
**Источник:** [`CnInvPmtUplFile.dump.utf8.txt`](./CnInvPmtUplFile.dump.utf8.txt), [`CnInvPmtUplFile.data.csv`](./CnInvPmtUplFile.data.csv)  
**Тип:** локальная Access. **Записей:** 30 (`cipufUpload` 7…36; лист: `Sheet1` / `Лист1`).  
**Форма:** `CnInvPmtUpl>File_f`.

## Назначение

Шапка лаунчера загрузки выгрузки платежей (`export_*` / БУиРГ): путь, флаги, RTF-лог, **имя листа** (`cipufSheet` — вместо отдельной FileSh).

## Поля

| Поле | DAO | Size | Req | Caption / Description |
|------|-----|------|-----|------------------------|
| `cipufKey` | dbLong, **PK**, AutoInc | 4 | нет | — |
| `cipufUpload` | dbLong | 4 | **да** | выгрузка → `cn_inv_pm_upl.cn_inv_pm_key` |
| `cipufPath` | dbText | 255 | **да** | путь файла |
| `cipufFlLoad` | dbBoolean | 1 | нет | обновлять? / обновлять БД? |
| `cipufLoadingProgress` | dbMemo, TextFormat=1 | — | нет | ход загрузки (RTF) |
| `cipufFlTbl` | dbBoolean | 1 | нет | обнов. по исх? |
| `cipufSheet` | dbText | 255 | нет | лист в книге |

## Индексы / связи

| | |
|--|--|
| PK | `cipufKey` |
| UNIQUE | `cipufUpload` (в дампе индекс назван `cidufUpload` — опечатка Access) |
| Relation | `ags_cn_inv_pm_upl.cn_inv_pm_key` → `cipufUpload` |

## Для FEMSQ

- 1:1 с `cn_inv_pm_key`; UNIQUE; FK на `sudz.cn_inv_pm_upl` — по возможности (ключи sandbox vs ags уточнить при seed).
- Лог → `nvarchar(max)`; CSV seed — **без** Memo.

**lastUpdated:** 2026-08-13
