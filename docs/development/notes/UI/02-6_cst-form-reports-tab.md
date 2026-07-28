# Форма `cst` — вкладка «отчёты»

**Дата:** 2026-07-23  
**Access:** subform `cst>ra_t` (список) + detail `ags.ra` + nested `ags.ra_summ`

## Иерархия данных

```text
cst
 └ tab «отчёты»
      ├ список = ags.fnRRcList(@cstKey)   // отчёты UNION изменения
      ├ карточка = ags.ra                 // только базовые (raChKey IS NULL)
      └ суммы = ags.ra_summ               // версии, CRUD как Access dynaset
```

Связь отчёта со стройкой: `ra.ra_cac` → `cstAgPn.cstapKey` → `cstAg` → `cst`.

## GraphQL

| Операция | Назначение |
|----------|------------|
| `cstRaList(cstKey)` | перечень (как continuous form) |
| `constructionSiteReport(id)` | карточка RA |
| `raSums(raKey)` | версии сумм |
| `raPeriodLookups` / `cstAgPnLookupsForSite` | combobox |
| `create/update/deleteRaReport` | CRUD отчёта |
| `create/update/deleteRaSumm` | CRUD сумм |

Удаление RA блокируется, если есть `ags.ra_change`.

## UI (Java)

Компонент [`CstReportsTab.vue`](../../../../code/femsq-frontend-q/src/views/construction-sites/CstReportsTab.vue):

1. Dense-таблица списка (колонки как Access `cst>ra_t`).
2. Клик по базовому отчёту → карточка + вкладки суммы / изменения(stub) / примечания (как `cst>ra_f` + Filter по `ra_key`).
3. Строки изменений в списке — только просмотр (CRUD `ra_change` позже).

**Синхронизация Access (VBA):**

| Событие | Access | Java |
|---------|--------|------|
| Смена стройки (`Form_cst.Form_Current`) | `ra_t.Requery` + Filter `ra_f` по `ra_key` | `selectSite` → `loadRaList` |
| Смена строки списка (`Form_cst>ra_t.Form_Current`) | `ra_f.Filter = "ra_key = …"` | `selectRa(raKey)` |

**Исправление 2026-07-24:** в `CstReportsTab` не были импортированы компоненты Quasar (`QTable`/`QDialog`…), поэтому таблица не рисовалась, а заголовки диалогов «Новый отчёт»/«Новые суммы» утекали в поток страницы.

## Вне scope этого захода

- CRUD `ags.ra_change` / `ra_change_summ` (вкладка «изменения»).
- Chart / `fnRRcListUtil`.
- Вкладка «отчёты, аренда» — см. [02-7](02-7_cst-form-rent-reports-tab.md).
