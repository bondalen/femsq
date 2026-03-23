# Таблица Access: `ralpRaSumTest`

**Статус описания:** достаточно для дальнейшей работы — зафиксированы метаданные TableDef, 10 полей; индексы и связи в дампе не обнаружены.

**Назначение:** локальный буфер сводных показателей по аренде земли (`af_type = 3`, лист `учет_аренды`). В SQL Server целевая staging-таблица: `ags.ra_stg_ralp_sm`.

**Источник метаданных:** DAO-дамп `DumpTableDef_Extended` (передан текстом) + сверка со скриншотом конструктора Access.

**Метаданные таблицы (TableDef):** локальная таблица; `DateCreated` 11.01.2022 12:06:56; `LastUpdated` 11.01.2022 12:07:14; `Attributes=0`; в свойствах `RecordCount=24`.

**COUNT(*) failed Err=3008:** ожидаемый эффект Access/DAO при занятой таблице; на состав полей не влияет.

**Ошибки 3008 в `Field.Properties` (`Precision`/`Scale`):** известный DAO-эффект; типы и размеры из блока `FIELD` считаем корректными.

**lastUpdated:** 2026-03-19

---

## Поля (DAO)

Типы: `4` = `dbLong`, `5` = `dbCurrency`, `10` = `dbText`.

| Имя поля | Type | Size | Required | Атрибуты | Комментарий |
|----------|------|------|----------|----------|-------------|
| `ralprsNum` | 4 | 4 | no | 1 | Номер/порядок записи |
| `ralprsSenderStr` | 10 | 255 | no | 2 | Отправитель (текст) |
| `ralprsSender` | 4 | 4 | no | 1 | Ключ отправителя |
| `ralprsArrived` | 4 | 4 | no | 1 | Кол-во поступивших |
| `ralprsInProcess` | 4 | 4 | no | 1 | Кол-во в обработке |
| `ralprsSended` | 4 | 4 | no | 1 | Кол-во отправленных |
| `ralprsReturned` | 4 | 4 | no | 1 | Кол-во возвращенных |
| `ralprsAccepted` | 5 | 8 | no | 1 | Денежная сумма, формат `#,##0.00 ₽;-#,##0.00 ₽` |
| `ralprsY` | 4 | 4 | no | 1 | Год |
| `ralprsAdtKey` | 4 | 4 | no | 1 | Ключ ревизии (`adtKey`) |

Примечание: `ralprsSenderStr` допускает `AllowZeroLength=True`.

---

## Индексы

В дампе раздел `INDEXES` пуст (явные индексы не перечислены).

---

## Связи

В разделе `RELATIONS` дампа связи не перечислены (пусто).

---

## Сырой фрагмент (контроль)

```text
FIELD: ralprsNum       Type: 4 (dbLong)     Size: 4
FIELD: ralprsSenderStr Type: 10 (dbText)    Size: 255
FIELD: ralprsSender    Type: 4 (dbLong)     Size: 4
FIELD: ralprsArrived   Type: 4 (dbLong)     Size: 4
FIELD: ralprsInProcess Type: 4 (dbLong)     Size: 4
FIELD: ralprsSended    Type: 4 (dbLong)     Size: 4
FIELD: ralprsReturned  Type: 4 (dbLong)     Size: 4
FIELD: ralprsAccepted  Type: 5 (dbCurrency) Size: 8
FIELD: ralprsY         Type: 4 (dbLong)     Size: 4
FIELD: ralprsAdtKey    Type: 4 (dbLong)     Size: 4
```
