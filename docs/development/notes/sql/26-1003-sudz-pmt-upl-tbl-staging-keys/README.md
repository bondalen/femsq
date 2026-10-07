# 26-1003 — staging-ключи на `sudz.CnInvPmtUplTbl` (1.13.1)

**Дата:** 2026-10-03  
**План:** [chat-plan-26-0922 §1.13.1](../../chats/chat-plan/chat-plan-26-0922-pmt-upl-ui-complete.md)  
**Опора:** [export-row-tree-structure §7.0 правило B](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/export-row-tree-structure.md)

## Зачем

На белых строках Excel→Tbl писать промежуточные ключи традиционной раскладки:

| Колонка | Смысл |
|---------|--------|
| `ciputSfKey` | СФ файла (кредитор + договор + присвоение), суррогат в пределах пакета |
| `ciputCacSpanKey` | сплошной отрезок стройки внутри СФ файла |
| `ciputDueKey` | жёлтый итог срока (одна L3-группа) |
| `ciputDueGrp` | 1…n внутри пакета + СФ + CAC + срок |

Все колонки **nullable**; старые строки / нетрадиционная раскладка → `NULL`. Жёлтые строки в Tbl по-прежнему не пишутся.

## Скрипты

| Файл | |
|------|--|
| `01_ALTER_CnInvPmtUplTbl_staging_keys.sql` | ADD 4 колонок (dev / 2016+) |
| `MSSQL2012/01_ALTER_CnInvPmtUplTbl_staging_keys.sql` | то же для prod 2012 |
| `05_ROLLBACK.sql` | DROP колонок |

**Prod:** только `MSSQL2012/`.
