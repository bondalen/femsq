# §2–§3: патч fn2 (A) + приёмка RS @507

**Дата:** 2026-11-26  
**План:** [chat-plan-26-1126-fn2-stcost-fact-rs.md](../chat-plan-26-1126-fn2-stcost-fact-rs.md) · **0094**  
**Стенд:** `FishEye_prod_noM6`

---

## §2 Патч

| | |
|--|--|
| Dev | `docs/development/notes/sql/26-0604/04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql` |
| Зеркало | `MSSQL2012/04_…` (тот же IIF) |
| Суть | `presented`/`accepted`: agency + `@stCostKey IS NULL` → `rf.*`; иначе → `mstr*` |
| Apply | `CREATE OR ALTER` на `FishEye_prod_noM6` (sed USE); VERIFY `PATCHED` |
| Побочно | первый прогон без sed попал в БД `FishEye` (тот же хост) — тоже пропатчен |

Диагностика приёмки: `07k_COMPARE_stCost_fact_RS_chain507.sql`.

---

## §3 Матрица RS (`07k`, `@MounthEndDate=20261130`, site-grain max `dateRslt`, `ag_ipgpKey NN`)

| stCost | EXIT | nn_ipgp | sum_lim | sum_pres | sum_accp |
|--------|-----:|--------:|--------:|---------:|---------:|
| NULL | 0 | 391 | ~1.057e12 | ~6.42e11 | ~5.98e11 |
| 212 | 0 | 391 | ~1.057e12 | ~1.744e9 | ~4.11e7 |
| 195 | 0 | 163 | ~7.44e11 | ~1.329e9 | 0 |
| 172 | 0 | 325 | ~2.41e11 | ~2.47e8 | ~4.11e7 |
| 187 | 0 | 357 | ~7.22e10 | ~1.67e8 | 0 |

| Gate | δ | Результат |
|------|--:|-----------|
| lim 195+172+187≈212 | ≈0.01 | **PASS** |
| presented Accum | ≈0 | **PASS** |
| accepted Accum | 0 | **PASS** |
| NULL smoke (факт >0) | — | **PASS** |

~113 с на 5 прогонов.

### Замечания

1. При `NOT NULL` объём факта ≪ RRc@NULL — ожидаемо (Решение 23 / factDocCost vs полный `ras_total`).
2. `accepted@195/187=0` при ненулевом `presented` — данные стенда; аддитив 195+172+187=212 для accepted всё равно PASS за счёт 172.
3. Канон ценности закрыт на **RS**, не только 07j.

### Природа `lim δ≈0.01` (07k1, 2026-11-26)

**Не** артефакт fn2 и **не** только float в 07k.

| Слой | δ | Где |
|------|--:|-----|
| `ipgpSm*` / `ipgPnLim` @ipg=27 | **1e−8** | ровно **1** стройка |
| RS `ag_lim` (×1 000 000) | **0.01** | та же стройка |

- **cstapKey = 3555**, `ipgpKey = 12464`, `ipgpSh = 2`
- `SmTtl=1634.23604378`; Wrk+Equ+Oth=`1634.23604377` → δ=`1e-8`
- seed lim ← Sm → та же δ; в PercentBrn ×1e6 → **0.01**
- 390/391 строек: δ=`0` exact (decimal)
- Скрипт: `07k1_DIAG_lim_delta_by_site_chain507.sql`

Итог: расхождение **в исходных Sm/лимите пункта** (Ttl записан на 1e−8 больше суммы частей), не в патче A.  
Норма и ремонт: [ADR 012](../../../../../project/decisions/012-money-agg-axes.md) · задача **0095** · [план money-agg](../chat-plan-26-1126-money-agg-axes.md).

---

## Next

§4: ссылки C2 §3.6.4 / roadmap; опц. 07j; закрытие 0094.
