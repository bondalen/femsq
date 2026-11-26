# C2 §3.5.6 — UX вкладки «Загрузка пунктов»

**Дата:** 2026-11-26 · **Задача:** 0081 · **План:** §3.5.6  
**Файл:** `InvestmentProgramsView.vue` (панель `load-points`)

## Решение

1. **Один канал ошибок** — убран блок `investment-programs-apply-errors`; детали только в «Ход загрузки» (`iilResults` / `logHtml`). Краткая chip-строка summary (счётчики) сохранена без списка.
2. **Лог на всю высоту** — `fill-pane` + `col scroll`; снят `max-height: 24rem`.
3. **Toolbar A** — одна строка `no-wrap`: load · prev ИП · Проверить · Загрузить; hint prev → `QTooltip`; meta/summary с фиксированной `min-height`, без прыжка шапки.

## Статус

✅ код + JAR **0.1.0.413-SNAPSHOT** (2026-11-26)  
UI-check: нет `apply-errors`; toolbar A; высота лога ~626px (было max 24rem).

## Прогон проверки (2026-11-26 ~17:35)

| Проверка | Факт |
|----------|------|
| JAR | `0.1.0.413-SNAPSHOT` |
| Сценарий | ИП **28** · load **9** (`sql_i`) · **Проверить** (dryRun) |
| Toolbar A | ✅ `investment-programs-load-toolbar` |
| Нет розового `apply-errors` | ✅ DOM отсутствует; ошибки только в «Ход загрузки» (`CSTAGPN_NOT_FOUND`…) |
| Summary chip | ✅ одна строка: листьев 621 · применено 13 · уже 588 · ошибок 20 |
| Высота лога | ✅ **626px** |
| load 9–11 `iilResults` | ✅ без изменений (4017/3019/3020) — dryRun не пишет |
| Toast | «…ошибок 20 — см. лог» |
