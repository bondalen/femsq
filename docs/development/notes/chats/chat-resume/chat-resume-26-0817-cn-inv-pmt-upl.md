# Резюме чата 26-0817: паспорт Access `CnInvPmtUpl*` (процесс 1.1.1.2)

**Дата:** 2026-08-17 – 2026-08-18  
**Последнее обновление:** 2026-08-18  
**Тема:** Съём эталона MS Access для загрузки `export_{счётГК}_*` — формы `CnInvPmtUpl*`, VBA `btnUpload`, локальные таблицы, QueryDef `cipu*` / `agsCnCtpt*`. Java-воронка платежей **не** входила в объём.  
**Задачи:** инвентарь СУДЗ [0065](../../../project-development.json) (док); реализация pmt **не** открывалась  
**Журнал:** `chat-2026-08-17-001` (completed)  
**Машина:** nb-win (WSL2); DBHub OK; `femsq-mssql` Up; Excel-шара `D:\wire-guard-share-nb-win\femsq\excel\…`

**Не смешивать:** воронка долгов `CnInvDbtUpl` / 0069; КСДСФ (S68 / S68t) — только ссылка на будущий адаптер pmt.

## Связанные документы

- [02-11_cn-inv-pmt-upl-access.md](../../UI/02-11_cn-inv-pmt-upl-access.md) — паспорт формы (закрыт)
- [chat-plan-26-0802-sudz.md](../chat-plan/chat-plan-26-0802-sudz.md) §5.7 — инвентарь S69
- [03-processes §1.1.1.2](../../domain/sudz/03-processes.md)
- [04-data-model §2.9](../../domain/sudz/04-data-model.md#29-алгоритм-btnupload_click--cninvpmtupl-процесс-1112-каркас-s69) — 13 шагов `cipu*`
- Съём: [26-0813_CnInvPmtUpl_/](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/)
- Скрины: [assets/26-0817-cn-inv-pmt-upl/](../../UI/assets/26-0817-cn-inv-pmt-upl/README.md)
- VBA: `VBA-Code-Export/Form-Modules/Form_CnInvPmtUpl_gt_File_f.cls`, `…_gt_cnInv.cls`

## Контекст

Общий свод (1.1.1.1) не содержит привязки к стройке / САК. После свода специалисты грузят `export_{счётГК}_*` через Access. До этого чата в репозитории были табличный съём File/Tbl/TblCnInv/Tbl_1 и два модуля форм; RecordSource, QueryDef `cipu*`, буфер шага 12 и карта Excel Offset не были сняты. SQL запросов не выдумывали: только конструктор, UTF-8-дамп QueryDef или скрин.

## Выполненные фазы съёма

| Фаза | Содержание | Итог |
|------|------------|------|
| Nav / родитель | `CnInvPmtUpl` ← `ags_cn_inv_pm_upl`; Link File_f `cn_inv_pm_key`↔`cipufUpload`; `_2` нет | ✅ |
| File_f | полный RS 7 полей `CnInvPmtUplFile`; `cipufLoadingProgress` Memo RTF; вкладки ход / InvDouble / CstNew / прочее | ✅ |
| Nested | InvDouble = view над `TblCnInv` (нет `FileInvDouble`); Link к File **пустой**; `invNum`→`cnInv` | ✅ |
| VBE | у pmt только `File_f` и внутренний `cnInv`; родитель / Sum_t / InvDouble / nested invNum / CstNew — HasModule = Нет | ✅ |
| QueryDef | дамп живого контура `cipu*` (40 файлов) + helper `agsCnCtpt*` | ✅ |
| Буфер шага 12 | `cipuCn_CtptCnOneInvOneAcDcExtPmTbl` (имя **ExtPmTbl**, не ExtPmtTbl); 40 полей, без PK, 7736 строк | ✅ |
| Excel Offset | якорь «№ докум.» = **U1**, колонки A–Z, пять файлов `26-0422` идентичны | ✅ |
| Runtime InvDouble | выбран `export_606012_25-0721` — **0 строк** | ✅ |
| Вопрос 5 | apply шага 8 намеренно закрыт владельцем | ✅ |

## Ключевые решения и факты

| Тема | Решение / факт |
|------|----------------|
| **Шаг 8** `cipuCn_CtptCnOneInvTwoLoad` | Только показ. Создать новую СФ или перепривязать двоящий номер — вручную оператором после решения. Авто-apply в загрузке закрыт. Java на этом шаге не пишет. Согласуется с S68 п.3. |
| INSERT при `flLoad` | `cipuInsPmNotIns` → `ags_cn_inv_pm`; `cipuDocNotIns` → `ags_cn_inv_doc`; `…AcNotIns` → `ags_cnInvAccntSmpl` |
| Исполнитель vs агент | `agsCnCtptExequtorSmplBuirg`: `cn_s_type=2`, номер = `cnnNumNull`. Агент: `cn_s_type=1`, номер = `cnnNum`. `*One` = ровно один `csosKey` на пару (договор, БУиРГ). Не VIEW `ags.cn_s_orgExeBuirg` |
| OId ≠ Old | `cipuCtpt_All_OIdNot` = org_id. Шаг 1 структурно пуст (INNER JOIN + key NOT NULL) |
| Type 20 (DocCode) | Precision 18 / Scale 0 → **dbDecimal**, не GUID |
| Offset | живой VBA `Offset(−20…+5)` от «№ докум.»; закомментированный блок в `File_f` — другая раскладка |
| InvDouble | грид = текущий буфер `TblCnInv` (`ciputciCnInvNumCount` Is Not Null), не выбранная выгрузка |

## Ключевые артефакты

| Тип | Путь |
|-----|------|
| Паспорт | `docs/development/notes/UI/02-11_cn-inv-pmt-upl-access.md` |
| Offset | `docs/project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/export_offset-map.md` |
| RS File_f | `…/CnInvPmtUpl_File_f.recordsource.access.sql` |
| QueryDef | `…/cipu-sql/` и `{Имя}.access.sql` |
| Буфер ExtPmTbl | `…/cipuCn_CtptCnOneInvOneAcDcExtPmTbl.table.md` |
| Runtime InvDouble | `docs/development/notes/UI/assets/26-0817-cn-inv-pmt-upl/29-runtime-invdouble-empty.png` |

## Вне scope (остаётся)

| # | Тема |
|---|------|
| J1 | Java-воронка 1.1.1.2 (`btnUpload` / `cipu*`) — отдельный чат |
| J2 | Эскиз FEMSQ UI для платежей |
| J3 | Адаптер КСДСФ под pmt |
| J4 | Offset других годов, кроме среза `26-0422` |
| J5 | Коммит Excel `export_*.xlsx` в git — не делать |

## Итог

Паспорт Access процесса **1.1.1.2** закрыт. Эталон поведения и SQL сохранённых запросов лежит в `02-11` и каталоге `26-0813_CnInvPmtUpl_/`. Java и UI FEMSQ для pmt в этом чате не начинались.
