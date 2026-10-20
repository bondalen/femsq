# Деплой: `usp_RebuildDbtUplCstAg` 14g + `dvDocBase` CnInv≻Doc

**Дата:** 2026-10-20  
**План:** [1019](../development/notes/chats/chat-plan/chat-plan-26-1019-qii-pmt-rslt.md) §1.7–1.8  
**Пакет SQL:** `docs/development/notes/sql/26-0921-sudz-dbt-upl-cst-ag-exp/MSSQL2012/`  
**Цель:** FishEye SQL Server **2012 SP4** + JAR FEMSQ с правкой записи `DbtValue`

---

## 1. Что меняется

| Компонент | Содержание |
|-----------|------------|
| `sudz.usp_RebuildDbtUplCstAg` | Канон **14g**: H1 + H2soft + H3soft2 |
| `JdbcSudzDao` INSERT `DbtValue` | `dvDocBase = COALESCE(NULLIF(CnInv), NULLIF(Doc))` |
| Опционально DML | Backfill уже загруженных Value из Tbl (`13_…`) |

На DEV после этого: conflict QIV/QI ↔ `26-0505` = **0** (жёсткие); приняты 5 GEN + 2 multi.

---

## 2. Порядок на продуктиве

1. Бэкап БД FishEye.  
2. Выкладка **JAR** с CnInv≻Doc (иначе новые загрузки снова пишут Doc≻CnInv).  
3. SQL (только из **`MSSQL2012/`**):
   - `12_CREATE_usp_RebuildDbtUplCstAg_P2_H1_H2soft_H3soft2.sql`
   - `13_BACKFILL_DbtValue_dvDocBase_CnInv_first.sql` (для upl, уже в Tbl; на чистой БД можно пропустить)
   - `EXEC sudz.usp_RebuildDbtUplCstAg 901` (и 902, 903 по наличию `g_p`) — **долго** (H3soft2, минуты на upl)
   - `14_VERIFY_after_14g.sql`
4. Smoke: Rslt yr/asOf; выборочно 11925/8655/3672.  
5. Откат usp: применить прежний скрипт P1 (`09_…`) или P2 inline из корня пакета `13_CREATE_usp_…_P2_inline.sql` (адаптировать в MSSQL2012 при необходимости). Value backfill откатом не снимается автоматически — только из бэкапа.

---

## 3. Не входит в этот пакет

- Карта колонок QII без срока (**0922 1.13.7**).  
- Усиление H2soft (короткий doc при nCst=1) — опционально позже.  
- Перенос Acceptance-артефактов classify (лежат в `artifacts/`, в git не коммитятся).

---

## 4. Чеклист дня

- [ ] `@@VERSION` / compatibility 2012  
- [ ] JAR с CnInv≻Doc  
- [ ] `12` usp  
- [ ] `13` backfill (если нужны старые upl)  
- [ ] rebuild Duca @901/@902/@903  
- [ ] `14` verify  
- [ ] выборочная сверка Rslt  
