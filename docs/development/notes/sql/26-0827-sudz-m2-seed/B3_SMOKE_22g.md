# B3 / 22g — регресс после 22f + C1 (2026-08-30)

**JAR:** 0.1.0.231-SNAPSHOT · **upl:** 910

## P2a (лаунчер / КСДД)

| Метрика | Baseline 2026-08-26 | После 22f+22g |
|---------|---------------------|---------------|
| `CnInvUplInvDbtDouble` open | 133 | **0** |
| `DbtValue` upl 910 | 1628 | **1755** |
| `DbtValue` без `invDbtDbt` upl 910 | — | **0** (C1 apply 705 мостов) |

## P2e (отчёты)

| Проверка | Результат |
|----------|-----------|
| REST `GET /api/v1/sudz/d644.xlsx?yr=901&currUpl=903` | ✅ HTTP 200 (~4.9K) |

## C1 UAT upl 910

| | |
|--|--|
| `applyDbtUplInvDbtDbtEnsure` | f1=**0**, newDbt=**705**, bridges=**705**, ambiguous=**0** |
| Повторный snapshot | missing=**0** |

## Вывод

КСДД 22f закрыт (open=0). C1 calm: все calm-слоты upl 910 получили `invDbtDbt`. D644 не сломан.
