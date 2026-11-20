# Прод readonly-опрос R1.0 DEV-гейт (2026-11-19)

**Сессия:** `продОбмен/26-1119_09-30/`  
**Артефакты отПрод:** `09-51.zip` (шаг 00, лежал во `в_Прод`), `отПрод/10-04.zip` (01), `отПрод/10-10.zip` (02)  
**Формат:** SSMS Results to Text → `.txt` (UTF-8 BOM) — принят.

## 00 — M6 / объёмы

| Поле | Значение |
|------|----------|
| server / db | SPB-05-NV-SQL1 / FishEye |
| version | 11.0.7507.2 SP4 Standard |
| compatibility / collation | 100 / Cyrillic_General_CI_AS |
| m6-absent-expect | **все PASS** |
| objects | ags: cnInv*, cn_inv_dbt*, invDbt, invDbtTmpCiaRel, yr; **нет** Dbt/DbtValue/invDbtDbt |
| cnInvCmm | только cnicInvAccnt |
| counts | cia 13999, dbt 48234, upl 26 / max_key 34 / max_date 2026-04-21 |

## 01 — схема sudz

`sudz_schema = **ABSENT**` (объектов нет).

## 02 — ревизии

Все таблицы списка 0054 — **OK**; `ra_a` + `adt_staging_log_level` — TABLE_AND_COLUMN_EXIST; stg cols OK.

| ralpRa | ralpRaAu | ogAgFee | ogAgFeeP | ra_a |
|--------|----------|---------|----------|------|
| 15352 | 15375 | 1256 | 32898 | 9 |

## Вердикт

**PASS** опроса прода для 1.1: M6 нет, sudz нет, контур ревизий на месте.
