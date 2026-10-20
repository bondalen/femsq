# КСДСФ — советник (S68+)

**Дата:** 2026-09-02  
**Последнее обновление:** 2026-10-11 (`pmt_blns_same_cn` / 1.10.4)  
**Зеркало:** [KSDD_ADVISOR.md](../26-0827-sudz-m2-seed/KSDD_ADVISOR.md) (сегм. 22c)

## API (GraphQL)

| Query | Назначение |
|-------|------------|
| `sudzSfDoubleAdvice(ciusKey, epsilon)` | блок `[советник]` в «Сообщения» |
| `sudzSfDoubleHints(ciusKey, epsilon)` | кнопки выбора строк (как раньше) |

## Советник — проверки v1

| check | Рекомендация |
|-------|--------------|
| `executor_unique` | link (high) — один СФ с номером и исполнителем Excel (**не** для подозрительного №) |
| `cn_exact` | link (high) — один такой СФ на договоре Excel (**не** для подозрительного №) |
| `cn_homonym` | create (high) — однофамильцы на **несвязанном** договоре (**после** `sum_same_cn`) |
| `cn_num_variant` | link на **канонический** cn (где уже inv), не на cn очереди |
| `cn_num_alias` | inv уже на cn «711113884/ЯРЭС» → добавить «711113884» как второй cnNum; удалить дубль cn из воронки |
| `executor_none` | create (high) — нет СФ с номером и исполнителем Excel (**после** `sum_same_cn`) |
| **`sum_same_cn`** | link (high) — уникальная сумма (old/new) с исполнителем Excel на договоре очереди и известным `invKey` (номер Excel может отличаться) |
| **`pmt_blns_same_cn`** | link (high, pmt) — ровно одна строка связанного свода с `cidutDebt` = Σ `ciputBlns` и ровно один inv с этим номером на договоре очереди; не для `suspicious_inv`; orphan `cn_inv_pm` не использовать |
| **`suspicious_inv`** | номер ∈ {`б/н`, `Б/С`, `-`, `*`, пусто, …}: **запрет** link high из `executor_unique`/`cn_exact`/`pmt_blns_same_cn`; далее `sum_same_cn` → link; иначе **`suspicious_cac_due`** (1.13.6) |
| **`suspicious_cac_due`** | (1.13.6) среди СФ с тем же № на договоре очереди: фильтр по стройке Excel (срок — уточнение при &gt;1); ровно 1 → **link** high; &gt;1 → **manual**; 0 / нет CAC → **create** high |
| sum unique + один СФ **того же номера** на cn | link (medium) |
| иначе | manual |

`confidence`: high | medium | low | none. Не заменяет первичку.

### `suspicious_inv` (2026-10-05)

**Зачем:** «б/н» на договоре — часто свалка разных строек/пакетов (cius=1310 → legacy inv 40729 с 2023). Совпадение только по номеру даёт ложный **link**.

**Правило:** `SfDecisionCompareUtil.isSuspiciousInvNum` — общий список с шапкой decision-TreeList. При подозрительном № Excel:
1. не рекомендовать link из уникальности номера на cn / `pmt_blns_same_cn`;
2. если есть `sum_same_cn` — link (как Б/С→настоящий номер, UAT C.10);
3. иначе **`suspicious_cac_due`** (0922 **1.13.6**): стройка Excel (и срок при неоднозначности) — фильтр среди существующих СФ на договоре; 1 → link; &gt;1 → manual; 0 → create;
4. иначе — **create** high на договоре очереди (нет CAC в Excel или фильтр пуст).

Жёлтая граница / `due_grp` сами по себе новый СФ не создают.

**Кейсы:**
- pm=59 · cius=**1310** · КС-14 «б/н» · advice был link→**40729** → **create** (apply: 106724, moved=3).
- pm=59 · cius=**1313** · КС-51 «б/н» · Σ0 · матрица 1.9.6 была link→**6884** → **create** (свалка на cn 308; 2×pm59 уже там по InsPm — не доказательство link).

**InsPm (2026-10-05):** `#oneInv` / AcNot не матчат подозрительный № к существующему СФ — иначе платежи снова сядут на свалку «б/н».

**create СФ (2026-10-05):** после inv/cnInv — cias + перенос pm текущего пакета с legacy того же № на договоре; при пустом — вставка из Tbl. Repair: повтор `createSudzSfFromDouble` при status=created.

### `pmt_blns_same_cn` (2026-10-11, лист 1.10.4)

**Зачем:** в контексте платежей якорь суммы — Σ `ciputBlns` по присвоению, а не `cidutDebt` Excel и не orphan `cn_inv_pm`. Если связанный свод (`g_p`) даёт ровно одну строку с тем же номером СФ/счётом и долгом = итог сальдо, а на договоре очереди ровно один такой inv — link high надёжнее, чем одно только `sfByNum`.

**Условие:** `sudzPmtSfSumCompare` linked; среди `matches` ровно одна с `|debt − Σ| ≤ 0.01` или `|debt − |Σ|| ≤ 0.01`; среди domain-совпадений ровно один `invKey` на `ciusCnKey`; номер не `suspicious_inv`.

**Действие:** `link` на этот `invKey`. Текст помечает `pmt_blns_same_cn` и cidutKey сверки.

**Кейс smoke:** pm=60 · cius=**1224** · «6714» / cn 2330 · Σ = debt 5 536 204,57 → inv **79701**.

### `sum_same_cn` (2026-09-08)

**Зачем:** при заглушке номера в Excel (`Б/С`, `б/н`) тот же долг часто уже есть в `DbtValue` / слоте на **том же** договоре под «нормальным» № СФ (другая выгрузка). Совпадение только по номеру даёт ложный **create** и дубль.

**Условие:** `sumsNew` или `sumsOld` — ровно одно совпадение с исполнителем Excel на cn очереди (или варианте номера), и у hint item заполнен `invKey` (для new: `DbtValue → invDbt.idInv`).

**Действие:** `link` на этот `invKey`, не create. Текст помечает возможную перенумерацию / заглушку.

**Кейс:** upl 901 · `СГМ14-234` / Excel `Б/С` · сумма 1 091 312,07 ↔ DV upl 910 · inv `25/01/92/01-716-ГР` на cn 1312.

**Link + алиас номера (2026-09-08):** `linkSfDoubleToCn` при отличии номера Excel от уже известных `invNum` целевого СФ добавляет Excel-номер как второй `ags.invNum` (без смены `inv.iNum`). Иначе после «Связать» на договоре остаётся только старый номер (`25/01/92/…`), а `Б/С` из кандидата не появляется.

## UI

- Панель «Сообщения» под Excel-кандидатом: `[советник]`
- Кнопка **«Связать с договором Excel»** (positive) при `action=link`
- Кнопка **«Создать СФ по Excel»** (positive) при `action=create` + `confidence=high`, иначе outline
- `recommendInvKey` → auto-select строки в «Счета-фактуры»
- «Связать» вызывает `linkSudzSfDoubleToCn(ciusKey, recommendInvKey, recommendCnKey)`

## Нормализация номеров договора (cn_num_variant)

Сравнение без учёта регистра и лишних пробелов; суффикс через `/` (`711113884` ↔ `711113884/ярэс`).

## UAT @ upl 902

- 161–163 (`711113…` / `…/ЯРЭС`): **link / high** (cn_num_variant + sum)
- 164 (`158` / «Соглашение №2»): **create / high**
