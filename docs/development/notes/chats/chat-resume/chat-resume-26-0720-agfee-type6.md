# Резюме чата 26-0720: Type=6 AgFee2306 — reconcile Акты → Пункты

**Дата:** 2026-07-20 – 2026-07-21  
**Последнее обновление:** 2026-07-21  
**Тема:** Порт VBA/T-SQL сверки «Акты агентского вознаграждения» (`af_type=6`) в Java: Stage 2a FK, двухуровневый reconcile Акт→Пункты, tree-лог, UAT на `test_26`.  
**Задачи:** [0055](../../../project-development.json), [0056](../../../project-development.json) — **completed**  
**Журнал:** `chat-2026-07-20-001`  
**Машина:** nb-win (WSL2); JAR до `0.1.0.144-SNAPSHOT`

## Связанные документы

- [chat-plan-26-0720-agfee-type6.md](../chat-plan/chat-plan-26-0720-agfee-type6.md) — план (v1.0.0, выполнен)
- [ra-audit-file-processor-architecture.md](../../analysis/ra-audit-file-processor-architecture.md)
- [audit-log-vba-to-java-mapping.md](../../audit-log/audit-log-vba-to-java-mapping.md)
- SQL: `docs/development/notes/sql/26-0720/`, `26-0721/`
- Не путать с **0054** (prod bootstrap `ra_a`) — вне scope этого чата

## Контекст

- Домен `ags.ogAgFee` / `ags.ogAgFeeP` **уже на сервере** (не bootstrap как 0054).
- Нужен порт логики Access (`ra_aAgFee23_06` / views `ogAgFeePnTest*`) на `ra_stg_agfee` + `exec_key`.
- Ключевое требование: **сначала Акты, потом Пункты** (иначе нет `oafKey` для новых актов).

## Выполненные фазы плана

| Фаза | Содержание | Итог |
|------|------------|------|
| A | DDL/lookup/Excel инвентаризация | ✅ март 666 стр./~31 акт; июль 1987/~117 |
| B | Stage 2a AgentKey/CstKey + diagnostic | ✅ `oafptOafSenderKey` / `oafptPnCstAgPnKey` |
| C–D | Reconcile заголовок + пункты + год/сумма | ✅ `AgFee2306ReconcileService` |
| E | `Type6ReconcileTreeLogger` | ✅ дерево Акт→Пункты |
| F | Dry-run / seed марта / july apply / rollback | ✅ baseline **31/521** за 2026 |
| G | Docs + UAT UI | ✅ G.5 PASS (dry-run + B + C) |
| 0056 | Читаемость лога | ✅ диапазон Stage1, CstNo, русские подписи, суммы, «Этап» |

## UAT (оператор, nb-win)

| Шаг | Exec / факт |
|-----|-------------|
| Dry-run март | 1207–1208: WARN пустых=0, диапазон 2–666, суммы с разрядами |
| **B** apply март | 1209: NEW=0, домен 31/521 |
| **C** july dry-run → apply | 1210–1211: домен **86/1550**, Δ=0 |
| Rollback | скрипт → снова **31/521**, снимок `2026_03`, `adt_AddRA=false` |

Доработки лога по замечаниям UAT: свёртки Agent/Cst; `+`/`−` вместо «СОБЫТИЕ»; агент из `ogs.ogAgCs` («051 Газпром инвест, ООО»); критерий значимой Excel-строки (№ Акта + стройка/дата) против хвоста UsedRange.

## Ключевые артефакты

| Тип | Путь |
|-----|------|
| Reconcile | `.../reconcile/AgFee2306ReconcileService.java`, `Type6ReconcileTreeLogger.java` |
| Stage 2a | `.../stage2/AgFeeStage2Service.java`, `AgFeeFkAnomalyFormatter.java` |
| Stage 1 | `DefaultAuditStagingService` + `AgFeeDataRangeClassifier` |
| Деньги в логе | `AuditMoneyFormat.java` |
| Скрипты | `audit-switch-agfee-snapshot.sh`, `rollback-agfee-to-march-baseline.sh`, `femsq-sql.js` |
| DDL | Liquibase `2026-07-20` FK keys, `2026-07-21` `oafptRow`; пакеты `sql/26-0720`, `26-0721` |

## Вне scope (остаётся)

| # | Тема |
|---|------|
| П1 / В6 | Заполнение `AuditExecutionContext.year` при старте ревизии |
| П2 | Вернуть `af_execute` type=3/5 на `dir=15` при смешанном `test_26` |
| П3 | **0054** prod bootstrap таблиц ревизий |
| П4 | Выкат DDL Stage2a/`oafptRow` на prod (MSSQL2012) |

## Итог

План **chat-plan-26-0720-agfee-type6** выполнен полностью в пределах заявленных целей и UAT. Type=6 готов к эксплуатации на abs; prod-деплой DDL — по окну (П4) и после/параллельно с 0054 для контура `ra_a`.
