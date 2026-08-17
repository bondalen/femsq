# Access: `CnInvDbtUpl_2` + `CnInvDbtUpl>File_f` — скрины (0069)

**Дата:** 2026-08-11  
**Чат:** «0069 Загрузка выгрузки. UI» (`chat-2026-08-11-001`)  
**Назначение:** визуальный эталон экрана FEMSQ «СУДЗ → Загрузка свода» (задача 0069 / S61).  
**Эскиз FEMSQ:** [02-9 §4a](../../02-9_sudz-mvp-screens.md#4a-экран-c--загрузка-свода-cn_inv_dbt_upl--лаунчер-file_f)

## Структура Access (по скринам)

```text
CnInvDbtUpl_2
├── сверху: datasheet cn_inv_dbt_upl (upl_date, upl_name, upl_key)
├── полоса выбранной записи: дата + upl_name
└── вкладки:
    ├── загрузка          → subform File_f
    ├── выгрузки платежей → мост cn_inv_dbt_upl_g_p (pm↔dbt)
    ├── счета, сумма      → агрегаты по account_num (ttl / overd)
    ├── задолженности, правка  → cn_inv_dbt (редактирование)
    └── задолженности, чтение  → cn_inv_dbt (просмотр)

CnInvDbtUpl>File_f  (вкладка «загрузка»)
├── cidufPath | ☑ Обновлять | ☑ обнов. по исх? | [загрузка]
├── cidufKey / cidufUpload (служебные)
└── подвкладки:
    ├── ход загрузки              → cidufLoadingProgress (RTF/HTML-лог)
    ├── перечень листов           → CnInvDbtUplFileSh (лист, счёт, проверять?)
    └── повторяющиеся счета-фактуры → InvDouble (+ «создать СФ для договора»)
```

## Каталог файлов

| Файл | Вид | Содержание |
|------|-----|------------|
| `00-design-main-form-overview.png` | Design | `CnInvDbtUpl_2`: шапка upl_* + вкладки |
| `00b-design-file-f-overview.png` | Design | `File_f`: path, флаги, кнопка, подвкладки |
| `01-runtime-load-progress-log.png` | Runtime | «загрузка» → «ход»: полный путь X:\…xlsx, лог после прогона |
| `02-runtime-load-sheets-list.png` | Runtime | «перечень листов»: лист=счёт ГК, «проверять?» |
| `03-runtime-load-duplicates-invdouble.png` | Runtime | «повторяющиеся СФ» + кнопка создания СФ |
| `04-runtime-accounts-sum.png` | Runtime | «счета, сумма»: account_num / ttl / overd + итог |
| `05-runtime-debts-edit.png` | Runtime | «задолженности, правка»: строки cn_inv_dbt |
| `06-runtime-pm-uploads-tab.png` | Runtime | «выгрузки платежей (БухРГ)» |
| `07-design-file-f-progress-rtf.png` | Design | `cidufLoadingProgress`: формат текста = RTF |
| `08-design-file-f-sheets-subform.png` | Design | RecordSource → `CnInvDbtUplFileSh` |
| `09-design-file-f-invdouble-readonly.png` | Design | грид неоднозначностей; AllowEdits=Нет на форме грида |
| `10-design-main-pm-bridge-g_p.png` | Design | вкладка платежей → `ags_cn_inv_dbt_upl_g_p` |
| `11-design-main-upl-sum-query.png` | Design | источник списка/сумм → `ags_q_cn_inv_dbt_upl_sum` |
| `12-design-main-debts-cn_inv_dbt.png` | Design | задолженности → `ags_cn_inv_dbt` |

## Замечания для FEMSQ

- Раскладка Access — **список сверху / детали снизу**, не master слева (как A0).
- Полный UNC/путь в `cidufPath` в браузере недоступен так же, как в Access; в FEMSQ v1 — FSA имя файла/папки (S60).
- Лог — **RTF** с цветами; в web — HTML (как Progress) или plain с минимальной разметкой.
- Внешний ряд вкладок (счета / долги / pm) — справочный контур после загрузки; для первого UAT лаунчера **не обязателен** (S61), но скрины сохранены как эталон следующей итерации.

| `13-access-nav-local-tables.png` | Nav | Локальные таблицы Access (`CnInvDbtUplFile*`, `CnInvDbtUplTbl*`, …) |
| `14-access-er-file-vs-ags-upl.png` | ER | `CnInvDbtUplFile`/`FileSh` ↔ `ags_cn_inv_dbt_upl` / `ags_cn_inv_pm_upl` / `CnInvPmtUplFile` |

## SQL Server vs Access (проверка DBHub, 2026-08-11, nb-win / FishEye)

| Объект | Где | На SQL Server? |
|--------|-----|----------------|
| `cn_inv_dbt_upl` | `ags` / `sudz` | **да** (таблица) |
| `cn_inv_pm_upl` | `ags` / `sudz` | **да** |
| `cn_inv_dbt` | `ags` | **да** |
| `cn_inv_dbt_upl_g_p` | `ags` / `sudz` | **да** |
| `cn_inv_dbt_double` | `ags` | **VIEW** (диагностика дублей сумм; ≠ Access InvDouble) |
| `CnInvDbtUplFile` | Access local | **нет** |
| `CnInvDbtUplFileSh` | Access local | **нет** |
| `CnInvDbtUplTbl` / `TblCnInv` / `TblCnInvOld` | Access local | **нет** |
| `CnInvDbtUplFileInvDouble` | Access local | **нет** |
| `CnInvPmtUplFile` / `CnInvPmtUplTbl*` | Access local | **нет** |
| `ags_Yr_DbtTbl`, `cn_PrDocImp`, `cipuCn_*` | Access local (по nav) | **нет** |

Связь на ER: `CnInvDbtUplFile.cidufUpload` → пакет `ags_cn_inv_dbt_upl.upl_key` (линия на скрине может не отображаться; поля: `cidufPath`, `cidufFlLoad`, `cidufFlTbl`, `cidufLoadingProgress`).

