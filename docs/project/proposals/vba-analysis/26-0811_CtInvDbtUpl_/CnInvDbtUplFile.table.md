# Таблица Access: `CnInvDbtUplFile`

**Статус:** структура снята (дамп 2026-08-11).  
**Источник:** [`CnInvDbtUplFile.dump.utf8.txt`](./CnInvDbtUplFile.dump.utf8.txt)  
**Тип:** локальная таблица Access (`Connect` пустой). Не на SQL Server (DBHub 2026-08-11).  
**Записей:** 19  
**Данные (без логов):** [`CnInvDbtUplFile.data.csv`](./CnInvDbtUplFile.data.csv)  
**Полный CSV с RTF-логами:** ~33 MB — не для git (`*.csv.FULL_WITH_LOGS_DO_NOT_COMMIT`); логи до ~1.8 MB/строка.  
**Форма:** `CnInvDbtUpl>File_f` (RecordSource / поля лаунчера).

## Назначение

Шапка лаунчера загрузки общего свода: путь к Excel, флаги apply/перечитать staging, HTML/RTF-лог; связь с пакетом `cn_inv_dbt_upl` через `cidufUpload` (= `upl_key`).

## Поля

| Поле | DAO | Size | Req | Default | Caption / Description |
|------|-----|------|-----|---------|------------------------|
| `cidufKey` | dbLong (4), **PK**, Autoincrement (Attr 17) | 4 | нет | — | ключ файла выгрузки |
| `cidufUpload` | dbLong | 4 | **да** | — | выгрузка → логически `upl_key` |
| `cidufPath` | dbText | 255 | **да** | — | путь файла |
| `cidufFlLoad` | dbBoolean | 1 | нет | No | обновлять? / нужно ли обновлять БД? |
| `cidufLoadingProgress` | dbMemo | — | нет | — | ход загрузки; **TextFormat=1** (Rich Text) |
| `cidufFlTbl` | dbBoolean | 1 | нет | No | обнов. по исх? / обновлять промежуточную таблицу по исходным данным |

## Индексы

| Имя | Primary | Unique | Поля |
|-----|---------|--------|------|
| `PrimaryKey` | да | да | `cidufKey` |
| `cidufUpload` | нет | **да** | `cidufUpload` → **1 файл на 1 upl** |

## Связи (Access Relations)

| Relation | Parent → Child | Поля |
|----------|----------------|------|
| (GUID) | `CnInvDbtUplFile` → `CnInvDbtUplFileSh` | `cidufKey` → `cidufsFile` |

Связи с linked `ags_cn_inv_dbt_upl` в дампе Relations **нет** (типично для ODBC-linked); FK логический: `cidufUpload` = `upl_key`.

## Для FEMSQ / SQL

- Кандидат на `sudz` staging: 1:1 с `cn_inv_dbt_upl.upl_key` (unique на upload).
- Лог → `nvarchar(max)` (HTML, не RTF Access).
- Путь: в Access UNC 255; в web — имя файла / FSA (S60).

**lastUpdated:** 2026-08-11
