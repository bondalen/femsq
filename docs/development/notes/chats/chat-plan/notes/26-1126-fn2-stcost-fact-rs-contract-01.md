# §0–§1: контракт fn2 agency×stCost + аудит factDocCost @507

**Дата:** 2026-11-26  
**План:** [chat-plan-26-1126-fn2-stcost-fact-rs.md](../chat-plan-26-1126-fn2-stcost-fact-rs.md) · задача **0094**  
**Стенд:** `FishEye_prod_noM6` · цепь **507** · ИП **27** · год **2026**

---

## §0. Контракт (вариант A, владелец 2026-11-26)

### Семантика `@stCostKey` в `fnIpgChRsltCstUtl2_2606`

| `@stCostKey` | Agency (`iShKey=2`, `shShow`) presented / accepted | Прочие схемы (1, 3) |
|--------------|-----------------------------------------------------|---------------------|
| **NULL** | как сейчас: `rf.*` ← `raFact2408` / `RRcTimeList` (паритет «взять всё» / `_2408`) | `mstr*` из mastering |
| **NOT NULL** | **`mstrPresented` / `mstrAccepted`** (и аналоги из `@schemeRows`, источник `agMstrngPrsRaMn` / `AcpRaMn` ← factDocCost) — **не** `rf.*` | без изменений (уже `mstr*`) |

### Явное исключение из ADR «agency = RRc»

В [03-design-decisions.md](../../../sql/26-0604/docs/03-design-decisions.md) Решение 11 и [09-scheme-cascade-mastering.md](../../../sql/26-0604/docs/09-scheme-cascade-mastering.md) §B.2 фиксировали: на агентской строке RA из `RRcTimeList` для паритета `_2408` (после 2022 `ras_total` vs legacy `fnStCostRa`).

**Исключение (Решение 23):** при `@stCostKey IS NOT NULL` бизнес-срез 195/172/187 важнее паритета полного `ras_total`. RRc без фильтра stCost даёт факт≈полный объём на каждом срезе → сумма частей ≈ 3×212.

### Вне v0.1

- **B** — масштаб RRc через `factDocCost`
- **C** — всегда mastering даже при NULL
- `returned` / `inProcess` / `notArrived` / `presentedAll*` — остаются на `rf` при NULL; при NOT NULL поведение уточняется в §2 (в mastering monthly для agency сейчас только Prs/Acp (+ fee/ralp/…); статусы «в пути» в `@schemeRows` не разведены)

### Канон приёмки

Аддитив **в RS** `spMstrg_2606` / PercentBrn на цепи 507:  
`SUM(ag_presentedAccum)` и `SUM(ag_acceptedAccum)`: 195+172+187 ≈ 212 (ε как 07j).  
07j — нижний слой диагностики, не замена RS.

---

## §1. Аудит данных factDocCost (507 / 2026)

### RA ↔ factDoc

| Метрика | Значение |
|---------|----------|
| Сайтов (`cstAgPn`) на цепи | **398** |
| `ra_summ` с `YEAR(ra_datePeriod)=2026` | **6825** |
| с `ras_fdKey` | **6825** (0 без fd) |
| docs с `factDocCost@212` | **3622** |
| docs с нулевым `ras_total` / без частей | **3203** (пустые оболочки — ок) |
| `mismatch 212 vs ras_total` | **0** |
| `non_additive parts` (per-doc 195+172+187≠212) | **0** |
| Gate `flat_work@182` (2026, цепь) | **0** PASS |

Агрегат `SUM(fdco@195+172+187) = SUM(fdco@212)` на контуре.

### Нижний слой mastering (не RS)

`fnMasteringPresRa_2606` / `AccpRa` читают `factDocCost` и **дают ненулевой срез** по stCost (не путать с «дырой fn2» = RRc без фильтра).

Spot `@dAll=2026-11-30`, `@stNet=5`, `@subAg=0`:

| cstAgPn | p212 | p195+172+187 | δ |
|--------:|-----:|-------------:|--:|
| 849 | 3.602e10 | ≈ | ~10 |
| 3716 | 1.745e11 | = | 0 |
| 1507 | 6.654e10 | = | 0 |
| 218 | 5.254e10 | = | 0 |
| 403 | 1.069e11 | 1.070e11 | ~1.4e8 ⚠️ |

δ на 403 — зафиксировать при §3; не блокер покрытия (разбивка есть).  
Вызов с `@subAg=NULL` даёт NULL — в диагностике всегда `0`.

### Вердикт §1

Данные для варианта A **готовы**: factDocCost заполнен и аддитивен на RA 2026 цепи 507; mastering PresRa режется по stCost. Риск «патч обнулит факт» из‑за пустого factDocCost — **снят**.

---

## Следующий шаг

§2 патч `04` + `MSSQL2012/04` (ветка `iShKey=2 AND @stCostKey IS NOT NULL → mstr*`) → apply → §3 матрица RS @507.
