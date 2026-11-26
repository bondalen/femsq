# Контракт: структурированный лог загрузки годовой ИП

**Дата:** 2026-11-26  
**План C2:** §3.5.4  
**Задача:** 0081  
**Эталон UX:** «Ход ревизии» (`AuditExecutionContext` → HTML `<details>`)

## Цель

Один журнал на сессию `impIpgLoad` (Structure parse/reconcile + Leaves apply): вложенные свёртываемые фазы от пути файла до CLOSE, уровни как у ревизий.

## Persist

- Колонка `ags.impIpgLoad.iilResults` (`nvarchar(max)` HTML) — накопительный лог по `loadKey`.
- GraphQL: `logHtml` в ответах parse/reconcile/apply; поле на типе load.
- Не писать в `adt_results`.

## Scopes / levels

Scopes: `LOAD` · `FILE` · `PARSE` · `RECONCILE` · `GATE` · `STI` · `SH` · `APPLY` · `SUMMARY`  
Levels: `INFO` · `SUCCESS` · `WARNING` · `ERROR` · `SUMMARY`

## Spine

```
IPG_LOAD_START
  FILE_RESOLVE_OK | FILE_MISSING
  WORKBOOK_OPEN … WORKBOOK_CLOSE
  PARSE_* · RECONCILE_* · GATE_* · STI_* · SH_*
  APPLY_* (APPLY_SKIP_ALREADY INFO; ERR свёртка по коду)
IPG_LOAD_END | IPG_LOAD_ERROR
```

Плоский `errors[]` сохраняется для совместимости.
