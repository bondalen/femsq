# Таблица Access: `ogAgFeePnTest`

**Статус описания:** полный DAO-дамп локальной таблицы Access. Зафиксированы `TableDef.Properties`, 10 полей, PK `PrimaryKey`, отсутствие явных relations.

**Тип объекта:** локальная таблица Access (`Connect` пустой, `Attributes=0`).

**Назначение в VBA:** буфер/рабочая таблица контура `af_type = 6` (`RAAudit_AgFee_Month`), напрямую используется через `OpenRecordset("ogAgFeePnTest", ...)` и `DELETE * FROM ogAgFeePnTest` в `Form_ra_a.cls`.

**Дата создания/обновления:** `DateCreated` 11.01.2022 12:06:56; `LastUpdated` 23.03.2026 11:35:47.  
**RecordCount (дамп):** `2399`.

**lastUpdated:** 2026-03-19

---

## Поля (DAO)

Типы в DAO:
- `dbLong` = 4
- `dbMemo` = 12
- `dbDate` = 8

| Имя поля | Type | Size | Required | AllowZeroLength | DefaultValue | Комментарий |
|----------|------|------|----------|------------------|--------------|-------------|
| `oafptKey` | 4 (dbLong) | 4 | False | False | — | PK (счетчик/ключ) |
| `oafptOafName` | 12 (dbMemo) | 0 | False | True | — | Имя акта |
| `oafptOafDate` | 8 (dbDate) | 8 | False | False | — | Дата акта |
| `oafptOafKey` | 4 (dbLong) | 4 | False | False | `0` | Ключ акта в БД |
| `oafptOafSender` | 4 (dbLong) | 4 | False | False | `0` | Отправитель |
| `oafptPnKey` | 4 (dbLong) | 4 | False | False | `0` | Ключ рассмотрения |
| `oafptPnCstAgPn` | 4 (dbLong) | 4 | False | False | `0` | Ключ стройки |
| `oafptPnNote` | 12 (dbMemo) | 0 | False | True | — | Примечание |
| `oafptAdtKey` | 4 (dbLong) | 4 | False | False | `0` | Ключ ревизии |
| `oafptY` | 4 (dbLong) | 4 | False | False | `0` | Год |

Примечание по `Field.Properties`: в данном дампе `Precision/Scale` читаются (например `1033`/`0`), но для документирования структуры главным источником остаются `Type/Size/Required/DefaultValue`.

---

## Индексы

| Имя индекса | Поля | Primary | Unique |
|-------------|------|---------|--------|
| `PrimaryKey` | `oafptKey` | ✅ | ✅ |

---

## Связи

В разделе `RELATIONS` дампа связи не перечислены (пусто).

---

## Контрольный сырой фрагмент

```text
TABLE: ogAgFeePnTest
Connect: (local table)
RecordCount: 2399
FIELD: oafptKey Type: 4 (dbLong) Size: 4
FIELD: oafptOafName Type: 12 (dbMemo) Size: 0
...
FIELD: oafptY Type: 4 (dbLong) Size: 4
INDEX: PrimaryKey (oafptKey)
```
