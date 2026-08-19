# Резюме чата 26-0819: экран D «Загрузка платежей» (visual v1)

**Дата:** 2026-08-19  
**Последнее обновление:** 2026-08-19  
**Тема:** Visual v1 экрана FEMSQ **D** «Загрузка платежей» (`sudz-pmt-upl`, процесс 1.1.1.2). Аналог UI экрана C (`SudzDbtUplView`) без пресетов воронки, без Excel и без записи платежей в домен.  
**Задачи:** [0072](../../../project-development.json) — **completed**  
**Журнал:** `chat-2026-08-19-001` (completed)  
**Машина:** nb-win (WSL2); DBHub OK; `femsq-mssql` Up; Vite `:5175` + JAR `0.1.0.198` на `:8080` для осмотра

**Не смешивать:** воронка долгов **0069** / `CnInvDbtUpl`; вкладка **«выгрузки платежей»** на экране свода (`g_p`, 1 дбт → N pmt); карта домена [0802](../chat-plan/chat-plan-26-0802-sudz.md) как рабочий план UI; КСДСФ.

## Связанные документы

- [chat-plan-26-0819-cn-inv-pmt-upl.md](../chat-plan/chat-plan-26-0819-cn-inv-pmt-upl.md) — рабочий план экрана D
- [02-9 §4b](../../UI/02-9_sudz-mvp-screens.md#4b-экран-d--загрузка-платежей-cn_inv_pm_upl--лаунчер-file_f) — эскиз
- [02-4](../../UI/02-4_app-forms-ia.md) — TopBar СУДЗ → Загрузка платежей
- [02-11](../../UI/02-11_cn-inv-pmt-upl-access.md) — паспорт Access (S69, закрыт ранее)
- [chat-plan-26-0802-sudz.md](../chat-plan/chat-plan-26-0802-sudz.md) §5.8 — указатель S70 (не наращивать UI pmt там)
- [chat-resume-26-0817-cn-inv-pmt-upl.md](./chat-resume-26-0817-cn-inv-pmt-upl.md) — съём Access, не этот чат

## Контекст

Паспорт Access 1.1.1.2 закрыт (S69). Согласован visual analog экрана «Загрузка свода»: список всех `cn_inv_pm_upl`, вкладка «загрузка» с 13 чекбоксами `cipu*` (префикс, без пресетов), нижние каркасы. Воронка `btnUpload` / Excel / apply — вне 0072.

## Выполненные фазы плана

| Фаза | Содержание | Итог |
|------|------------|------|
| 0 | План 26-0819, задача 0072, IA, эскиз 02-9 §4b, указатель S70 | ✅ (док. чат до кода) |
| 1 | Экран D v1: TopBar, view/store, lookup, шаги, нижние вкладки, stub «загрузка» | ✅ 2026-08-19 |
| UAT | Владелец: экран в целом соответствует плану | ✅ 2026-08-19 |

## UAT / smoke (nb-win, 2026-08-19)

| Проверка | Результат |
|----------|-----------|
| TopBar **СУДЗ → Загрузка платежей** | ✅ |
| Список дата / имя / `pm_key`, выбор строки | ✅ |
| Вкладка «загрузка»: путь, `cipufSheet`, два флага, stub, 13 шагов без пресетов; шаг 6 — «агент более одного раза» | ✅ |
| «счета, сумма» disabled | ✅ |
| Низ: ход (пусто) / повторяющиеся СФ / стройки новые | ✅ |
| Экран C: вкладка «выгрузки платежей» не удалена | ✅ `aria-disabled=true` |
| Unit `pmt-upl-funnel-steps.spec.ts` | 3/3 passed |

## Ключевые артефакты

| Тип | Путь |
|-----|------|
| View | `code/femsq-frontend-q/src/views/sudz/SudzPmtUplView.vue` |
| Store | `code/femsq-frontend-q/src/stores/sudz-pmt-upl.ts` |
| Шаги | `code/femsq-frontend-q/src/sudz/pmt-upl-funnel-steps.ts` |
| Тест | `code/femsq-frontend-q/tests/unit/pmt-upl-funnel-steps.spec.ts` |
| Nav | `TopBar.vue`, `ActiveView` `sudz-pmt-upl` |
| Список GraphQL | уже было: `sudzPmUplLookups`, `createSudzPmUpl` |

## Наблюдения осмотра (в следующий чат, не 0072)

| Тема | Факт |
|------|------|
| Схема списка | `sudzPmUplLookups` читает `sudz.cn_inv_pm_upl` (на DEV было 0 строк). В `ags.cn_inv_pm_upl` — 45. Для осмотра создана строка `pm_key=1` «visual-v1 осмотр». |
| Подписи шагов | Средний сплиттер по умолчанию обрезает подписи; опустить разделитель. |
| Vite boot | Статический импорт `ContractsView` / `SudzSfDoubleView` падал: в checkout feQuLib нет `FemsqTree`. В `App.vue` эти экраны — `defineAsyncComponent` (экран D грузится). |
| File / лог | Путь, лист, флаги — только UI; в `CnInvPmtUplFile` не пишутся. |

## Вне scope / follow-up

| # | Тема |
|---|------|
| F1 | Лаунчер File: `cipufPath` / `cipufSheet` / флаги / лог из БД (следующий чат; ещё не воронка) |
| F2 | Excel→Tbl и оркестратор `cipu*` по шагам |
| F3 | Вкладка `g_p` на экране C; переход C→D по `pmKey` |
| F4 | Адаптер КСДСФ под pmt |
| F5 | Живые InvDouble / CstNew / Sum_t |
| F6 | Коммит `export_*.xlsx` — не делать |

## Итог

Задача **0072** закрыта: visual v1 экрана D принят владельцем. Следующий чат — **F1** (шапка File), не вся воронка и не 0802.
