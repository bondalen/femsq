# Profile fill `#sudzEia` — 902 vs 910 (2026-09-02)

Скрипты: [`93_PROFILE_fill_902_vs_910.sql`](./93_PROFILE_fill_902_vs_910.sql), [`93b_PROFILE_fill_notexists.sql`](./93b_PROFILE_fill_notexists.sql).  
Среда: Docker `femsq-mssql`, БД `FishEye`, SQL Server 2022. Backend fill = `JdbcSudzDao.fillSudzEiaTemp` (CTE `existInvAll` + `invCand` / `invMatchRank`).

## Вердикт

**902 не медленнее 910.** На актуальном Java-SQL оба ~**150 с**.  
«~7 с на 910» из [`92_PROFILE_RESULTS_910.md`](./92_PROFILE_RESULTS_910.md) — это **другой** SQL (упрощённый join без ranking/`NOT EXISTS`), не текущий `fillSudzEiaTemp`.

## Кардинальность (почти идентична)

| Метрика | 902 | 910 |
|---------|-----|-----|
| Tbl | 1746 | 1764 |
| existInvGrouped | 1744 | 1754 |
| distinct cn | 256 | 265 |
| cnInv на matched cn | 80875 | 80933 |
| invCandRaw (match) | 1746 | 1756 |

Домен: `cnInv`≈92k, `invNum`≈92k, `invDbt`≈13k, `DbtValue`≈54k, PIT(801–803)≈5.7k.

## Стадии времени (sqlcmd)

| Стадия | 902 ms | 910 ms |
|--------|--------|--------|
| existInvGrouped → `#eig` | 2164 | 3287 |
| invCandRaw (join+LIKE, без pit) | 3491 | 3481 |
| + OUTER APPLY pitHist | 3501 | 3750 |
| **fill Java full** (`NOT EXISTS`+rank) | **149994** | **153676** |
| fill simple (как 92_PROFILE) | **82** | **86** |

## Узкое место (изоляция на 902)

| Вариант | ms | Примечание |
|---------|-----|------------|
| B1: invCand + pitApply, без CASE | 3581 | база |
| B2: + коррелированный `NOT EXISTS` в rank0 | **74388** | тот же rank histogram |
| B3: set-based `#hasExtPit` | **90** | всего **1** пара (cn, invNull) |
| B4: rank через `LEFT JOIN #hasExtPit` | 20673 | histogram = B2 |

`sqlInvNumRankCase` ветка rank=0 делает **на каждую** строку invCand коррелированный поиск «есть ли на том же cn расширенный `invNum` (`LIKE prefix + ' %'`) с PIT-историей». При ~80k cnInv на matched договорах это даёт минуты. Set-based `#hasExtPit` даёт тот же выбор победителя (rank0=1743 / rank1=1 / rank2=1 / rank3=1).

## Почему казалось «902 ×20 медленнее 910»

1. Baseline 910 (~6–7 с fill) — скрипт **92** / ранняя материализация **без** P4 ranking.
2. После появления `invMatchRank` + `NOT EXISTS` fill стал ~150 с **для любой** выгрузки похожего размера.
3. UI dry 902 `fillMs≈149482` согласуется с профилем; 910 сейчас такой же.

## Рекомендация (код, отдельно)

В `fillSudzEiaTemp` / `sqlInvNumRankCase`:

1. Один раз материализовать `#hasExtPit (cn_key, cidutCnInvNull)` (или PIT-флаги по `iKey` в `#pitByInv`).
2. Заменить коррелированный `NOT EXISTS` на `LEFT JOIN` / `NOT EXISTS` против temp.
3. Ожидание: fill порядка **секунд** (B1+B3), не ~150 с; семантика ranking сохраняется (проверено histogram B2=B4).

Повторный замер: `93_PROFILE_fill_902_vs_910.sql` после правки — смотреть `fill_java_full`.

## 2026-09-02 — fix в коде (0.1.0.261)

`JdbcSudzDao.fillSudzEiaTemp`: `#sudzEig` → `#pitByInv` → `#hasExtPit` → ranking/`#sudzEia` (set-based, без коррелированного `NOT EXISTS`).

UAT dry AccSmpl upl **902** (prefix org…AccSmpl, `flLoad=false`):

```
fillSudzEiaTemp unloadKey=902 rows=1,744 eigMs=2,450 pitMs=47 hepMs=62 eiaMs=3,722 totalMs=6,291
findDbtUpl… rows=0 fillMs=6,292 queryMs=51
```

Было fillMs≈**149 s** → стало ≈**6.3 s** (~**24×**). AccSmpl missing=0.
