# Диагностика plan-align — этап 21.4.2

**Дата:** 2026-07-06  
**Dev:** FishEye @ `10.7.0.3`, цепь 5  
**Скрипты:** `07v_diag_plan_align_chain5.sql`, `run_diag_21_4_2.sh`  
**Архитектурное решение:** `03-design-decisions.md` **§22**; `glossary.md` (широкие месячные колонки)

---

## Preflight

| Проверка | Результат |
|----------|-----------|
| `07_VERIFY_after` | PASS — объекты `_2606`, fn2=11587, PercentBrn=15262/17 |
| `07n` cst **2102** | PASS (К-12 strict) |
| `07n` cst **849** | PASS (К-12 strict) |
| `07o` spot 2102 | FAIL — `iv_Pl`/`iv_PlAccum` NULL на ИП 11 (на yearend активна только ИП 11) |

Fixture **не откатывался** — данные UtPlMn на месте.

---

## Точка обрыва (вердикт)

**Обрыв между слоем данных UtPlMn и PercentBrn:**

| Слой | Состояние |
|------|-----------|
| L1 `ipgPn` + `ipgChRl_2606` | OK — схемы и группы 18–20 на активных ревизиях |
| L3 **`ipgUtPlPnLmMn`** (sparse) | OK — sum@212 ненулевой (849: 254 778; 2102: 1 334 на ИП 11) |
| L3 **`ipgUtPlP.iuplpM12`** | **NULL** на golden-строках в группах 18–20 |
| L4 JOIN gap/gip (как в PercentBrn) | Строка есть, **`iuplpM12` = NULL** → `ag_Pl_sim` = NULL |
| L5 PercentBrn `_2606` | `iv_ipgpKey` / `ag_ipgpKey` / лимиты / факт OK; **`iv_Pl` / `ag_Pl` = NULL** |
| L6 `iShKey` vs `ipgpSh` | OK — mismatch нет |

### Почему `_2605` показывает план, а `_2606` — нет

Для **849**, ИП **11**, `ipgpKey=4817`:

- **Legacy** `ipgChRl` → prod-группа UtPl → `iuplpPl=85`: **`iuplpM12=33929.32`**, `iuplpM12Accum=254778.46`
- **Тест** `ipgChRl_2606` → gr **20** → `iuplpPl=203`: **`iuplpM12=NULL`**, но **UtPlMn@212** заполнен по всем 12 месяцам

`fnIpgChRsltCstUtlPercentBrn_2605` @ yearend: `ag_Pl ≈ 33.9 млрд`, `ag_PlAccum ≈ 254.8 млрд`  
`fnIpgChRsltCstUtlPercentBrn_2606` @ yearend: `ag_Pl = NULL`

PercentBrn (и `_2605`, и `_2606` **до Решения 22**) берёт план из колонок **`ipgUtPlP.iuplpM01`…`iuplpM12`** (семантика **итога stCost 212**, без колонки stCost), **не** из `ipgUtPlPnLmMn`.

После FIXTURE_06 (swap на группы 18–20) приёмка **К-12** идёт по **UtPlMn**; колонки **`iuplpM*`** на связанных `iuplpPl` **не синхронизированы**.

---

## Дополнительно: календарь смены ИП vs gate `07o`

На `2022-12-31` для golden-строек **активна одна инвестпрограмма в цепи — ИП 11** (периоды ИП 6 и 8 **завершены** по `ipgcrvEnd` — это **смена актуальности инвестпрограммы**, не «ревизия» факта; см. глоссарий).

Gate `07o` (требовать `iv_Pl` на ИП **6, 8, 11** одновременно на yearend) **семантически некорректен** — пересмотр в Решении 22: проверка по **календарю `dateRslt`** (как `07t`, К-12r в `07n`).

---

## Направление для **21.4.3** (принято — Решение 22)

1. **PercentBrn `_2606`:** `ag_Pl`/`iv_Pl` из cumulative **LmMn @212** (как `fnStCostRsIpgPn_2606`), не из `iuplpM*`.
2. **`_2605` / prod PercentBrn** — не трогать.
3. **Пересмотреть `07o`** — критерий по датам календаря, не «три ИП на yearend». ✅ **2026-07-06** (21.4.4)
4. **FIXTURE_09** (backfill `M*`) — **не** принято как долгосрочное решение.

---

*Связано: `03-design-decisions.md` §21, §**22**; `13-plan-stcost-monthly-acceptance.md`; этап **21.4.3**.*
