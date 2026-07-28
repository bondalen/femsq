# Резюме чата 26-0722: IA форм + экраны Стройки (`cst` / `cstAgPn`)

**Дата:** 2026-07-22 – 2026-07-28  
**Последнее обновление:** 2026-07-28  
**Тема:** Целевая IA верхней строки FEMSQ (Design chrome), GraphQL CRUD строек и дерево агентов, Quasar-экраны `cst` / `cstAgPn`, отчёты/аренда; пауза на FemsqTable→feQuLib→projectize и возврат.  
**Задачи:** [0057](../../../project-development.json), [0058](../../../project-development.json) — **completed**  
**Журнал:** `chat-2026-07-22-001`, `chat-2026-07-28-002`  
**Машина:** nb-win (WSL2); frontend `npm run build` OK; backend connected (`FishEye`/`ags`); Vite `:5175`

## Связанные документы

- [chat-plan-26-0722-forms-ia-cst.md](../chat-plan/chat-plan-26-0722-forms-ia-cst.md) — план (v0.5.0, выполнен в MVP)
- [02-4_app-forms-ia.md](../../UI/02-4_app-forms-ia.md) — IA + Design chrome
- [02-5_cst-form-agents-tab.md](../../UI/02-5_cst-form-agents-tab.md), [02-6](../../UI/02-6_cst-form-reports-tab.md), [02-7](../../UI/02-7_cst-form-rent-reports-tab.md)
- Цепочка FemsqTable: [chat-plan-26-0725-femsq-table.md](../chat-plan/chat-plan-26-0725-femsq-table.md), ADR [008](../../../../project/decisions/008-fequlib-and-docs-registry.md)

## Контекст

- До порта Access `cst`/`cstAgPn` нужны согласованная IA меню и общие UX-паттерны (master–detail, Form_Current → requery).
- 2026-07-25…28: 0058 blocked до 0059→0061→0060→0063; продолжение только на `FemsqTable` из [fequlib](https://github.com/bondalen/fequlib).

## Выполненные фазы плана

| Фаза | Содержание | Итог |
|------|------------|------|
| A0 | Design chrome (Kimbie/VS Light, StatusBar connection/theme) | ✅ 2026-07-22 |
| A | IA-док + TopBar/ActiveView `construction-sites` + A.5 smoke | ✅ 2026-07-28 |
| B | GraphQL CRUD cst / cstAg / cstAgPn / Branch + lookups | ✅ smoke 5064 cst |
| C | Frontend master–detail, агенты L1–L3, C.5 тесты, C.6 by-code | ✅ |
| D | Отчёты + аренда (без chart/util/ra_change) | ✅ MVP; D.3/D.4 follow-up |
| E | Docs, modules.json, journal, UAT smoke | ✅ 2026-07-28 |

## UAT / smoke (nb-win, 2026-07-28)

| Проверка | Результат |
|----------|-----------|
| `npm run type-check` | OK |
| `npm run build` | OK (vite, 508 modules) |
| `ConstructionSitesView.spec.ts` | 4/4 passed |
| GraphQL `constructionSites` | 5064 строк |
| GraphQL `cstAgents(3321)` | «049 Газпромтранс, ООО» |
| Playwright UI | StatusBar «Подключено»; nav Org/Cst/Reports/Audits/Chains/Service; `construction-sites-view` (5064) + agents tree; by-code view; переключение экранов без регрессии |

## Ключевые артефакты

| Тип | Путь |
|-----|------|
| Views | `code/femsq-frontend-q/src/views/construction-sites/*` |
| Store / API | `stores/construction-sites.ts`, `api/construction-sites-api.ts` |
| Chrome | `TopBar.vue`, `StatusBar.vue`, `femsq-app-shell.css` |
| Tests | `tests/component/ConstructionSitesView.spec.ts` |
| Backend | `cst-schema.graphqls`, `CstGraphqlController` |
| Modules | `docs/project/extensions/modules/modules.json` (02.06.12–17, 02.08) |

## Вне scope / follow-up

| # | Тема |
|---|------|
| F1 | CRUD `ags.ra_change` (D.3) |
| F2 | Chart / `fnRRcListUtil` (D.4) |
| F3 | TreeList для дерева агентов (отдельный компонент, не FemsqTable) |
| F4 | feQuLib фазы D–G; задача 0062 (миграция JSON → docs-registry) — вне этой цепочки |
| F5 | Полный порт вкладок ipg/общее/освоение/графики формы `cst` |

## Итог

План **chat-plan-26-0722-forms-ia-cst** в пределах MVP выполнен: IA+chrome (0057), экраны строек GraphQL+Quasar (0058). Follow-up — F1–F5 выше.
