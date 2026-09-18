# Чеклист дня деплоя: СУДЗ invDbt cutover (+ контур B)

**Связанный порядок работ:** [`db-upgrade-sudz-invdbt-cutover.md`](db-upgrade-sudz-invdbt-cutover.md)  
**Политика Access ↔ FEMSQ:** [`sudz-access-femsq-write-policy.md`](sudz-access-femsq-write-policy.md)  
**Smoke исходящих:** [`sudz-outgoing-d644-smoke.md`](sudz-outgoing-d644-smoke.md)  
**Краткий отчёт (UAT-эталон):** [`../development/notes/domain/sudz/03-1_brief-report-pre-load.md`](../development/notes/domain/sudz/03-1_brief-report-pre-load.md) §7  
**Контур B / WBS:** [`../development/notes/chats/chat-plan/chat-plan-26-0918-sudz-rslt-prod-mailing.md`](../development/notes/chats/chat-plan/chat-plan-26-0918-sudz-rslt-prod-mailing.md)  

**Дата создания:** 2026-08-27  
**lastUpdated:** 2026-09-18  
**Статус:** заготовка — заполняется после фаз A–G; gate Rslt (E1′) есть; добавлены smoke контура B (дока)

**Сервер:** `prod-fisheye` (`SPB-05-NV-SQL1` / FishEye / `ags`)  
**Пакет на носителе:** `…/MSSQL2012/` *(путь TBD)*  
**Исполнитель:** Александр · инструмент: SSMS · auth: Windows

---

## До окна

### Cutover (слой invDbt)

- [ ] Фаза A: survey prod выполнен, `SURVEY_RESULT.md` сверен в Cursor
- [ ] N_slots_plan зафиксирован (ожид. ~11907)
- [ ] Решение E0/E1/E2 по Value (**E1** + **E1′ PIT** для Rslt)
- [ ] **R3:** решение Access write после cutover зафиксировано в [политике](sudz-access-femsq-write-policy.md) §3
- [ ] DEV: dry seed + UAT calm F1 + экран
- [ ] DEV: Rslt stage1 gate — `verify_rslt_stage1.py` exit 0 (база–QI–QII; QIII/QIV в эталоне игнор)
- [ ] L001–L010 + Apply в пакете cutover
- [ ] Backup FishEye согласован / выполнен
- [ ] JAR собран, версия записана: ________

### Контур B — готовность пакетов / продукта (без GO на prod до зелёного DEV)

- [ ] Опись `MSSQL2012/` включает нужные пакеты (в т.ч. `26-0918-sudz-brief-report-fio-dict/MSSQL2012/` при выкладке словаря)
- [ ] DEV: контур **b** закрыт по канону 0076 (pm / `g_p` / стройки), не только бэкфилл S80
- [ ] DEV: краткий отчёт `.3.2–.5` зелёный **или** осознанный перенос на следующий релиз (тогда smoke §«Краткий отчёт» ниже — N/A)
- [ ] Регламент исходящих прочитан: [sudz-outgoing-d644-smoke.md](sudz-outgoing-d644-smoke.md)

---

## В окне

### Cutover

- [ ] `00_VERIFY_before` — PASS
- [ ] DDL C — PASS
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
- [ ] Access write: не «возвращать запись Access» без явного отзыва политики R3
