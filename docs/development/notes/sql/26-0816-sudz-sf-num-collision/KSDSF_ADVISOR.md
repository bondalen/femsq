# КСДСФ — советник (S68+)

**Дата:** 2026-09-02  
**Зеркало:** [KSDD_ADVISOR.md](../26-0827-sudz-m2-seed/KSDD_ADVISOR.md) (сегм. 22c)

## API (GraphQL)

| Query | Назначение |
|-------|------------|
| `sudzSfDoubleAdvice(ciusKey, epsilon)` | блок `[советник]` в «Сообщения» |
| `sudzSfDoubleHints(ciusKey, epsilon)` | кнопки выбора строк (как раньше) |

## Советник — проверки v1

| check | Рекомендация |
|-------|--------------|
| `executor_unique` | link (high) — один СФ с номером и исполнителем Excel |
| `cn_exact` | link (high) — один такой СФ на договоре Excel |
| `cn_homonym` | create (high) — однофамильцы на **несвязанном** договоре |
| `cn_num_variant` | link на **канонический** cn (где уже inv), не на cn очереди |
| `cn_num_alias` | inv уже на cn «711113884/ЯРЭС» → добавить «711113884» как второй cnNum; удалить дубль cn из воронки |
| `executor_none` | create (high) — нет СФ с номером и исполнителем Excel |
| sum unique + один СФ на cn | link (medium) |
| иначе | manual |

`confidence`: high | medium | low | none. Не заменяет первичку.

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
