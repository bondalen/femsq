# Резюме чата 26-0919: CnInvPmtUpl H4 apply (0076)

**Дата:** 2026-09-19  
**Тема:** H4 — apply воронки платежей на всех 5 пакетах `export_*` → `cn_inv_pm`.  
**Задачи:** [0076](../../../project-development.json)  
**Машина:** nb-win (WSL2); FishEye Docker `localhost:1433`; JAR **0.1.0.300**  
**План:** [chat-plan-26-0819 §4.3](../chat-plan/chat-plan-26-0819-cn-inv-pmt-upl.md)

## Итог

UAT через UI браузера Cursor (`http://172.17.34.15:8080/`), префикс до `cipuInsPmNotLoad`, `flTbl=0`.

| pm | export | dry Doc / InsPm (до) | apply InsPm (и др.) | dry после |
|----|--------|----------------------|---------------------|-----------|
| 8 | 767502 | (H3 2026-09-18) | ✅ 303 | ✅ 0 |
| 3 | 606012 | 2656 / 1113 | InsPm **3769** left=0 (~11 мин) | ✅ пусто |
| 4 | 606022 | 136 / 264 | Doc **136**; InsPm **400** left=0 | ✅ пусто |
| 5 | 761010 | 101 / 497 | Doc **101**; InsPm **598** left=0 | ✅ пусто |
| 6 | 767501 | 3193 / 446 (+ Ag2, Inv/Ac 1982) | Doc **3193**; InsPm **5302** left=0 (~20 мин) | ✅ пусто |

**Код:** `JdbcSudzDao` — `setQueryTimeout` InsPm select **300** с, insert **600** с (иначе timeout на больших Tbl).

## Следующий срез

**H5** — `g_p` ↔ dbt **902**; затем H6–H7.
