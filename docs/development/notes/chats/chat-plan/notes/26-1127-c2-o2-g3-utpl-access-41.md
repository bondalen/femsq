# C2 O2 §4.1 — Access G3 UtPl: UI → VBA → migrate

**Дата:** 2026-11-27 · **Задача:** 0081 · **План:** §4.1  
**Статус:** ✅ инвентарь + решение migrate  
**Контракт:** [26-1127-c2-o2-utpl-lim-contract.md](./26-1127-c2-o2-utpl-lim-contract.md)  
**UI Access (скрины):** [screenshots …/2026-1123-ipg-forms](./screenshots-26-1120-access-ui/2026-1123-ipg-forms/README.md)  
**Справочник затрат (процесс A):** [stcost-structure-40](./26-1127-c2-o2-stcost-structure-40.md) ✅  
**Принцип migrate:** как [§2.3](./26-1120-c2-migrate-1-1.md) — Access = сценарии/семантика, не UX/VBA-шаблон

---

## 1. Что видит оператор (Access UI)

Карточка ИП (`ipg` / визуально `ipgMin`):

| Зона | Вкладки / подформы | Смысл |
|------|-------------------|--------|
| Master под шапкой | `группы планов` · `планы` · `загрузка ут. планов` | G3 / G2: группы, заголовки планов, LdM |
| Деталь пункта (низ) | `планы` · `лимиты` · `пункты структуры` · `общее` | UtPl по выбранному `ipgPn`; лимиты года; StPn |

Иерархия контролов (имена Access, `>` = вложенность):

```text
ipg
 ├─ ipg>UtPlGr_t / …>P_t     группы планов + состав (агентские планы)
 ├─ ipg>UtPl_t               список ipgUtPl (фильтр по текущей ИП)
 ├─ ipg>LdM_*                загрузка Excel → UtPlP (G2, не этот шаг)
 ├─ ipg>Pn_t                 грид пунктов
 │    └─ ipg>Pn_t>UtPlP_t    заголовки уточн. плана по пункту (VBA Filter)
 └─ ipg>Pn_f                 карточка пункта
      ├─ ipg>Pn_f>UtPlPnLmYe / Qu / Mn   лимиты/планы Ye/Qu/Mn × stCost
      ├─ ipg>Pn_f>Lim_*                  годовые лимиты пункта (ipgPnLim)
      └─ ipg>Pn_f>StPn                   структура ИПГ (уже в FEMSQ Leaves)
```

**Наблюдение со скринов:** вкладки G3 на `ipgMin` есть; при Load полной `ipg` подтягиваются Ye/Qu/Mn — причина тормозов. FEMSQ уже принял lazy (не грузить на open).

Скрин G3 **не обязателен** для закрытия §4.1, если достаточно design-имён + bound RecordSource + VBA экспорта; доп. скрин «лимиты»/`LmMn` — nice-to-have перед §4.2 UI.

---

## 2. VBA / запись (факт экспорта)

| Объект | Код | Поведение |
|--------|-----|-----------|
| `Form_ipg>Pn_t>UtPlP_t` | **есть** | `Form_Current`: фильтрует sibling-подформы Ye/Qu/Mn по `iuplpKey` (`iuplpyPlPn` / `iuplpqPlPn` / `iuplpmPlPn`) |
| `ipg>Pn_f>UtPlPnLm*` · `ipg>UtPl*` · `…Lim_*` | **bound**, модулей в экспорте почти нет | CRUD через Access bound → `ags.*` |
| Класс `ipgPnLim` | тонкий DAO | Таблица `ags_ipgPnLim`; поля `ipgplPn`, **`ipgplStCost`**, `ipgplLim`; геттер `stCost` |
| Класс `stCost` | справочник | Используется из `ipgPnLim` / UI затрат |

**Вывод:** бизнес-логика G3 в Access — в основном **bound forms + фильтр Current**, не сложный VBA. Переносить нужно **семантику таблиц и навигацию оператора**, не `ClassFunc` / FilterOn.

Связь план ↔ пункт: `ipgUtPlP.iuplpIpgPn` → `ipgPn`; заголовок ↔ план агента: `iuplpPl` → `ipgUtPl`.  
Группа на цепи: `ipgChRl.ipgcrUtPlGr` / `_2606.ipgcrvUtPlGr` (не на файле Monf).  
Состав группы: `ipgUtPlGrP` (`iuplgpGr`, `iuplgpPl`).

---

## 3. Канон хранения (noM6)

| Таблица | Ключевые поля | Роль |
|--------|---------------|------|
| `ipgUtPl` | `iuplIpg`, `iuplAg`, `iuplNm` | План агента на ИП (**комбо §4.2: `iuplIpg` = текущая**) |
| `ipgUtPlGr` / `ipgUtPlGrP` | gr ↔ pl | Группа для `_2606` |
| `ipgUtPlP` | `iuplpPl`, `iuplpIpgPn`, `iuplpLim`, `M01…M12`, `Q*` | Заголовок; широкие M/Q = семантика **212** (legacy) |
| `ipgUtPlPnLmMn` | `iuplpmPlPn`, **`iuplpmStCost`**, `iuplpmMn`, `iuplpmLim` | **Канон** месяц × stCost |
| `ipgUtPlPnLmYe` / `Qu` | … + `StCost` | Год/квартал × stCost (часто производные) |
| `ipgPnLim` | `ipgplPn`, **`ipgplStCost`**, `ipgplLim` | Год × stCost на пункте (G-ip) |

Факт DEV: в `ipgUtPlPnLmMn` доминируют **212/195/172/187** (десятки тысяч строк); есть хвост прочих `stcKey` — UI §4.2 **не** ограничивать жёстко четырьмя ключами на чтении, но **канон ввода O2** = тройка+212 (контракт).

**Процесс B:** в строку пишется только `stcKey`, **без** выбора cost-net (сетка — справочник §4.0).

---

## 4. Матрица migrate (G3 / P2 1.3)

Легенда: **P** перенести · **U** упростить · **A** Access до R1 · **X** вне O2 / позже

| Возможность Access | Решение | Как в FEMSQ (§4.2) |
|--------------------|---------|-------------------|
| Список `ipgUtPl` текущей ИП | **P+U** | Query filter `iuplIpg`; lazy на Leaves |
| CRUD заголовка `ipgUtPlP` (Lim + опц. широкие M*) | **P+U** | GraphQL; широкие M* — опционально/legacy; авторитет — LmMn |
| CRUD `ipgUtPlPnLmMn` (месяц × stCost) | **P** | **Основной** редактор; DoD A+B+G-agg (контракт) |
| Просмотр/правка Ye/Qu | **U** | Не три bound-грида; Q/Y — производные / read или редкий edit |
| CRUD `ipgPnLim` (год × stCost) | **P** | На карточке пункта; seed/сверка G-ip |
| Группы `ipgUtPlGr` + `GrP` | **P+U** | Отдельный блок; привязка группы к цепи — на Chains (`ipgcr*UtPlGr`) |
| FilterOn sibling-форм по Current | **X** | Один Apollo state / parent key |
| VBA-класс `ipgPnLim` | **U** | Java service по полям таблицы |
| Выбор cost-net на плане | **X** | Нет (только `stcKey`) |
| Excel LdM | **X** здесь → **§6** | G2; не закрывает ось C |
| Филиал multi | **X** | Решение 013 |
| Полный clone Access-вкладок | **X** | Один блок «Планы/лимиты» на Leaves |

---

## 5. Рекомендуемый UX FEMSQ (вход в §4.2)

1. Leaves / карточка ИП → вкладка **Планы** (lazy).  
2. Комбо **план агента** (`ipgUtPl` where `iuplIpg` = текущая).  
3. Выбор **пункта** (`ipgPn`) → грид **месяц × stCost** (`LmMn`) + итог 212/части.  
4. Год: `ipgPnLim` / `LmYe` рядом; AggAxis при save.  
5. Группы планов — вторичный экран или секция; цепь задаёт `UtPlGr` для `_2606`.

DoD записи — контракт §3 (FemsqMoney + AggAxis + G-agg).  
Не дублировать Access: три подформы Ye/Qu/Mn + Filter.

---

## 6. DoD §4.1

1. ✅ Инвентарь UI вкладок/подформ G3.  
2. ✅ VBA: только sync Filter + класс `ipgPnLim`; запись = bound → таблицы.  
3. ✅ Матрица migrate для §4.2.  
4. ☐ (опц.) скрин вкладки «лимиты»/`LmMn` с данными — не блокер старта GraphQL.

---

## 7. Next

**§4.2** — GraphQL + UI LmMn / UtPlP (+ группы); DoD A+B+G-agg; комбо `iuplIpg`=текущая.
