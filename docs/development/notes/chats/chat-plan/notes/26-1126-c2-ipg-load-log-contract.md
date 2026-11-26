# C2 §3.5.4 — структурированный лог загрузки годовой ИП (реализация)

**Дата:** 2026-11-26 · **Задача:** 0081 · **Эталон UX:** «Ход ревизии» (`AuditExecutionContext` → `adt_results`)  
Подготовительный контракт: [26-1126-c2-o1-ipg-load-log-contract.md](26-1126-c2-o1-ipg-load-log-contract.md).

## Контракт

Серверные события (spans) → HTML с `<details>/<summary>` → FE `v-html` внутри `.audit-log-surface`
(глобальные стили `styles/audit-log.css`, подключены в `main.ts`). Лог накопительный по сессии `impIpgLoad`:
каждая операция (parse / reconcile / apply) добавляет свой блок `IPG_LOAD_START … IPG_LOAD_END|IPG_LOAD_ERROR`
к ранее сохранённому HTML.

| Слой | Где |
|------|-----|
| DDL | `ags.impIpgLoad.iilResults nvarchar(max) NULL` — [`sql/26-1126-impipg-iilresults/`](../../../sql/26-1126-impipg-iilresults/README.md) |
| Билдер | `com.femsq.database.ipglog` (`ImpIpgLoadLogContext`, `…Entry/Level/Scope/Codes/Support`) — тонкая копия модели `AuditExecutionContext`, без зависимости от web |
| DAO | `ImpIpgLoadDao.updateLoadResults(iilKey, html)`; `ImpIpgLoad.iilResults`; SELECT с откатом без колонки (warning) |
| GraphQL | `ImpIpgLoad.logHtml`; `logHtml` в `ImpIpgParseResult`, `ImpIpgReconcileResult`, `ImpIpgPointsApplyResult`; `errors[]` сохранён |
| FE | `imp-ipg-load-api.ts` (типы + запросы), Structure — вкладка «Ход загрузки», Инвестпрограммы → «Загрузка пунктов» — панель «Ход загрузки» |

## Уровни и области

Levels: `INFO · SUCCESS · WARNING · ERROR · SUMMARY` → CSS `lvl-*`.  
Scopes: `LOAD · FILE · PARSE · RECONCILE · GATE · STI · SH · APPLY · SUMMARY` (LOAD и FILE раскрыты по умолчанию; блоки с WARNING/ERROR внутри раскрываются автоматически).

## Коды событий

| Операция | Коды |
|----------|------|
| Любая | `IPG_LOAD_START` → … → `IPG_LOAD_END` \| `IPG_LOAD_ERROR` |
| Parse (`ImpIpgExcelParseService`) | `FILE_RESOLVE_OK` \| `FILE_MISSING`, `WORKBOOK_OPEN` … `WORKBOOK_CLOSE`, `PARSE_START`, `PARSE_SHEET`, `PARSE_STATS`, `PARSE_STAGING_WRITTEN`, `PARSE_END` |
| Reconcile (`DefaultImpIpgReconcileService`) | `RECONCILE_START`, `RECONCILE_ROW_OPEN` (WARN, ≤ 20 примеров), `RECONCILE_STATS`, `RECONCILE_END` |
| Apply (`DefaultImpIpgPointsApplyService`) | `APPLY_START`; вложенно `GATE_START/GATE_SOFT_OPEN (WARN)/GATE_OK/GATE_END`, `STI_INHERIT_START/STATS/END`, `SH_RESOLVE_START/STATS/END`; `APPLY_ROW_ERR`, `APPLY_SKIP_ALREADY`, `APPLY_STATS`, `APPLY_END` |

Маппинг ошибок apply: `CSTAGPN_NOT_FOUND`, `STI_HOLE`, `SH_RESOLVE` (и `INSERT_FAIL`) → `APPLY_ROW_ERR` (ERROR, **свёртка по причине**: счётчик + до 20 примеров; исходный код — в `meta.reason`).
`ALREADY_EXISTS` → `APPLY_SKIP_ALREADY` (INFO, одна агрегированная строка). Soft-open ПТСФ → `GATE_SOFT_OPEN` (WARNING; apply не прерывается).

## Правила persist / возврата

- `parseImpIpgLoad`, `reconcileImpIpgStructure(persistMatches=true)`, `applyImpIpgPoints(dryRun=false)` — лог пишется в `iilResults`; ответ содержит **накопительный** `logHtml`.
- `applyImpIpgPoints(dryRun=true)` — `logHtml` возвращается (предыдущий лог + проверка), **в БД не пишется**.
- Query `impIpgStructureReconcile` и reconcile с `persistMatches=false` — лог не строится (`logHtml = null`).
- Ошибка parse/reconcile: блок `IPG_LOAD_ERROR` сохраняется, исключение пробрасывается как раньше. Жёсткий отказ apply (нет сессии/ipg/`ipgStRlSh`/листьев) — `IPG_LOAD_ERROR` + `errors[]`.
- Сбой записи лога не ломает операцию (warning). Предохранитель: накопленное тело > 1 000 000 символов усекается с пометкой.
- Не использовать `adt_results`; сообщения экранируются (`ImpIpgLoadLogContext.esc`).

## Хвосты

- DDL `MSSQL2012/01_ALTER_impIpgLoad_iilResults.sql` на прод — при выкладке (DEV `FishEye_prod_noM6`: применён 2026-11-26).
- UI-smoke parse → reconcile → apply: ✅ §3.5.5 (2026-11-26) на `SMOKE_LOG_261126` / load12; note [26-1126-c2-o1-ipg-load-log-ui-smoke-355.md](26-1126-c2-o1-ipg-load-log-ui-smoke-355.md).
- GATE/STI/SH-эндпоинты-превью (`impIpgPointsGate`, …) лог не пишут — только внутри apply.
