# Первый промпт — чат «fn2 / RS факт × stCost»

Скопировать в **новый** чат Cursor целиком (или от «Начни с» до конца).

---

## Промпт

```text
Работаем по плану:
docs/development/notes/chats/chat-plan/chat-plan-26-1126-fn2-stcost-fact-rs.md
Задача 0094 · трек C4 (ранний gate) · стенд FishEye_prod_noM6.

### Цель
В RS spMstrg_2606 / PercentBrn факт освоения по агентской схеме должен
резаться @stCostKey так же, как лимит:
  ag_presented*(212) ≈ (195)+(172)+(187)
  ag_accepted*(212)  ≈ (195)+(172)+(187)
Сейчас лим ✅, факт ≈ полный объём на каждом срезе → сумма частей ≈ 3×212 — для бизнеса бесполезно.

### Решение владельца (вход, не пересматривать без явной просьбы)
Вариант A:
  @stCostKey IS NULL     → как сейчас (RRcTimeList / @raFact2408, «взять всё»)
  @stCostKey IS NOT NULL → agency (iShKey=2, shShow) financials из mastering
                           (mstrPresented / mstrAccepted / …), НЕ из rf.*
Не закрывать задачу одним 07j: канон приёмки — аддитив в RS на цепи 507.
Варианты B/C (масштаб RRc через factDocCost; всегда mastering) — вне v0.1.

### Откуда спин-офф (C2 §3.6–3.7, чат chat-2026-11-20-001)
Контур подготовки УЖЕ сделан — не повторять O1/sh/ipgPnLim с нуля:

1) ipgpSh на ИП 27–30: шаг 2 FROM_PREV(prev=26) | else 2; COUNT(sh=4)=0.
   Код: DefaultImpIpgShResolveService.DEFAULT_UNDEFINED_SH = 2
   (API source DEFAULT_4 = «default», значение ключа 2).
   Notes: docs/development/notes/chats/chat-plan/notes/26-1126-c2-o1-ipgpsh-step2-37.md
          §5.2 в 26-1123-c2-o1-prod-delta-requirements.md обновлён.

2) ipgPnLim на 27–30 seeded из ipgpSmTtl/Wrk/Equ/Oth → 212/195/172/187
   (как на эталонных ИП 1/3/5/6/8/11). Без этого fnStCostIpgPn_2606=0
   и typeGrTtl уходит в «1.2. Инв. (Аг., неплан)» → ag_* пустые.
   Хвост O1 (не этот план): apply должен писать ipgPnLim сам.

3) После remaster @507: ag_ipgpKey NN (~391@212), ag_lim аддитивен
   (δ≈0.01), ag_presentedAccum >0 но НЕ аддитивен по stCost.

4) Ревизии dir=15: adt 15 type5, 16 type6, 17 type3 — COMPLETED
   (часть execute через GraphQL из‑за hang fetchAudits).

5) Диагноз дыры в fn2 (не трогать «просто перейти на 07j»):
   docs/.../MSSQL2012/04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql
   ~строки 547–558:
     IIF(iShKey=2 AND shShow, rf.presented, mstrPresented) …
   rf = @raFact2408 из RRcTimeList — без @stCostKey.
   lim/mstr — из fnMasteringStIpgStCost_2606(@stCostKey) — с фильтром.
   ADR-конфликт: 03-design-decisions.md фиксировал RRc для паритета _2408
   (ras_total vs factDoc@212 после 2022). Здесь ЯВНОЕ исключение:
   при NOT NULL бизнес-срез важнее паритета «полный ras_total».

### Ключевые файлы
- Патч: docs/development/notes/sql/26-0604/04_…fn2… и MSSQL2012/04_…
- Нижний слой (диагностика): 07j_COMPARE_stCost_fact_additive_chain5.sql
- Карта fact→stCost: docs/.../05-fact-stcost-map.md; план 11-ra-work-stCost195
- C2 план: chat-plan-26-1120-c2-d11-ipg-plans.md (хвост → этот план)
- Roadmap: chat-plan-26-1116-roadmap-r1.md §5

### Первый шаг в этом чате
1. Проверка окружения по .cursorrules (машина, DBHub, SQL Server, mcp.json).
2. План → in-progress; задача 0094 → in-progress; чат журнала → in-progress.
3. §0 контракт/note + §1 быстрый аудит factDocCost по сайтам цепи 507/2026.
4. Затем §2 патч fn2 (A) → apply → §3 матрица RS @507.

Не смешивать с C2 O2 UtPl и не чинить UI ревизий в этом чате.
Начни с п.1–2 и кратко подтверди готовность контура 507 (sh/lim/ag_*).
```

---

**Связь:** план [chat-plan-26-1126-fn2-stcost-fact-rs.md](../chat-plan-26-1126-fn2-stcost-fact-rs.md) · задача **0094** · чат журнала `chat-2026-11-26-001` (создаётся при старте / уже в registry).
