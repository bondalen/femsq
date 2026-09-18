# Резюме чата 26-0918: CnInvPmtUpl H3 apply (0076)

**Дата:** 2026-09-18  
**Тема:** Закрытие H3 — apply-шаги воронки платежей `cipu*` → домен при `flLoad` (экран D).  
**Задачи:** [0076](../../../project-development.json) (канон 1.1.1.2 / §4.3 плана 0819)  
**Машина:** asus-kubuntu; FishEye `10.7.0.3`; JAR **0.1.0.297**  
**Handoff для продолжения:** [2026-09-18_1641_…-h3-continue.md](../2026-09-18_1641_asus-kubuntu_cn-inv-pmt-upl-h3-continue.md)  
**План:** [chat-plan-26-0819 §4.3](../chat-plan/chat-plan-26-0819-cn-inv-pmt-upl.md)

## Итог

На **pm=8** (`export_767502`) выполнены и проверены через UI Cursor dry→apply→dry:

| Шаг | Id | Apply |
|-----|-----|-------|
| 3 | `cipuCn_CtptCnNotLoad` | ✅ |
| 5 | `cipuCn_AgNotLoad` | ✅ |
| 7 | `cipuCn_CtptCnOneInvNotLoad` | ✅ |
| 9 | `cipuCn_CtptCnOneInvOneAcNotLoad` | ✅ |
| 10 | `cipuDocNotLoad` → `cn_inv_doc` | ✅ 127 |
| 12 | `cipuInsPmNotLoad` → `cn_inv_pm` | ✅ 303 |

H2 log-only и Excel→Tbl на 5 пакетах были закрыты ранее в той же ветке работы.

## Следующий чат

**H4** — apply на pm 3/4/5/6; затем **H5** `g_p`→902; **H6–H7** стройки/Rslt.
