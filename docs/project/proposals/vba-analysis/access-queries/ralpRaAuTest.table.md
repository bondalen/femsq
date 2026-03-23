# Таблица Access: `ralpRaAuTest`

**Статус описания:** достаточно для дальнейшей работы — зафиксированы метаданные TableDef, 8 полей, первичный индекс и связь со staging для `af_type = 3`.

**Назначение:** локальный буфер импорта для сценария аренды земли (`RAAudit_ralp`, лист `Аренда_Земли`). В SQL Server целевая staging-таблица — `ags.ra_stg_ralp`.

**Источник метаданных:** DAO-дамп `DumpTableDef_Extended` (передан текстом) + визуальная сверка со скриншотом конструктора Access.

**Метаданные таблицы (TableDef):** локальная таблица; `DateCreated` 11.01.2022 12:06:56; `LastUpdated` 11.01.2022 12:07:14; `Attributes=0`; в свойствах `RecordCount=177`.

**COUNT(*) failed Err=3008:** ожидаемый эффект в Access/DAO при чтении занятой таблицы; на состав полей/индексов не влияет.

**Ошибки 3008 в `Field.Properties` (`Precision`/`Scale`):** известный DAO-эффект; типы и размеры полей в блоке `FIELD` считаем каноничными.

**lastUpdated:** 2026-03-19

---

## Поля (DAO)

Типы: `4` = `dbLong`, `8` = `dbDate`, `10` = `dbText`, `12` = `dbMemo`.

| Имя поля | Type | Size | Required | Атрибуты | Комментарий |
|----------|------|------|----------|----------|-------------|
| `ralprtKey` | 4 | 4 | no | 17 | Счётчик/ключ строки (PK) |
| `ralprtNum` | 10 | 255 | yes | 2 | Номер записи (короткий текст) |
| `ralprtDate` | 8 | 8 | no | 1 | Дата |
| `ralprtCstAgPn` | 4 | 4 | no | 1 | Ключ стройки/САК |
| `ralprtOgSender` | 4 | 4 | no | 1 | Ключ отправителя/организации |
| `ralprtKeySQL` | 4 | 4 | no | 1 | Ссылка/ключ записи в SQL Server |
| `ralprtRaAuKey` | 4 | 4 | no | 1 | Ключ связанной сущности `ra_au` |
| `ralprtNote` | 12 | 0 | no | 2 | Примечание (memo/long text) |

Примечание: `ralprtNum` и `ralprtNote` допускают `AllowZeroLength=True`.

---

## Индексы

| Имя индекса | Поля | Primary | Unique |
|-------------|------|---------|--------|
| `PrimaryKey` | `ralprtKey` | yes | yes |

---

## Связи

В разделе `RELATIONS` дампа связи не перечислены (пусто).

---

## Связанные QueryDef

- [`ralpRaAuTestQuRa.access.sql`](./ralpRaAuTestQuRa.access.sql) - сверка отчетов `ags_ralpRa` с таблицей `ralpRaAuTest` по `ralprKey`/`ralprtKeySQL`, используется в `RAAudit_ralp`.
- [`ralpRaAuTestQuAu.access.sql`](./ralpRaAuTestQuAu.access.sql) - сверка фактов рассмотрения `ags_ralpRaAu` с таблицей `ralpRaAuTest` по `ralpraKey`/`ralprtRaAuKey`, используется в `RAAudit_ralp`.

---

## Сырой фрагмент (контроль)

```text
FIELD: ralprtKey      Type: 4 (dbLong)  Size: 4
FIELD: ralprtNum      Type: 10 (dbText) Size: 255  Required: True
FIELD: ralprtDate     Type: 8 (dbDate)  Size: 8
FIELD: ralprtCstAgPn  Type: 4 (dbLong)  Size: 4
FIELD: ralprtOgSender Type: 4 (dbLong)  Size: 4
FIELD: ralprtKeySQL   Type: 4 (dbLong)  Size: 4
FIELD: ralprtRaAuKey  Type: 4 (dbLong)  Size: 4
FIELD: ralprtNote     Type: 12 (dbMemo) Size: 0
INDEX: PrimaryKey (ralprtKey)
```
