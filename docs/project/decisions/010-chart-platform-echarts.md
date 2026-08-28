# Решение 010: Платформа графиков — ECharts + FemsqChart (feQuLib)

**Дата:** 2026-08-28  
**Последнее обновление:** 2026-08-28  
**Статус:** ✅ Принято  
**Участники:** Александр, Cursor AI

## Проблема

Интерактивные графики нужны в нескольких зонах FEMSQ (КСДД, форма `cst` «график всего/виды», портфель, preview отчётов). Разрозненные SVG/sparkline или лёгкие библиотеки быстро упрются в zoom, markLine, несколько серий и единый стиль. PDF-отчёты уже идут через JasperReports; UI и отчёты должны делить **семантику данных**, не обязательно один движок рендера.

## Решение

1. **Интерактив UI:** Apache **ECharts 5** через обёртку **`FemsqChart`** в **feQuLib** (аналог `FemsqTable` / `FemsqTree`).
2. **Контракт данных:** TypeScript **`ChartSpec`** / **`TimeSeriesSpec`** в feQuLib; GraphQL возвращает точки ряда, FE собирает `ChartSpec` (или JSON-поле на backend позже).
3. **PDF / печать:** **JasperReports** (см. [ADR-003](./adr-003-reporting-engine.md)); тот же SQL, что и для интерактивного ряда. Headless ECharts для PDF — не в v1.
4. **Legacy JFreeChart** на prod — не развиваем; только вывод из стека.

## Граница хост ↔ lib (как 008)

| Зона | Владелец |
|------|----------|
| Палитра продукта, light/dark | FEMSQ (`--femsq-*`) |
| Плотность, оси, tooltip, resize в splitter | feQuLib (`FemsqChart`, `--fequlib-chart-*`) |
| Доменные данные | Backend GraphQL |

## Первый потребитель

**КСДД** (сегм. 22c): вкладка «Динамика» — ряд `DbtValue` по выбранному слоту; советник `[advisor]` в «Сообщения».

## Следующие потребители

- `cst` D.4 (графики освоения) — тот же `FemsqChart`.
- Pilot Jasper-отчёт с тем же SQL, что timeline.

## Связанные документы

- [008 feQuLib](./008-fequlib-and-docs-registry.md)
- [chat-plan SUDZ §22c](../../../development/notes/chats/chat-plan/chat-plan-26-0802-sudz.md)
