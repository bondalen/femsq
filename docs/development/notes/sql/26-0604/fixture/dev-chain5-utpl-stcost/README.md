# Dev fixture: разбивка UtPlMn по stCost (цепь 5)

**Только dev Docker.** Не включать в `MSSQL2012/` и на флеш-носитель.

См. [`../../docs/13-plan-stcost-monthly-acceptance.md`](../../docs/13-plan-stcost-monthly-acceptance.md).

## Применение

```bash
cd docs/development/notes/sql/26-0604/fixture/dev-chain5-utpl-stcost
chmod +x apply_fixture_chain5.sh
./apply_fixture_chain5.sh
```

Порядок: `00` → `01` (нормализация 6 пн) → `03` (split) → `04` (verify).

## FIXTURE_06 (golden cst 2102)

```bash
cd docs/development/notes/sql/26-0604/fixture/dev-chain5-utpl-stcost
chmod +x apply_fixture_06.sh
SQL_HOST=10.7.0.3 ./apply_fixture_06.sh   # Fedora → nb-win Docker
```

Порядок: `06_00` (журнал + ipgUtPlGr 18–20) → `06_01` (swap ipgcrvUtPlGr) → `06_golden` → `06_verify`.

Откат: `FIXTURE_06_99_rollback.sql`. Журнал: `ags._fixture_utpl06_log`.

Приёмка 17 дат (после FIXTURE_06):

```bash
cd docs/development/notes/sql/26-0604
SQL_HOST=10.7.0.3 ./run_07o_cst2102_17dates.sh
```

## Откат (FIXTURE_01–05)

```bash
docker exec -i femsq-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '***' -d FishEye -C \
  -i FIXTURE_99_rollback.sql
```

Журнал: `ags._fixture_utpl_stcost_log`.

## Скрипты

| Файл | Назначение | Статус |
|------|------------|--------|
| `FIXTURE_00_setup_journal.sql` | таблица журнала | ✅ |
| `FIXTURE_01_normalize_utplmn.sql` | sum(UtPlMn@212) → ipgpSmTtl | ✅ |
| `FIXTURE_03_split_stcost.sql` | 212 → 195/172/187 по ipgPnLim | ✅ |
| `FIXTURE_04_verify_data.sql` | инварианты данных | ✅ |
| `FIXTURE_99_rollback.sql` | откат INSERT + NORMALIZE | ✅ |
| `FIXTURE_05_pilot_cst_2102.sql` | пилот cst 2102 (заменён golden 06) | ✅ |
| `FIXTURE_06_00` … `FIXTURE_06_99` | изолированные группы 18–20, golden 2102 | ✅ **2026-06-24** |
| `apply_fixture_06.sh` | оркестратор FIXTURE_06 (`SQL_HOST` на Fedora) | ✅ |
| `07o_plan_17dates_cst_chain5.sql` | 17 дат, К-12…К-17, cst 2102 | ✅ **2026-06-24** |
| `run_07o_cst2102_17dates.sh` | прогон 07o | ✅ |
