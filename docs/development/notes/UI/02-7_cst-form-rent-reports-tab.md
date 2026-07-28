# Форма `cst` — вкладка «отчёты, аренда»

**Дата:** 2026-07-24  
**Access:** subform на вкладке «отчёты, аренда» — RecordSource `ralpRaCst` + nested `Au_t` (`ags.ralpRaAu`)

## Иерархия данных

```text
cst
 └ tab «отчёты, аренда»
      ├ список = Access ralpRaCst (JOIN ralpRa↔cstAgPn↔cstAg↔og↔ogAgCs)
      ├ карточка = ags.ralpRa
      └ строки = ags.ralpRaAu          // Access Au_t, CRUD
```

Связь со стройкой: `ralpRa.ralprCstAgPn` → `cstAgPn.cstapKey` → `cstAg` → `cst`.

В SQL Server объекта `ralpRaCst` нет — список собирается JDBC JOIN (см. план).

## GraphQL

| Операция | Назначение |
|----------|------------|
| `cstRalpRaList(cstKey)` | перечень (как continuous form) |
| `ralpRa(id)` | карточка заголовка |
| `ralpRaAus(ralprKey)` | строки Au |
| `ralpRaAuStatusLookups` | статусы 0..3 (константы) |
| `create/update/deleteRalpRa` | CRUD заголовка |
| `create/update/deleteRalpRaAu` | CRUD Au |

Удаление `ralpRa` блокируется, если есть `ralpRaAu`.

Статусы Au: 0 не представлен · 1 в работе · 2 направлен в бухгалтерию · 3 возвращён агенту.

**Отправитель (`ralprOgSender`):** в БД встречается и `og.ogKey`, и ключ варианта имени `ogNmF.onfKey` (Stage 2 reconcile пишет `onfKey`). Подпись в UI: `og.ogNm`, иначе `ogNmF.onfOg`→`og.ogNm` / `onfName`. Не путать с `ogAgCs` (агент стройки).

## UI (Java)

Компонент [`CstRentReportsTab.vue`](../../../../code/femsq-frontend-q/src/views/construction-sites/CstRentReportsTab.vue):

1. Dense-таблица списка (№, дата, САК, агент, отправитель).
2. Клик → карточка + таблица Au с диалогами CRUD.
3. Horizontal splitter (`femsq.cst.rentSplit`).

## Вне scope

- Поля `ralpraTestStartDate` / `ralpra_fdKey` в UI.
- Каскадное удаление Au при удалении заголовка.
