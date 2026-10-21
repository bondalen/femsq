# Чеклист дня деплоя: СУДЗ invDbt cutover (+ контур B)

**Связанный порядок работ:** [`db-upgrade-sudz-invdbt-cutover.md`](db-upgrade-sudz-invdbt-cutover.md) §1.3.1  
**Walk-back cmm на `*Dv`:** [`db-upgrade-cmm-dv-walkback.md`](db-upgrade-cmm-dv-walkback.md)  
**Политика Access ↔ FEMSQ:** [`sudz-access-femsq-write-policy.md`](sudz-access-femsq-write-policy.md)  
**Smoke исходящих:** [`sudz-outgoing-d644-smoke.md`](sudz-outgoing-d644-smoke.md)  
**Краткий отчёт (UAT-эталон):** [`../development/notes/domain/sudz/03-1_brief-report-pre-load.md`](../development/notes/domain/sudz/03-1_brief-report-pre-load.md) §7  
**Контур B / WBS:** [`../development/notes/chats/chat-plan/chat-plan-26-0918-sudz-rslt-prod-mailing.md`](../development/notes/chats/chat-plan/chat-plan-26-0918-sudz-rslt-prod-mailing.md)  

**Дата создания:** 2026-08-27  
**lastUpdated:** 2026-10-21  
**Статус:** прогон готовности DEV 2026-10-21 (WBS **1.1.2.3**). Окно H не открывалось. Smoke на prod пустой.

**Сервер:** `prod-fisheye` (`SPB-05-NV-SQL1` / FishEye / `ags`)  
**Пакет на носителе:** `…/MSSQL2012/` *(путь TBD)*  
**Исполнитель:** Александр · инструмент: SSMS · auth: Windows

---

## До окна

### Cutover (слой invDbt)

- [ ] Фаза A: survey prod выполнен, `SURVEY_RESULT.md` сверен в Cursor — файла в репозитории нет (2026-10-21)
- [x] N_slots_plan зафиксирован (ожид. ~11907) — cutover §1; пересчёт на prod остаётся фазой A
- [x] Решение E0/E1/E2 по Value (**E1** + **E1′ PIT** для Rslt) — cutover §E / §E1′, 2026-08-27 / 2026-08-31
- [x] **R3:** решение Access write после cutover зафиксировано в [политике](sudz-access-femsq-write-policy.md) §3 — 2026-10-21, запрета нет, выбор у оператора
- [x] DEV: dry seed + UAT calm F1 + экран — M3 JAR 0.1.0.225, M4 JAR 0.1.0.226 (cutover §F / §M4)
- [x] DEV: Rslt stage1 gate — `verify_rslt_stage1.py` exit 0 (база–QI–QII; QIII/QIV в эталоне игнор) — README пакета `26-0831`, JAR ≥ 0.1.0.240. Повтор скрипта в этом прогоне не запускался
- [ ] L001–L010 + Apply в пакете cutover — seed есть в `26-0831/02_SEED_L001_L010.sql` (синтаксис DEV). Каталог `26-0807-sudz-target-schema/MSSQL2012/` для схемы `ags` пуст
- [ ] Backup FishEye согласован / выполнен
- [ ] JAR собран, версия записана: ________ — в бланк дня пишется сборка окна. На DEV сейчас `0.1.0.372-SNAPSHOT` (`code/pom.xml`)

### Контур B — готовность пакетов / продукта (без GO на prod до зелёного DEV)

- [ ] Опись `MSSQL2012/` включает нужные пакеты (в т.ч. `26-0918-sudz-brief-report-fio-dict/MSSQL2012/` при выкладке словаря и `26-1016-cmm-dv-prod/MSSQL2012/` для текста cmm) — словарь и `*Dv` на диске есть; пакет cutover в `ags` пуст, поэтому опись релиза не закрыта. Состав — в прогоне ниже
- [x] DEV: контур **b** закрыт по канону 0076 (pm / `g_p` / стройки), не только бэкфилл S80 — план 0918 **0.3.51**, листья **1.1.1.2.1–.8**
- [x] DEV: краткий отчёт `.3.2–.5` зелёный **или** осознанный перенос на следующий релиз (тогда smoke §«Краткий отчёт» ниже — N/A) — UAT **1.1.1.0.3.5** 2026-10-21
- [x] Регламент исходящих прочитан: [sudz-outgoing-d644-smoke.md](sudz-outgoing-d644-smoke.md) — 2026-10-21. Прогон на prod по-прежнему после окна H и вехи 1.1.3

---

## Прогон готовности DEV (2026-10-21)

Сервер `prod-fisheye` не открывался. Разделы «В окне», «После окна» и «Откат» не заполнялись.

Пакеты `MSSQL2012/`, которые уже лежат в репозитории и входят в контур B:

| Пакет | Зачем на окне |
|-------|----------------|
| `26-0918-sudz-brief-report-fio-dict/MSSQL2012/` | словарь FIO, `ags.fioDict` |
| `26-1016-cmm-dv-prod/MSSQL2012/` | walk-back текста cmm на `*Dv`; скрипты квалифицируют схему `sudz`, на `ags` без колонок `*Dv` DML не запускать |
| `26-0921-sudz-dbt-upl-cst-ag-exp/MSSQL2012/` `12`–`14` | процедура **14g** и backfill основания документа; apply после M6, рядом с **1.1.2** |

Дыры, которые держат окно H:

1. Фаза A: нет `SURVEY_RESULT.md`, N слотов на prod не пересчитан.
2. Бэкап FishEye не согласован.
3. Пакет cutover в схему `ags` (`26-0807-sudz-target-schema/MSSQL2012/`) пуст; L001–L010 туда не перенесены.
4. Версия JAR дня деплоя не назначена.

R3 закрыт 2026-10-21: запрета Access нет, инструмент шага выбирает оператор.

---

## В окне

### Cutover

- [ ] `00_VERIFY_before` — PASS
- [ ] DDL C — PASS (в том числе колонки `*Dv`, если этот релиз их добавляет)
- [ ] **D5a / §1.3.1:** бэкап → `00_VERIFY_before` (`gate OK`) → `01_DRYCHECK` → `02_MIGRATE` → `03_VERIFY_after` по [walk-back](db-upgrade-cmm-dv-walkback.md). Если `00` отказывает (на `ags` нет `cnicDv`) — `02` не запускать
- [ ] Seed D — rowcount = N_slots_plan
- [ ] Seed E (E1) — VERIFY; **не** last-asOf-any для исторических срезов Rslt
- [ ] L* Apply — PASS
- [ ] `04_VERIFY_after` — PASS
- [ ] Выкладка JAR
- [ ] Seed/DDL словаря FIO (`ags.fioDict`), если в составе релиза — VERIFY rowcount 211 / words ~460
- [ ] Smoke: лаунчер / calm / очередь / одна операция экрана
- [ ] Smoke Rslt: row1 Ttl/Overd/погашено vs эталон (объём доступных кварталов)

### Контур B — smoke на prod (после успешного cutover+JAR)

Порядок продуктовый: **0 → a → b → c → d**. Пункты с пометкой *если в релизе*.

#### 0) Краткий отчёт (БП 1.1.1.0) — *если `.3.*` в релизе*

- [ ] Путь к своду QI/актуального квартала → «Подготовить»
- [ ] Файл `…_краткий_отчёт.xlsx` рядом со сводом
- [ ] Мини-сверка по [03-1 §7](../development/notes/domain/sudz/03-1_brief-report-pre-load.md): порядок СГК, ВСЕГО H (±допуск), 2–3 ФИО→инициалы, нет `Отказ:` в C  
  *(полный U1–U15 — на DEV; на prod — дымовой набор)*

#### a) Свод

- [ ] Dry/smoke воронки свода (лаунчер C) без Cursor на критичном пути

#### b) Стройки / pm

- [ ] Наличие/доступ `export_*` периода; dry Excel→Tbl (без полного apply, если окно короткое — по решению владельца)
- [ ] После полного канона на DEV: smoke apply/`g_p` по регламенту 0819

#### c) Rslt + веха

- [ ] Rslt сбор · Выгрузить (после gate погашений, когда S79 готов)
- [ ] При наличии возврата: · Загрузить → New (не обязательно в том же окне H)

#### d) Исходящие

- [ ] По [sudz-outgoing-d644-smoke.md](sudz-outgoing-d644-smoke.md) §2–§3: **D644 · Выгрузить** + запись прогона  
- [ ] **Свод · Выгрузить** — если Q4 или тех. smoke (§4 того же дока)

---

## После окна

- [ ] Запись в журнал проекта (cutover + результаты smoke B)
- [ ] Обновить 04-4 / cutover-док фактическими числами prod
- [ ] Статус R3 в cutover → ✅ с датой политики
- [ ] План снятия dual-read (фаза I)
- [ ] Бэклог фазы J (`Dbt`), если актуален
- [ ] Заполнить бланки прогона D644/Свод в [sudz-outgoing-d644-smoke.md](sudz-outgoing-d644-smoke.md)

---

## Откат

- [ ] Критерий отката согласован заранее
- [ ] `05_ROLLBACK` / restore backup — только по решению владельца
- [ ] Откат walk-back `*Dv` — restore бэкапа, снятого до `02`; `04_ROLLBACK.sql` пакета `26-1016` строки не чистит
- [ ] Access write: не «возвращать запись Access» без явного отзыва политики R3
