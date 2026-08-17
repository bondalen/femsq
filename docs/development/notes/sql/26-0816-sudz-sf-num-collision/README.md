# S68: общая очередь «СФ с совпадающими номерами» (`CnInvUplSfDouble`)

**Дата:** 2026-08-16  
**Статус:** ✅ CREATE на DEV (2026-08-16); код наполнения + экран КСДСФ в JAR.  
**Контекст:** модуль КСДСФ (разбор СФ, номер которых уже есть в `ags`); вход из загрузки долгов и (позже) платежей.

## Зачем

В Access:

| Контур | Очередь «двоящих» |
|--------|-------------------|
| Долги | физ. `CnInvDbtUplFileInvDouble` (без FK на строку Excel) |
| Платежи | **нет** таблицы: RecordSource = `CnInvPmtUplTblCnInv` WHERE `ciputciCnInvNumCount IS NOT NULL` + nested `invNum`→`cnInv` |

FEMSQ: одна таблица очереди с **взаимоисключающими** FK на строку staging Excel (`CnInvDbtUplTbl` / `CnInvPmtUplTbl`), статус до следующего прогона загрузки, отдельный экран КСДСФ.

## Решения владельца (зафиксировано в chat-plan S68)

1. 1 строка Excel с двоящим номером → 1 строка очереди (`cidutKey` / `ciputKey`).
2. Bulk apply шага СФ **не** вставляет позиции из очереди.
3. Перепривязка / deep-link в Договоры — позже.
4. Статус разбора до следующего полного прогона выгрузки.
5. Вкладка «Повторяющиеся СФ» без смены layout; кнопка открытия экрана КСДСФ.

## Файлы

| Файл | Назначение |
|------|------------|
| `30_CREATE_CnInvUplSfDouble_S68.sql` | DEV (2022+), `IF OBJECT_ID … IS NULL` |
| `MSSQL2012/30_CREATE_CnInvUplSfDouble_S68.sql` | тот же DDL без конструкций 2016+ |
| `MSSQL2012/00_VERIFY_before.sql` | заготовка проверки |

`ags.*` не изменяет. Legacy `sudz.CnInvDbtUplFileInvDouble` **пока остаётся**; переход кода на новую таблицу — отдельный шаг реализации (после approve DDL).

## Имя / префикс

- Таблица: `sudz.CnInvUplSfDouble`
- Префикс колонок: `cius*` (Cn Inv Upl Sf)

## Связанные доки

- [chat-plan S68](../../chats/chat-plan/chat-plan-26-0802-sudz.md)
- Access pmt InvDouble RecordSource / `btnInvCreate` — зафиксированы в S68 плана
- Staging dbt/pmt: [26-0812-sudz-dbt-upl-staging](../26-0812-sudz-dbt-upl-staging/)

**lastUpdated:** 2026-08-16
