# §3.2.6 Smoke ИП A — apply load8 → ipg27

**Дата:** 2026-11-25  
**Задача:** 0081  
**Стенд:** `FishEye_prod_noM6`  
**Пилот:** load **8** / ipg **27** / stNet **5** / `sql_0.xlsx`

## Критерии DoD (короткий)

| Проверка | Ожидание | Факт |
|----------|----------|------|
| `ipgPn` count | = листьям staging (398) | **398** |
| `ipgStPn` count | = pn (каждый пункт со sti) | **398** |
| unique `(ipg,cstAgPn,sh)` | 0 нарушений | **0** |
| `ipgpSh` | без prev → все 4 | **398×4** |
| pn без sti | 0 | **0** |
| staging codes ↔ domain | 1:1 | **0 missing / 0 extra** |
| `ttl` mismatch | 0 | **0** |

## Суммы (ipg27)

| Поле | Σ |
|------|--:|
| `ipgpSmTtl` | 1 058 838.09 |
| `ipgpSmWrk` | 743 709.99 |
| `ipgpSmEqu` | 240 933.69 |
| `ipgpSmOth` | 74 194.41 |

## Вывод

Пилот A закрыт по данным: bulk apply (§3.2.4) + сверка (§3.2.6) OK.  
UI «Загрузить пункты» (§3.2.5) — для оператора / B–D после догрузки `cstAgPn`.
