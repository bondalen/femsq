# Access: `cnNum` (+ стороны + СФ + задолженности) — скрины (0071)

**Дата:** 2026-08-15 (пакеты 1–4)  
**Чат:** `chat-2026-08-11-001` (воронка 0069) → блокер **экран «Договоры»**  
**Назначение:** полное описание **действующей** формы Access (живая `ags`); UI FEMSQ строить по **целевой** модели ([dbtvar](../../../domain/sudz/assets/26-0807-sudz-target-sketch-dbtvar.png)), не копируя вложенность/`cnInvAccnt*`.  
**Эскиз FEMSQ:** [02-10_contracts-cnNum-access.md](../../02-10_contracts-cnNum-access.md)  
**VBA:** [Form-Modules](../../../../project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/) (`Form_cnNum`, `Form_cn`, `Form_inv`, `Form_cnInv>AccntSmpl_t`, …)

## Зачем сейчас

Шаг `CnExistCtptNotLoad` только показывает расхождение исполнителя; пакетного apply в Access нет. MVP-минимум экрана — **номер → cn → стороны**. Ветка **СФ / задолженности / PM / PrDoc** — эталон живого контура для сопоставления с целевым `Dbt`/`invDbtVar`; в первом срезе 0071 **не обязательна**.

### Access (живая) vs целевой эскиз

| Access (форма) | Целевой слой (эскиз) |
|----------------|----------------------|
| `cnNum` → `cn` → `cn_s` → smpl → org | то же ядро (`Cn` / стороны / org) |
| `cnInv` / `inv` / `invNum` | `cnInv` / `Inv` / `invNum` |
| `cnInvAccntSmpl` + `cnInvAccnt` + `ciaName` | **`Dbt`** (+ связи `invDbtDbt`) |
| `cn_inv_dbt` (+ upl) | **`DbtValue`** / факты по выгрузке |
| контекст имени в своде (через smpl/accnt/org) | **`invDbtVar`** (+ `invDbtDbtVar`) |
| `cn_inv_pm` / `ags_cn_inv_pm_dbt_upl` | `cn_inv_pm` / `cn_inv_pm_upl` (на эскизе) |
| `ags_cn_PrDoc` / `ags_cn_PrDocP` | вне ядра dbtvar (отдельный контур документов) |

---

## A. Цепочка сторон (пакет 1)

```text
cnNum                          RecordSource: ags_cnNum  ORDER BY cnnNum
│  вкладки: [ договор ] [ общее ]   ← на «общее» корня: cnnCn, cnnNum, cnnType, cnnKey, …
│
└─ subform cnNum→cn            Link: cnnCn → cn_key
   Form: cn                    RecordSource: ags_cn
   │  вкладки: [ номер ] [ общее ] [ счёта-фактуры ]
   │  «номер»: cn_date / cn_key / cn_note + вложенные стороны
   │  «общее»: cn_number, cnMark
   │
   └─ subform cn→s             Link: cn_key → cn_key
      Form: cn>s               RecordSource: ags_cn_s
      └─ orgSmpl → org         (см. файлы 04–13)
```

| Файл | Вид | Содержание |
|------|-----|------------|
| `00`…`13` | Design/SQL | Корень + стороны — см. имена файлов |
| `20-runtime-cnNum-list-sides.png` | Runtime | Список `cnnNum`/`cnnTyp`; вкладка номер + исполнитель/org |
| `21-runtime-cnNum-tab-general-cnn-fields.png` | Runtime | Корень «общее»: поля `cnn*` |
| `22-runtime-cn-card-tab-general-cnMark.png` | Runtime | Карточка cn «общее»: `cn_number`, `cnMark` |

---

## B. Ветка счетов-фактур и задолженностей (пакет 2)

```text
cn (вкладка «счёта-фактуры»)
└─ shell cnNum>cn>cn           Link: cn_key → cn_key
   вкладки: [ связанные СФ ] [ добавить связь ] [ общее ]
   │
   ├─ список связей            RecordSource: ciNumCs (ciCn, iKey, iNum)
   │     Link к cn: cn_key → ciCn
   │
   └─ форма inv                RecordSource: ags_inv  (iKey, iDate, iNote, …)
        вкладки: [ номера СФ ] [ договоры и задолженности ] [ общее ]
        │
        ├─ inv>invNum          Link: iKey → inInv     → ags_invNum
        │
        └─ inv→cnInv           Link: iKey → ciInv     → ags_cnInv
             вкладки: [ задолженности ] [ общее ]
             │
             └─ AccntSmpl_t    Link: ciKey → ciasCnInv → ags_cnInvAccntSmpl
                  (ciasAccnt, ciasCn_s_org_smpl, …)
                  далее runtime: cia* / cn_inv_dbt / комментарии…
```

| Файл | Вид | Содержание |
|------|-----|------------|
| `23-runtime-inv-numbers-inNum.png` | Runtime | Связанные СФ → номера (`inKey`/`inNum`/`inNote`) |
| `24-runtime-inv-debts-stack-cn_inv_dbt.png` | Runtime | Стек: ci* → cias* → cia* → `cn_inv_dbt` + вкладки сумм/коммент. |
| `25-runtime-inv-linked-general-iNote.png` | Runtime | СФ «общее»: `iNote`, `iTimeOfEntry` |
| `26-design-subform-cn-to-cnInv-link-cn_key.png` | Design | Subform `cnNum>cn>cn`: Link `cn_key`↔`cn_key` |
| `27-design-form-cnInv-shell-ags_cn.png` | Design | Оболочка; RecordSource `ags_cn` (фильтр по cn) |
| `28-design-subform-ciNum-link-cn_key-ciCn.png` | Design | Список связей: Master `cn_key` → Child `ciCn` |
| `29-design-form-ciNumCs-recordsource.png` | Design | `ciNumCs`: `ciCn`, `iKey`, `iNum` |
| `30-design-subform-inv-unlinked.png` | Design | Subform `inv` (Link пустой — контекст/синхрон) |
| `31-design-form-inv-ags_inv.png` | Design | Форма `inv`: RecordSource `ags_inv` |
| `32-design-subform-inv-to-invNum-link.png` | Design | `inv>invNum`: `iKey` → `inInv` |
| `33-design-form-invNum-ags_invNum.png` | Design | `ags_invNum` |
| `34-sql-ags_invNum.png` | SQL | `inKey`, `inNum`, `inNote`, `inInv`, `inTimeOfEntry` |
| `35-design-subform-inv-to-cnInv-link.png` | Design | `inv→cnInv`: `iKey` → `ciInv` |
| `36-sql-ags_cnInv.png` | SQL | `ciKey`, `ciCn`, `ciNote`, `ciMark`, `ciInv` |
| `37-design-form-cnInv-ags_cnInv.png` | Design | `cnInv` + вложенный AccntSmpl |
| `38-design-subform-cnInv-to-AccntSmpl-link.png` | Design | `ciKey` → `ciasCnInv` |
| `39-design-form-AccntSmpl_t-fields.png` | Design | поля `cias*` |
| `40-sql-ags_cnInvAccntSmpl.png` | SQL | `ciasKey`…`ciasTimeOfEntry` |

---

## C. AccntSmpl_f → Accnt → dbt (пакет 3, файлы `41`–`52`)

```text
AccntSmpl_f                    RecordSource: ags_cnInvAccntSmpl
  вкладки: [ задолженности | платежи | первичные документы | общее ]
  │
  ├─ Accnt_t                   Link: ciasKey → ciaCnInvAccntSmpl
  │    Accnt_f                 Filter VBA по ciaKey; RecordSource: ags_cnInvAccnt
  │    └─ dbt_t                Link: ciaKey → cidCnInvAccntCtpt
  │         RecordSource: ags_cn_inv_dbt
  │
  ├─ платежи → pm              Link: ciasKey → ciaCnInvAccntSmpl  (см. пакет 4)
  └─ первичные документы → PrDoc_t  (см. пакет 4)
```

VBA: `Form_cnInv>AccntSmpl_t` фильтрует `AccntSmpl_f` по `ciasKey`; `Form_cnInv>AccntSmpl_f>Accnt_t` фильтрует `Accnt_f` по `ciaKey`. Модулей у `dbt_t` / `AccntSmpl_f` в экспорте нет.

| Файл | Содержание |
|------|------------|
| `41`…`52` | embed AccntSmpl_f; Accnt_t/Accnt_f/dbt_t + SQL `ags_cn_inv_dbt` / `ags_cnInvAccnt` |

---

## D. Lookups / QueryDef (пакет 4a, `53`–`61`)

| Файл | Контрол / объект | RowSource |
|------|------------------|-----------|
| `53` | QueryDef `ciNumCs` | `cnInv ⋈ invCs` → `ciCn`, `iKey`, `iNum` |
| `54`–`55` | `cnnType` | `ags_cnNumType` (`cnntKey`, `cnntName`) |
| `56`–`57` | `ciasAccnt` | `ags_accnt` (`account_key`, `account_num`) |
| `58`–`59` | `ciaCn_s_org` | `ags_cn_s_orgCs` (`cn_s_org_key`, `name`) |
| `60`–`61` | `cn_inv_dbt_upl` | `ags_cn_inv_dbt_upl` (`upl_key`, `uplNmCs`) |

---

## E. Платежи + первичные документы (пакет 4b, `62`–`74`)

```text
AccntSmpl_f «платежи»
└─ form cn>cnInv>Accnt>dbt>pm
     RecordSource: ags_cn_inv_pm_dbt_upl   (VIEW/запрос поверх pm+контекст)
     Link: ciasKey → ciaCnInvAccntSmpl
     поля: cn_inv_pm_*, dbt_blns*/cdt_blns*, cnipCstAgPn, doc*, upl, …

AccntSmpl_f «первичные документы»
└─ PrDoc_t                 RecordSource: ags_cn_PrDoc
     Link: ciasKey → cnpdCnInvAccntSmpl
     └─ P_t                RecordSource: ags_cn_PrDocP
          Link: cnpdKey → pdpPrDoc
          lookup стройка: pdpCstAgPn ← ags_cstAgPnCs
```

| Файл | Вид | Содержание |
|------|-----|------------|
| `62` | Runtime | вкладка «первичные документы» — из‑за ошибки Access показан **layout платежей** (не эталон PrDoc) |
| `63` | Runtime | колонки `cnpd*` пустые (данные не открылись) |
| `64`–`66` | Design/SQL | вкладка «платежи» + `ags_cn_inv_pm_dbt_upl` |
| `67`–`72` | Design/SQL | `PrDoc_t` / `P_t` + `ags_cn_PrDoc` / `ags_cn_PrDocP` |
| `73`–`74` | Lookup | `pdpCstAgPn` ← `ags_cstAgPnCs` |

**Пробел:** наполненный runtime вкладки «первичные документы» (из‑за ошибки Access). Структура Design/SQL **есть**; при возможности — один runtime с данными позже.

---

## Замечания для FEMSQ (без реализации)

1. **Точка входа** — `cnNum` (слева список номеров + тип «БУиРГ»); справа nested tabs.
2. **0071 MVP** — список `cnNum` + карточка `cn` + стороны (`cn_s`→smpl→org с `csoCnDate`). Достаточно для `CnExistCtptNotLoad`.
3. **Ветка СФ/долгов** — эталон живого Access; в web **не клонировать** 4–5 уровней вкладок; поля/связи маппить на **`Dbt` / `invDbtVar` / `DbtValue`**.
4. Живой **`ags.*`** остаётся источником правды до миграции; GraphQL-only для домена.
5. Код экрана **не начинать**, пока не согласован подход (S62).
6. PrDoc/PM — полнота описания Access ≈ достаточна по схеме; runtime PrDoc — опционально.
