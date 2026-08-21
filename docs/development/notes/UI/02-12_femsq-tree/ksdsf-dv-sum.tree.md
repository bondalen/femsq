# КСДСФ · вкладка «Суммы» · новая структура (`DbtValue`)

**Экземпляр:** нижняя половина вкладки «Суммы» на `sudz-sf-double`  
**JSON:** [`src/trees/ksdsf-dv-sum.tree.json`](../../../../code/femsq-frontend-q/src/trees/ksdsf-dv-sum.tree.json)  
**Корень данных:** `sudz.DbtValue.dvKey` выбранной строки **нижней таблицы сумм**  
**Правила:** [relation-tree.md](./relation-tree.md) · план S68 sums (chat-plan 26-0802)  
**Сосед:** [ksdsf-cid-sum.tree.md](./ksdsf-cid-sum.tree.md) (старая структура)

Верхняя таблица сумм половины — не часть дерева: кандидаты по `ABS(dvTtl − cidutDebt) ≤ ε`. Корень — выбранный `DbtValue`.

Цель: от величины долга к канону `Dbt`, затем ко всем связанным `inv` (через `invDbtDbt` / `invDbt`) и **раскрыть каждый СФ**: все `invNum` и все `cnInv`→договоры/стороны.

## Карта

- `1. DbtValue` (корень)
  - Заголовок: `dvKey`, `dvTtl`, `dvUpl`
  - Деталь: `dvOverd`, даты, `dvDocBase`, …
  - Дети:
    - `1.1. Dbt` (`dv.dbt`, N:1)
      - Заголовок: `dbtKey`
      - Дети:
        - `1.1.1. Dbt, связи с invDbt` (папка `dbt.idd`, 1:N) — один долг может быть на нескольких СФ
          - строки `invDbtDbt`:
            - Заголовок: `iddKey`, `iddInvDbt`, `iddDbt`
            - Дети:
              - `1.1.1.1.1. invDbt` (`idd.invDbt`, N:1)
                - Заголовок: `idKey`, `idNum`
                - Дети:
                  - `1.1.1.1.1.1. inv` (`invDbt.inv`, N:1) — **СФ**
                    - Заголовок: `iKey`, `iTimeOfEntry`
                    - Дети (раскрытие СФ — приоритет v1):
                      - `СФ, номера` (папка `inv.invNum`, 1:N)
                      - `СФ, связи с договорами` (папка `inv.cnInv`, 1:N)
                        - `cnInv` → `cn` → `cnNum` / `cn_s` / org

## Рёбра, которых ещё нет в каталоге (добавить перед T)

| Ребро | card | join |
|---|---|---|
| `dv.dbt` | N:1 | `dv.dvDbt` → `dbt.dbtKey` |
| `dbt.idd` | 1:N | `idd.iddDbt` → `dbt.dbtKey` |
| `idd.invDbt` | N:1 | `idd.iddInvDbt` → `invDbt.idKey` |
| `invDbt.inv` | N:1 | `invDbt.idInv` → `inv.iKey` |
| `inv.invNum` | 1:N | общее с половиной cid |

Уже есть: `dbt.dv` (обратное к `dv.dbt`), `idd.dbt`, `inv.invDbt`, `inv.cnInv`, ветка `cn`/`cn_s`.

## Замечание по данным DEV

На femsq-mssql для якоря Excel `41666666.67` (`106647`) в `sudz.DbtValue` совпадений может не быть (seed новой модели неполный). Половина UI всё равно нужна: пустая таблица + подпись «нет совпадений» — нормальный UAT-кейс.
