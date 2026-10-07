# 26-1003 — `ags.cn_inv_pm.cn_inv_pm_due_grp` (1.13.2)

**Дата:** 2026-10-03  
**План:** [chat-plan-26-0922 §1.13.2](../../chats/chat-plan/chat-plan-26-0922-pmt-upl-ui-complete.md)  
**Опора:** [export-row-tree-structure §7.0 правило C](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/export-row-tree-structure.md)

## Зачем

Порядковый номер жёлтой группы срока внутри пакета+СФ+CAC+срок (1…n). Почти везде `1`; кейс `0620CR000478` / 28.02.2026 — `1` и `2`. Исторические строки остаются `NULL` до перезаливки InsPm.

Источник при INSERT — staging `sudz.CnInvPmtUplTbl.ciputDueGrp` (**1.13.3**).

| Колонка | Тип |
|---------|-----|
| `ags.cn_inv_pm.cn_inv_pm_due_grp` | `smallint NULL` |

## Скрипты

| Файл | |
|------|--|
| `01_ALTER_cn_inv_pm_due_grp.sql` | ADD (dev / 2016+) |
| `MSSQL2012/01_ALTER_cn_inv_pm_due_grp.sql` | prod 2012 |
| `05_ROLLBACK.sql` | DROP колонки |

**Prod:** только `MSSQL2012/`.
