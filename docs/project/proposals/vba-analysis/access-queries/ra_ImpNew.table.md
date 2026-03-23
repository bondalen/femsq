# Таблица Access: `ra_ImpNew`

**Статус описания:** **достаточно для дальнейшей работы** — зафиксированы назначение таблицы, 26 полей (DAO-типы, NULL/REQ), индексы, связь со staging `ags.ra_stg_ra`, подводные камни Immediate/UTF-8 и бинарные свойства TableDef. Логика сверки — в SQL [`ra_ImpNewQuRa.access.sql`](./ra_ImpNewQuRa.access.sql) / [`ra_ImpNewQuRc.access.sql`](./ra_ImpNewQuRc.access.sql) и в [`ra-audit-btnAuditRun-analysis.md`](../../../development/notes/analysis/ra-audit-btnAuditRun-analysis.md).

**Канон подписей:** для поля `rainRaReturnedSum` в документации проекта используется **«Сумма возвращенных ОА»** (кириллическая **С**). Метаданные в файле `.accdb` приведите в соответствие вручную: конструктор таблицы → поле `rainRaReturnedSum` → **Описание** и **Подпись** = `Сумма возвращенных ОА`.  
**SQL Server:** для уже развёрнутых БД добавлен changeset `femsq:2026-03-21-ra-col-map-normalize-returned-sum` — правит `ags.ra_col_map` (`rcm_key` 27/47, удаляет дубликаты 28/48); см. `code/.../changes/2026-03-21-ra-col-map-cyrl-c-fix.sql`.

Источник: выгрузка через DAO `TableDefs`, стандартный модуль.

**Расширенный дамп (индексы, связи, свойства полей/таблицы, опционально `COUNT(*)`):**  
файл модуля [`DumpTableDef_RaImpNew.bas`](./DumpTableDef_RaImpNew.bas):

- `DumpTableDef_RaImpNew` — `DumpTableDef_Extended "ra_ImpNew", True, False, True, vbNullString` (Immediate, компактные Field.Properties).
- Полная сигнатура:  
  `DumpTableDef_Extended tableName, includeRecordCount, includeDatasheetUiProps, compactFieldProperties, utf8FilePath`
  - `includeDatasheetUiProps:=True` — ColumnWidth, IMEMode и т.п.
  - `compactFieldProperties:=False` — все безопасные `Field.Properties` без отсечения дублей с блоком `FIELD:`.
  - **`utf8FilePath:="C:\temp\ra_ImpNew.txt"`** — параллельно пишется **UTF-8** файл: кириллица в Description/Caption читается нормально **при открытии этого файла** в редакторе. Если вы **копируете текст из окна отладки**, кириллица снова может стать `РџР»Р°РЅ…` — смотрите именно `.txt` или раздел **«Подписи и описания»** ниже в этом файле.

В окне отладки **имя таблицы и путь — только в кавычках**, иначе VBA считает их переменными → **ошибка 424 Object required**.  
Пример: `DumpTableDef_Extended "ra_ImpNew", True, False, False, "C:\temp\ra_ImpNew.txt"`.

В выводе **не читаются** свойства **Recordset.Field** (`Value`, `ForeignName`, …). Сообщения об ошибках — без русского `Err.Description` (только номер).

**«Китайские» символы в `TableDef.Properties`:** свойства **`GUID`** и **`NameMap`** в DAO — **бинарные** (Property.Type **9** / **11**). Если выводить их как строку, получается случайный «мусор» и псевдо-CJK; это **не** данные таблицы и **не** ошибка UTF-8 для полей. В актуальной версии [`DumpTableDef_RaImpNew.bas`](./DumpTableDef_RaImpNew.bas) такие значения помечаются как `<binary/skipped>`. Свойства **`ConflictTable`** / **`ReplicaFilter`** для локальной таблицы часто недоступны (Err 3032) — в дампе **пропускаются**.

**Назначение в VBA:** промежуточное хранилище строк импорта «отчёты всех агентов» перед reconcile; в Java/SQL Server аналог — `ags.ra_stg_ra` (имена колонок согласованы с префиксом `rain*`).

### Достаточно ли скриншота конструктора таблицы?

- **Для смыслового описания** (имена полей, типы в терминах Access, колонка **«Описание»**) — **да**, скриншот режима конструктора — нормальный источник правды «для человека».
- **Для полной техспеки** лучше **дополнять** скриншотом **UTF-8-дамп** (или нижнюю панель *Свойства поля* в Access): там видны **`Caption` ≠ `Description`**, строки **`Format`**, обязательность, индексы, связи, размеры `dbText`/`Memo` и т.д. — в сетке конструктора это не всё на одном экране.
- **`РџР»Р°РЅ…` в выводе Immediate** — это не «битая» база: текст в отладке фактически **UTF-8**, а при копировании/просмотре его читают как однобайтную (ANSI) кодировку → **mojibake**. В UTF-8-файле дампа кириллица совпадает с конструктором — для документации и репозитория опирайтесь на **файл**, не на копипаст из Immediate.

**Порядок снятия сведений для других таблиц Access:** [MS-ACCESS-OBJECTS-CAPTURE.md](../MS-ACCESS-OBJECTS-CAPTURE.md), каталог артефактов — [README.md](./README.md) (один `{таблица}.table.md` на таблицу; запросы — `{запрос}.access.sql` после доработки из исходного `.txt`).

**lastUpdated:** 2026-03-19

---

## Поля

| Имя поля | DAO Type | Размер | Обязательное | Примечание (расшифровка типа) |
|----------|----------|--------|--------------|-------------------------------|
| `rainRow` | 4 (dbLong) | 4 | REQ | Целое long — номер строки источника |
| `rainSender` | 10 (dbText) | 255 | REQ | Текст |
| `rainCstAgPnStr` | 10 (dbText) | 255 | REQ | Текст (код стройки / ИПГ) |
| `rainCstName` | 12 (dbMemo) | 0 | null | Мемо |
| `rainRaNum` | 10 (dbText) | 255 | REQ | Номер ОА |
| `rainRaDate` | 8 (dbDate) | 8 | null | Дата/время |
| `rainTtl` | 5 (dbCurrency) | 8 | null | Денежная сумма |
| `rainWork` | 5 (dbCurrency) | 8 | null | Денежная сумма |
| `rainEquip` | 5 (dbCurrency) | 8 | null | Денежная сумма |
| `rainOthers` | 5 (dbCurrency) | 8 | null | Денежная сумма |
| `rainArrivedNum` | 10 (dbText) | 255 | null | Текст |
| `rainArrivedDate` | 8 (dbDate) | 8 | null | Дата |
| `rainArrivedDateFact` | 8 (dbDate) | 8 | null | Дата |
| `rainReturnedNum` | 10 (dbText) | 255 | null | Текст |
| `rainReturnedDate` | 8 (dbDate) | 8 | null | Дата |
| `rainReturnedReason` | 12 (dbMemo) | 0 | null | Мемо |
| `rainSendNum` | 10 (dbText) | 255 | null | Текст |
| `rainSendDate` | 8 (dbDate) | 8 | null | Дата |
| `rainUnit` | 10 (dbText) | 255 | null | Текст |
| `rainSign` | 10 (dbText) | 255 | null | Текст (признак) |
| `rainRaSheetsNumber` | 3 (dbInteger) | 2 | null | Целое 16-bit |
| `rainTitleDocSheetsNumber` | 3 (dbInteger) | 2 | null | Целое 16-bit |
| `rainPlanNumber` | 3 (dbInteger) | 2 | null | Целое 16-bit |
| `rainPlanDate` | 8 (dbDate) | 8 | null | Дата |
| `rainRaSignOfTest` | 2 (dbByte) | 1 | null | Байт |
| `rainRaSendedSum` | 5 (dbCurrency) | 8 | null | Денежная сумма |
| `rainRaReturnedSum` | 5 (dbCurrency) | 8 | null | Денежная сумма |

Последний столбец в сыром выводе VBA (`1` / `2`) соответствует атрибутам поля DAO (например, фиксированная/переменная длина для текстовых типов), для портирования на SQL Server обычно достаточно имя + тип + NULL/NOT NULL.

### Подписи и описания (DAO: Caption / Description)

Если в Immediate кириллица «ломается» (`РџР»Р°РЅ…`), это **mojibake** при копировании, а не обязательно ошибка в базе. Ниже — канон из метаданных Access (UTF-8-дамп / конструктор). У части полей **Caption** и **Description** различаются.

| Поле | Caption (подпись) | Description (описание) | Примечание |
|------|-------------------|-------------------------|------------|
| `rainRow` | Номер строки | Номер строки | |
| `rainSender` | Агент | Агент, вернее отправитель | |
| `rainCstAgPnStr` | Стройка, код | Код стройки | |
| `rainCstName` | Стройка, Имя | Наименование стройки | |
| `rainRaNum` | Отчёт агента, № | № ОА | |
| `rainRaDate` | Отчёт агента, дата | Дата ОА | Формат в Access: `dd.mm.yyyy` |
| `rainTtl` | Всего с НДС | Всего с НДС | |
| `rainWork` | *(часто пусто)* | СМР | Формат: `#,##0.00 ₽` |
| `rainEquip` | Оборудование | Оборудование | |
| `rainOthers` | Прочие | Прочие | |
| `rainArrivedNum` | Поступило_№_письма | Поступило_№_письма | |
| `rainArrivedDate` | Поступило (Дата письма) | Поступило (Дата письма) | |
| `rainArrivedDateFact` | Поступило (Фактическая дата) | Поступило (Фактическая дата) | |
| `rainReturnedNum` | Возвращен на доработку (№ письма) | Возвращен на доработку (№ письма) | |
| `rainReturnedDate` | Возвращен на доработку (дата письма) | Возвращен на доработку (дата письма) | Формат: General Date |
| `rainReturnedReason` | Причина возврата | Причина возврата | |
| `rainSendNum` | Направлен в Бухгалтерию (№ СЗ) | Направлен в Бухгалтерию (№ СЗ) | |
| `rainSendDate` | Направлен в Бухгалтерию (дата СЗ) | Направлен в Бухгалтерию (дата СЗ) | |
| `rainUnit` | Отдел Управления | Отдел Управления | |
| `rainSign` | Признак | Признак | |
| `rainRaSheetsNumber` | Кол-во листов ОА | Кол-во листов ОА | |
| `rainTitleDocSheetsNumber` | Кол-во листов ПУД | Кол-во листов ПУД | |
| `rainPlanNumber` | План кол-во | План кол-во | |
| `rainPlanDate` | План дата | План дата | Формат: `dd.mm.yyyy` |
| `rainRaSignOfTest` | Признак проверки ОА | Признак проверки ОА | |
| `rainRaSendedSum` | Сумма переданных ОА | Сумма переданных ОА | |
| `rainRaReturnedSum` | Сумма возвращенных ОА | Сумма возвращенных ОА | Кириллическая **С**; см. канон в шапке |

### Индексы (имена как в Access)

| Имя индекса | Поле | Уникальность |
|-------------|------|--------------|
| `rainRow` | `rainRow` | Да (без дубликатов) |
| `Код стройки` | `rainCstAgPnStr` | Нет |

### Полный дамп TableDef в репозитории (опционально)

Файл с локальной машины (`C:\temp\…`) в Cursor по пути не подтягивается — при необходимости скопируйте UTF-8-дамп в репозиторий, например:

`ra_ImpNew.dump.utf8.txt`

(имя рядом с `{tableName}.table.md`).

---

## Сырой вывод (как в окне отладки)

```
TABLE: ra_ImpNew
rainRow        4             4            REQ                          1 
rainSender     10            255          REQ                          2 
rainCstAgPnStr               10            255          REQ                          2 
rainCstName    12            0            null                         2 
rainRaNum      10            255          REQ                          2 
rainRaDate     8             8            null                         2 
rainTtl        5             8            null                         2 
rainWork       5             8            null                         2 
rainEquip      5             8            null                         2 
rainOthers     5             8            null                         2 
rainArrivedNum               10            255          null                         2 
rainArrivedDate              8             8            null                         2 
rainArrivedDateFact          8             8            null                         2 
rainReturnedNum              10            255          null                         2 
rainReturnedDate             8             8            null                         2 
rainReturnedReason           12            0            null                         2 
rainSendNum    10            255          null                         2 
rainSendDate   8             8            null                         2 
rainUnit       10            255          null                         2 
rainSign       10            255          null                         2 
rainRaSheetsNumber           3             2            null                         1 
rainTitleDocSheetsNumber     3             2            null                         1 
rainPlanNumber               3             2            null                         1 
rainPlanDate   8             8            null                         2 
rainRaSignOfTest             2             1            null                         1 
rainRaSendedSum              5             8            null                         2 
rainRaReturnedSum            5             8            null                         2 
```

---

## Ссылка на схему в проекте

DDL staging в SQL Server: Liquibase `ags.ra_stg_ra` в `code/femsq-backend/femsq-web/src/main/resources/db/changelog/changes/2026-03-20-ra-audit-staging.sql` (в т.ч. `rain_exec_key` для изоляции сеанса — в Access-таблице этого поля нет).
