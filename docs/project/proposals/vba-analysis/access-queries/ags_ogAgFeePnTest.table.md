# Таблица Access (linked): `ags_ogAgFeePnTest`

**Статус описания:** полный DAO-дамп linked-таблицы (ODBC -> SQL Server). Зафиксированы `TableDef.Properties`, список полей, PK и замечания по `Err=3151` для части `Field.Properties`.

**Тип объекта:** linked table в MS Access.

**Connect:**  
`ODBC;DSN=FishEye;DATABASE=FishEye;TABLE=ags.ogAgFeePnTest;`

**Attributes (TableDef):** `536870912`  
**Updatable:** `False`  
**DateCreated/LastUpdated:** `13.03.2026 14:51:30`  
**RecordCount:** `COUNT(*) failed Err=3151` (на состав метаданных не влияет).

**GUID/NameMap:** `<binary/skipped>` (DAO-бинарные свойства).

**lastUpdated:** 2026-03-19

---

## Поля (DAO)

Типы в DAO:
- `dbLong` = 4
- `dbText` = 10
- `dbDate` = 8
- `dbCurrency` = 5
- `dbMemo` = 12 (в этом дампе нет)

| Имя поля | Type | Size | Required | AllowZeroLength | Комментарий |
|----------|------|------|----------|------------------|-------------|
| `oafptKey` | 4 (dbLong) | 4 | True | False | PK |
| `oafptOafSender` | 10 (dbText) | 255 | True | True | Sender (текст) |
| `oafptOafSenderKey` | 4 (dbLong) | 4 | False | False | Ключ sender |
| `oafptActCount` | 4 (dbLong) | 4 | False | False | Кол-во актов |
| `oafptOafName` | 10 (dbText) | 255 | True | True | Название |
| `oafptOafDate` | 8 (dbDate) | 8 | True | False | Дата |
| `oafptPnCstAgPn` | 10 (dbText) | 255 | True | True | Строка |
| `oafptPnCstAgPnKey` | 4 (dbLong) | 4 | False | False | Ключ |
| `oafptTtl` | 5 (dbCurrency) | 8 | True | False | Денежный TTL |
| `oafptCapex` | 10 (dbText) | 10 | True | True | Текст |
| `oafptArrivedNum` | 10 (dbText) | 255 | True | True | Arrived num |
| `oafptArrivedDate` | 8 (dbDate) | 8 | True | False | Arrived date |
| `oafptSendedNum` | 10 (dbText) | 255 | False | True | Sended num |
| `oafptSendedDate` | 8 (dbDate) | 8 | False | False | Sended date |
| `oafptUnit` | 10 (dbText) | 255 | True | True | Ед.изм |
| `oafptReturnedNum` | 10 (dbText) | 255 | False | True | Returned num |
| `oafptReturnedDate` | 8 (dbDate) | 8 | False | False | Returned date |
| `oafptReturnedReason` | 10 (dbText) | 255 | False | True | Reason |
| `oafptReturnedSum` | 5 (dbCurrency) | 8 | False | False | Den. returned sum |
| `oafptPagesCount` | 4 (dbLong) | 4 | False | False | Pages count |

Примечание по `Field.Properties`: для `Precision/Scale` местами чтение возвращает `Err=3151` — как и в прошлых дампах, тип/размер берём из секции `FIELD`.

---

## Индексы

| Имя индекса | Поля | Primary | Unique |
|-------------|------|---------|--------|
| `PK_ogAgFeePnTest` | `oafptKey` | ✅ | ✅ |

---

## Связи

В разделе `RELATIONS` дампа указано: пусто.

---

## Контрольный сырой фрагмент (для сверки)

```text
TABLE: ags_ogAgFeePnTest
Connect = ODBC;DSN=FishEye;DATABASE=FishEye;TABLE=ags.ogAgFeePnTest;
FIELD: oafptKey Type: 4 (dbLong) Size: 4 Required: True
FIELD: oafptOafSender Type: 10 (dbText) Size: 255 Required: True
...
FIELD: oafptPagesCount Type: 4 (dbLong) Size: 4 Required: False
INDEX: PK_ogAgFeePnTest Fields: oafptKey (Primary/Unique)
```

---

## Где используется (контур `af_type = 6`)

- В `Form_ra_a.cls` и классе `ra_aAgFee23_06.cls` таблица `ags_ogAgFeePnTest` используется как связанный (`ODBC`) SQL Server-объект.
- Локальная таблица `ogAgFeePnTest` — отдельный объект Access; задокументирована отдельно в [`ogAgFeePnTest.table.md`](./ogAgFeePnTest.table.md).

