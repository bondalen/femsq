# Чеклист дня деплоя: СУДЗ invDbt cutover

**Связанный порядок работ:** [`db-upgrade-sudz-invdbt-cutover.md`](db-upgrade-sudz-invdbt-cutover.md)  
**Дата создания:** 2026-08-27  
**Статус:** заготовка — заполняется после фаз A–G

**Сервер:** `prod-fisheye` (`SPB-05-NV-SQL1` / FishEye / `ags`)  
**Пакет на носителе:** `…/MSSQL2012/` *(путь TBD)*  
**Исполнитель:** Александр · инструмент: SSMS · auth: Windows

---

## До окна

- [ ] Фаза A: survey prod выполнен, `SURVEY_RESULT.md` сверен в Cursor
- [ ] N_slots_plan зафиксирован (ожид. ~11907)
- [ ] Решение E0/E1/E2 по Value
- [ ] Решение Access write после cutover
- [ ] DEV: dry seed + UAT calm F1 + экран
- [ ] Backup FishEye согласован / выполнен
- [ ] JAR собран, версия записана: ________

## В окне

- [ ] `00_VERIFY_before` — PASS
- [ ] DDL C — PASS
- [ ] Seed D — rowcount = N_slots_plan
- [ ] Seed E (если да) — VERIFY
- [ ] `04_VERIFY_after` — PASS
- [ ] Выкладка JAR
- [ ] Smoke: лаунчер / calm / очередь / одна операция экрана

## После окна

- [ ] Запись в журнал проекта
- [ ] Обновить 04-4 / cutover-док фактическими числами prod
- [ ] План снятия dual-read (фаза I)
- [ ] Бэклог фазы J (`Dbt`)

## Откат

- [ ] Критерий отката согласован заранее
- [ ] `05_ROLLBACK` / restore backup — только по решению владельца
