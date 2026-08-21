# КСДСФ · вкладка «Суммы» · старая структура (`cn_inv_dbt`)

**Экземпляр:** верхняя половина вкладки «Суммы» на `sudz-sf-double`  
**JSON:** [`src/trees/ksdsf-cid-sum.tree.json`](../../../../code/femsq-frontend-q/src/trees/ksdsf-cid-sum.tree.json)  
**Корень данных:** `cn_inv_dbt.cn_inv_dbt_key` выбранной строки **верхней таблицы сумм**  
**Правила:** [relation-tree.md](./relation-tree.md) · план S68 sums (chat-plan 26-0802)  
**Сосед:** [ksdsf-dv-sum.tree.md](./ksdsf-dv-sum.tree.md) (новая структура)

Верхняя таблица сумм — не часть дерева: кандидаты по `ABS(dbt_ttl − cidutDebt) ≤ ε`. Здесь один корень — выбранный `cn_inv_dbt`.

Цель дерева: от суммы **подняться к СФ** и сразу увидеть **все номера** этого `inv` и **все договоры** (`cnInv` → `cn` → номера/стороны).

## Карта

- `1. cn_inv_dbt` (корень)
  - Заголовок: `cn_inv_dbt_key`, `number`, `dbt_ttl`
  - Деталь: даты, `dbt_overd`, `debt_type`, `doc_base`, …
  - Дети:
    - `1.1. cnInvAccnt` (`cid.cia`, N:1)
      - Заголовок: `ciaKey`, `ciaName`
      - Дети:
        - `1.1.1. cnInvAccntSmpl` (`cia.cias`, N:1)
          - Заголовок: `ciasKey`, `ciasAccnt`
          - Дети:
            - `1.1.1.1. cnInv` (`cias.cnInv`, N:1) — связь, через которую висит долг
              - Заголовок: `ciKey`, `ciCn`, `ciInv`
              - Дети:
                - `1.1.1.1.1. inv` (`cnInv.inv`, N:1) — **СФ**
                  - Заголовок: `iKey`, `iTimeOfEntry`
                  - Дети (раскрытие СФ — приоритет v1):
                    - `1.1.1.1.1.1. СФ, номера` (папка `inv.invNum`, 1:N)
                      - строки `invNum`: `inKey`, `inNum`, `inInv`
                    - `1.1.1.1.1.2. СФ, связи с договорами` (папка `inv.cnInv`, 1:N)
                      - строки `cnInv` → `cn` → `cnNum` / `cn_s` / org (ветка как на вкладке «СФ», без долгов вниз)
                - `1.1.1.1.2. cn` (`cnInv.cn`, N:1) — договор этой связи суммы
                  - Заголовок: `cn_key`, `cnMark`, `cn_date`
                  - Дети: `cn.cnNum`, `cn.cn_s` → smpl → orgId → og (как в ksdsf-inv-num)

## Рёбра, которых ещё нет в каталоге (добавить перед T)

| Ребро | card | join |
|---|---|---|
| `cid.cia` | N:1 | `cid.cidCnInvAccntCtpt` → `cia.ciaKey` |
| `cia.cias` | N:1 | `cia.ciaCnInvAccntSmpl` → `cias.ciasKey` |
| `cias.cnInv` | N:1 | `cias.ciasCnInv` → `cnInv.ciKey` |
| `inv.invNum` | 1:N | `invNum.inInv` → `inv.iKey` |

Уже есть: `cnInv.inv`, `cnInv.cn`, `inv.cnInv`, `cn.cnNum`, `cn.cn_s`, … `og.orgId`.
