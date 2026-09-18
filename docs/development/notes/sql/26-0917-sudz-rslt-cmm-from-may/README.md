# Пакет: группа комментариев по зелёным полям Rslt сбор asOf903

**Создан:** 2026-09-17  
**lastUpdated:** 2026-09-17  
**Схема:** `sudz` (DEV)  
**Источник:** `/home/alex/Downloads/продОбмен/26-0917_09-41/в_Прод/ags_Yr_DbtChangesRslt_26-0917_cmm_from_may.xlsx` (не в git).

## Что делает

Создаёт **новую** `cnInvCmmGr` (не MERGE в 903) и пишет:

| Excel (зелёные) | Таблица | Тип |
|-----------------|---------|-----|
| Куратор | `cnInvCmm` | 8 |
| Мероприятия | `cnInvCmm` | 1 |
| Код стройки | `cnInvCmmCst` | 2 → `ags.cstAgPn` |
| Наименование | не хранится текстом | из `cst` по коду |

Ключ строки: `dbtKey` (колонка A). Split A45 (2×18000) — один канон.

Затем `sudz.yr.yr_CmmGr` для **yr=901** указывает на новую группу. Группа **903** (S81 Access) остаётся в БД.

## Результат DEV (2026-09-17)

| | |
|--|--|
| Группа | **905** `S82cmm` |
| yr=901 | `yr_CmmGr=905`, `yr_CmmGr_New=904` |
| Куратор (тип 8) | 131 |
| Мероприятия (тип 1) | 180 |
| Код стройки (тип 2) | 1815, unresolved 0 |
| 903 | не тронута (53+53 cmm, 1777 cst) |

## Экспорт Rslt сбор asOf903 (2026-09-17)

`GET /api/v1/sudz/rslt-sborn.xlsx?yr=901&asOfUpl=903` (JAR 0.1.0.285, `yr_CmmGr=905`).

Файл: [`artifacts/ags_Yr_DbtChangesRslt_901_asOf903_s82cmm_905_26-0917.xlsx`](artifacts/ags_Yr_DbtChangesRslt_901_asOf903_s82cmm_905_26-0917.xlsx)

Сверка с MAY-рассылкой (`…cmm_from_may.xlsx`), ключ `dbtKey` (2134/2134):

| Поле | Результат |
|------|-----------|
| Куратор | 131 = 131, CHANGE 0 |
| Мероприятия | 180 = 180, CHANGE 0 |
| Код стройки | 1815 = 1815, CHANGE 0 |
| Наименование | 1805 same + 10 орфография `ags.cst` vs Excel MAY |
| `*_new` | пустые |

```bash
node 04_COMPARE_GREEN_VS_MAY_MAILING.mjs
```

## Импорт MAY красных в группу 906 (UI, 2026-09-17)

Rslt-файл с `*_new` из красных MAY (QIV Overd, спецпары A45/86740/732):  
[`artifacts/ags_Yr_DbtChangesRslt_901_asOf903_may_red_return_26-0917.xlsx`](artifacts/ags_Yr_DbtChangesRslt_901_asOf903_may_red_return_26-0917.xlsx)

На Progress: **Rslt повтор · Загрузить** → **Создать** группу → POST `/api/v1/sudz/rslt-return?yr=901`.

| | |
|--|--|
| Группа новых | **906** (`yr_CmmGr_New`), `yr_CmmGr` остаётся **905** |
| Импорт | parsed=175, imported=175 |
| 906 | куратор 126 / мероприятия 138 / код 152 |
| vs 905 | пересечение CHANGE=0; 905 шире (зелёные MAY + не-QIV) |

904 (S57) не перезаписывалась.

## Скрипт

```bash
node 03_LOAD_CMM_FROM_MAILING_GREEN.mjs           # apply
node 03_LOAD_CMM_FROM_MAILING_GREEN.mjs --dry     # только SQL
```

## Связь

- Перенос MAY→MAIL: чат 2026-09-17  
- S81: [26-0916-sudz-rslt-cmm-backfill](../26-0916-sudz-rslt-cmm-backfill/)
