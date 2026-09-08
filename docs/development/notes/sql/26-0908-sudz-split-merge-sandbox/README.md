# Песочница «разделение и слияние долгов» — `test_sudz_sm`

**Дата создания:** 2026-09-08  
**lastUpdated:** 2026-09-08  
**Контур:** только DEV/FishEye. Не переносить в `MSSQL2012/` и не писать в `sudz.*` / `test_sudz` (82/85).  
**Канон полос Rslt:** листы **A_111_curr202** и **C_111_curr210** ([08](./08_CMM_AND_RSLT.md) §3). B / timeline / 112 — справка.  
**Живой якорь не split:** `iKey=85166`, КСДД 2807/2808 @901 (2×18 000, `reason=multi`). На текущем `sudz` форму A не собрать.

## Зачем отдельная схема

`test_sudz` занята эталоном Rslt 82/85. Здесь — изолированные словари (не `ags`), чтобы крутить split/merge, в том числе **снимая** UNIQUE/триггеры, которые на живом `sudz` трогать рано.

## Карта 10 × 10

| `dbtKey` | Роль | Срезы 201–210 |
|----------|------|----------------|
| **111** | split (модель 311 / 322 / 323) | strict: 36 000 на слоте 311; после `05`: 201=36 000, 202–209=2×18 000; после `12`: 210 снова 36 000@311 |
| **112** | merge-A | 10 000 на inv 301 |
| **113** | merge-B | 20 000 на inv 302; `06` переписывает мост → 112 |
| **114** | 1:1 | 5000 |
| **115** | уменьшение (контраст «погашено») | 10000…1000 |
| **116** | L* / P1 | 4000, чётные upl на inv 317, нечётные на 316 |
| **117–120** | 1:1 | 700 / 800 / 900 / 1000 |

Выгрузки: `test_sudz_sm.upl` **201–210** (не пересекаются с 901–903).

## Скрипты (порядок)

| # | Файл | Действие |
|---|------|----------|
| 0 | `00_CREATE_SCHEMA.sql` | схема |
| 1 | `01_CREATE_TABLES.sql` | DROP+CREATE, режим **strict** (S16 + Consistency п.4–5) |
| 2 | `02_SEED_BASE.sql` | 10×10 |
| 3 | `03_PROBE_STRICT.sql` | ожидаемые отказы |
| 4 | `04_RELAX.sql` | снять UX(inv,dbt) и п.4–5 |
| 5 | `05_SPLIT_111.sql` | модель владельца на 111 |
| 6 | `06_MERGE_112_113.sql` | канон 113→112 (разные inv — проходит и в strict) |
| 7 | `07_STATUS.sql` | сводка `lab_event` / суммы |
| 9 | `09_CREATE_CMM.sql` | таблицы cmm / cnInvGr на `dvKey` |
| 10 | `10_SEED_CMM.sql` | комментарии 201/202 (111) и 201 (112) |
| 12 | `12_MERGEBACK_111.sql` | 210 снова 36 000@311; cmm 209 (две доли) и 210 (целый) |
| 11 | `11_RSLT_SKETCH.sql` | макет полос A/B/C (консоль) |
| — | `apply_sm.py` | `--cmm` / `--xlsx` → `SKETCH.md` + `ags_Yr_DbtChangesRslt_sm_sandbox.xlsx` |

Повтор с нуля: снова `01` (сносит таблицы) → `02`…

## Режимы

- **strict** — как живой `sudz`: нельзя два слота одного `Dbt` на одном `inv`; нельзя две Value одного `Dbt` на одной upl; нельзя sibling с одинаковым `dvTtl`.
- **relaxed** — только для этой схемы; позволяет split на одном СФ.

## Наблюдения, которые лаборатория должна показать

1. Split «как в чате» в **strict** не встаёт.  
2. 2×18 000 на sibling бьёт п.4 даже без общего `Dbt`.  
3. Merge через `UPDATE invDbtDbt.iddDbt` на **разных** СФ в strict **проходит**; история Value не переписывается — у канона на срезе оказывается **две** строки величины. Триггер п.5 на UPDATE моста **не срабатывает**.  
4. После relax split 111 даёт ∑=36 000 на 202–209 при двух Value; `12` возвращает 210 к одной Value 36 000.  
5. cmm и cnInvGr на `dvKey`: зерно комментариев = зерно Value среза группы, не крайней полосы фактов.

Применение:

```bash
python3 /home/alex/projects/java/spring/vue/femsq/docs/development/notes/sql/26-0908-sudz-split-merge-sandbox/apply_sm.py
python3 /home/alex/projects/java/spring/vue/femsq/docs/development/notes/sql/26-0908-sudz-split-merge-sandbox/apply_sm.py --cmm
python3 /home/alex/projects/java/spring/vue/femsq/docs/development/notes/sql/26-0908-sudz-split-merge-sandbox/apply_sm.py --xlsx
```

`--cmm` — комментарии + merge-back 210 + `SKETCH.md` + Excel. `--xlsx` / `--report` — пересобрать макеты без повторного seed.

Excel: [ags_Yr_DbtChangesRslt_sm_sandbox.xlsx](./ags_Yr_DbtChangesRslt_sm_sandbox.xlsx) — канон **A** и **C**; остальные листы справочные. Это макет песочницы, не прод-экспорт `SudzRsltExcelExporter`.

Канон зерна и запреты на живой `sudz`: [08_CMM_AND_RSLT.md](./08_CMM_AND_RSLT.md).
