# B3 — разбор suspect (asOf916)

Порог рассылки: **suspect = 0**. **Пройден 2026-10-27** (JAR **376**): S79 cand72 / likely68 / **suspect0** / amb2 / doc2.

## dbt 11977 (762210 / КС-51 / 23/236) — ✅ исправлено 2026-10-27

- Опечатка свода QIII: **23/236 → 23/239** (сумма 43 075 586).
- `linkSudzInvDbtToDbt(slotKey=13436, dbtKey=11977)`; P1 `cip1Key` 33357/33358 → `linked`.
- Value @916 снова на каноне 11977 (`dvDocBase=23/239`). Из S79 openCases выпал.

## dbt 7757 (606012 / 29/0402/22 / СФ 52262) — ✅ documented погашение

- Twin **12067** (25/76 / КС-51) с той же суммой 10 M жил с QIV **параллельно** — не опечатка QIII.
- Link 7757→12067 дал бы **10M+10M=20M** — неверно.
- Решение владельца **2026-10-27:** считать **7757 погашенным**; не сливать с 12067.
- Whitelist S79: `E-QIII-Repaid-52262-not-12067` в `SudzRsltRepaymentChecker.documented("52262")`.
- P1@916 `cip1Key` 33390/33391 → `deferred` (причина: owner repaid; do not link to 12067).

## Ambiguous (не порог)

- 12459, 8624 — в cover note; порог рассылки не блокируют.
