# Таблица Access: `CnInvDbtUplTbl`

**Статус:** структура + данные сняты (2026-08-12).  
**Источник:** [`CnInvDbtUplTbl.dump.utf8.txt`](./CnInvDbtUplTbl.dump.utf8.txt), [`CnInvDbtUplTbl.csv`](./CnInvDbtUplTbl.csv) (~345 KB)  
**Тип:** локальная Access; **эфемерный staging** (при `cidufFlTbl` — `DELETE *` затем наполнение из Excel).  
**Записей:** **1548** — все с `cidutUnloadKey=26` (последний свод YE2024 / File key 20).  
**PK / индексы / Relations:** **нет** в TableDef.

## Назначение

Построчный буфер «найденных задолженностей» из листов свода до воронки match/insert в `ags`. Поля 1:1 с заголовками Excel (§2.7) + служебные Null-заменители для SQL Access.

## Поля

| Поле | DAO | Size | Req | Описание |
|------|-----|------|-----|----------|
| `FindDbtNum` | dbInteger | 2 | нет | № найденной задолженности (default 0) |
| `cidutAccount` | dbLong | 4 | нет | Счёт ГК → lookup `ags_accnt` |
| `cidutCntrPrtNum` | dbLong | 4 | нет | № контрагента (БУиРГ) |
| `cidutCntrPrtName` | dbText | 255 | нет | Контрагент |
| `cidutCntrPrtITN` | dbText | 255 | нет | ИНН |
| `cidutCnName` | dbText | 255 | нет | Договор |
| `cidutCnDate` | dbDate | 8 | нет | Дата договора |
| `cidutCnInv` | dbText | 255 | нет | Документ основания (счёт-фактура) |
| `cidutCnInvName` | dbText | 255 | нет | Имя задолженности по СФ |
| `cidutFormtnDate` | dbDate | 8 | нет | Дата образования |
| `cidutMatrtyDate` | dbDate | 8 | нет | Срок погашения |
| `cidutDebt` | dbCurrency | 8 | нет | Всего сумма задолженности |
| `cidutDebtOverdue` | dbCurrency | 8 | нет | Просроченная задолженность |
| `cidutDoc` | dbText | 255 | нет | Документ основания (присвоение ГК) |
| `cidutLink` | dbText | 255 | нет | Ссылка |
| `cidutSheet` | dbLong | 4 | нет | проверяемый лист (`cidufsKey`?) |
| `cidutSheetNum` | dbLong | 4 | нет | № строки на листе |
| `cidutUnloadKey` | dbLong | 4 | нет | выгрузка (= `upl_key` / `cidufUpload`) |
| `cidutCnDateNull` | dbDate | 8 | нет | вместо null → 01.01.1900 (Attr 2 — вероятно вычисляемое) |
| `cidutCnNameNull` | dbText | 243 | нет | вместо null/пусто → `"NullИлиПусто"` |
| `cidutCnInvNull` | dbText | 243 | нет | то же для СФ |
| `cidutCnInvNameNull` | dbText | 243 | нет | то же для имени |

## Данные (факты снимка)

- Один пакет: `cidutUnloadKey=26` (все 1548).
- `FindDbtNum` = 1…1548 подряд.
- `cidutSheet` ∈ {133…138} = `cidufsKey` листов File key 20; распределение по счетам: 19→1142, 21→178, 29→158, 24→40, 28→16, 23→14.
- Уникальных `cidutCnInv`: 1519.
- В снимке `NullИлиПусто` в Name/Inv — 0 (колонки `*Null` всё же заполнены нормализованными значениями).

## Для FEMSQ / SQL

- Staging в `sudz`: нужна **идентификация пакета** (`cidutUnloadKey` / FK на upl) + желательно суррогатный PK; в Access PK нет.
- Колонки `*Null` — артефакт Access-SQL; на сервере лучше `NULL` + нормализация в коде, либо сохранить для паритета запросов воронки.
- Таблица **перезаписывается** на загрузку — не «история всех сводов», а текущий буфер (сейчас 1548 ≈ один upl).

**lastUpdated:** 2026-08-12
