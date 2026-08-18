# Карта Offset `export_*` → `CnInvPmtUplTbl`

**Снято:** 2026-08-18  
**Каталог:** `D:\wire-guard-share-nb-win\femsq\excel\2026_03\debit` (WSL: `/mnt/d/wire-guard-share-nb-win/femsq/excel/2026_03/debit`)  
**Файлы (заголовки **идентичны**):**  
`export_606012_26-0422.XLSX`, `export_606022_26-0422.XLSX`, `export_761010_26-0422.XLSX`, `export_767501_26-0422.XLSX`, `export_767502_26-0422.XLSX`

Лист: **`Sheet1`**. Якорь VBA `Find("№ докум.", xlWhole)`: строка **1**, колонка **U**. Колонок на листе **A–Z**, без merge. Другие периоды в этом проходе не открывались.

VBA (`PaymentUnloadTest`): фиксированные `Offset(0, n)` от ячейки «№ докум.», не поиск по заголовкам.

| Offset | Col | Поле `CnInvPmtUplTbl` | Заголовок Excel |
|--------|-----|------------------------|-----------------|
| −20 | A | `ciputBE` | БЕ |
| −19 | B | `ciputAccount` | Счет ГК |
| −18 | C | `ciputCntrPrtNum` | Кредитор |
| −17 | D | `ciputCntrPrtName` | Наименование кредитора |
| −16 | E | `ciputCAC` | Код стройки |
| −15 | F | `ciputAgentNum` | Агент |
| −14 | G | `ciputAgentName` | Агент |
| −13 | H | `ciputCnName` | Договор |
| −12 | I | `ciputLink` | Ссылка |
| −11 | J | `ciputCnInv` | Присвоение |
| −10 | K | `ciputEntryDate` | Д/проводки |
| −9 | L | `ciputDocDate` | Д/документ |
| −8 | M | `ciputDueDate` | Срок оплаты |
| −7 | N | `ciputDbtBlns` | Сальдо конечное Дт |
| −6 | O | `ciputDbtBlnsOverd` | Сальдо кон.Дт просроченное |
| −5 | P | `ciputDbtBlnsOverdNot` | Сальдо кон.Дт непросроченн. |
| −4 | Q | `ciputCdtBlns` | Сальдо конечное по Кт |
| −3 | R | `ciputCdtBlnsOverd` | Сальдо кон.Кт просроченное |
| −2 | S | `ciputCdtBlnsOverdNot` | Сальдо кон.Кт непросроченн. |
| −1 | T | `ciputBlns` | Сальдо конечное |
| 0 | U | `ciputCnInvDocCode` | **№ докум.** |
| +1 | V | `ciputAlligmentDate` | Д/выравн. |
| +2 | W | `ciputBaseDate` | БазДата |
| +3 | X | `ciputCnInvDocSum` | Сумма документа |
| +4 | Y | `ciputStornoReason` | ПричСторн |
| +5 | Z | `ciputStornoDocCode` | ДокСторно |

**Замечания**

- F и G в Excel оба подписаны «Агент»; VBA кладёт F → номер, G → имя (как в строке 2 `export_606012`: оба пусты, C/D — кредитор).
- Закомментированный блок Offset в `File_f` (колонки 24/44/…) — **другая** раскладка; живой код совпадает с этой таблицей A–Z.
- Даты в Open XML — serial; Access читает через COM Excel.

**lastUpdated:** 2026-08-18
