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

## Откат

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
| `apply_fixture_chain5.sh` | оркестратор | ✅ |
