# Инвентарь зерна RC (`ra_change`) — узел 1.4.2.1

**Дата создания:** 2026-11-19  
**Последнее обновление:** 2026-11-19  
**Статус:** ✅ выполнен (инвентарь; решение модели — 1.4.2.2+)  
**Стенд:** `FishEye_prod_noM6`  
**План:** [chat-plan-26-1117-release-r1x.md](../../chats/chat-plan/chat-plan-26-1117-release-r1x.md) §1.4.2.1  
**Контекст:** [01-oa-signs-and-presentations.md](./01-oa-signs-and-presentations.md)

---

## 1. `ags.ra_change` — ключи и индексы

| Индекс | Unique | Колонки | Смысл |
|--------|--------|---------|--------|
| `PK_ra_change` | да | `rac_key` | суррогат |
| **`ЗаПериодЗаОтчётОдинНомер`** | **да** | **`ra_period`, `raс_ra`, `raс_num`** | натуральное зерно: период **изменения**, FK на базу, № изменения |
| `IX_ra_change_rac_ra` | нет | `raс_ra` | поиск по базе |

Кириллическая «с» (U+0441) в именах `raс_ra`, `raс_num`, `raс_date` — как в коде `AllAgentsReconcileService`.

На строке изменения лежат **и** идентичность, **и** жизненный цикл рассмотрения: `ra_arrived` / `ra_arrived_date` / `ra_sent` / `ra_returned` / … — **одна** тройка статусов на `rac_key`.

Связь с базой: FK на `ags.ra` (`raс_ra` → `ra_key`). База сама уникальна по `НомерОтчётаОдинЗаПериод` = `(ra_period, ra_num)`.

---

## 2. `ags.ra_change_summ` — версии сумм

| Индекс | Unique | Колонки |
|--------|--------|---------|
| `PK_ra_change_summ` | да | `raсs_key` |

Других unique-индексов **нет** (несколько версий на одно изменение допустимы).

| Колонка | Роль |
|---------|------|
| `raсs_raс` | FK → `ra_change.rac_key` (`FK_ra_change_summ_ra_change`) |
| `raсs_total` / `_work` / `_equip` / `_others` | суммы |
| `raсs_date` | дата версии |
| `racs_fdKey` | FK → `factDoc` (стек `_2606`) |

**Статистика noM6 (2026-11-19):** изменений с ≥1 суммой **1857**; ровно 1 версия — **1810**; **≥2 версий — 47**; максимум версий на одно изменение — **7**.

Уже есть механизм **эволюции сумм** без смены `rac_key`; **нет** механизма нескольких жизненных циклов (писем/СЗ) на одно зерно UX.

---

## 3. Представления «последней» суммы

### `ags.ra_chSmLt`

`MAX(raсs_date)` по `raсs_raс`, затем join обратно на `ra_change_summ`.  
Reconcile type=5 читает домен RC через `LEFT JOIN ra_chSmLt` (`AllAgentsReconcileService.loadDomainRcChangeRows`).

### `ags.RRcTimeList` (ветка «изм.»)

Аналогично: latest sum по `MAX(raсs_date)` на `raсs_raс`; `typeGr` от `ra.ra_type` базы; `complianceY` — совпадение года периода изменения и периода базы.

И отчёт освоения (`fn2` / `_2605`/`_2606`), и UI/сверка опираются на **одну** «текущую» сумму на `rac_key`.

---

## 4. Mastering (`fnMasteringRa*_2606`)

Носитель изменения в set-based ядре: `carrierKey = rac_key`, `isChange = 1`.

- Отбор: все `ra_change` ⋈ `ra` по `ra_cac` (стройка); **фильтра `ra_type` нет**.
- Сумма/стоимость: latest `ra_change_summ` по `(raсs_date DESC, raсs_key DESC)` → `racs_fdKey` → `factDocCost` / `fnStCostFromFd_2606`.
- Статусы pres/accp/ret/… — с **полей строки** `ra_change` (arrived/sent/returned), не с дочерней Au.

Итог: mastering видит **один** носитель на зерно UX и **одну** latest-сумму; несколько представлений с разными письмами в текущей схеме **некуда** положить.

---

## 5. Сопоставление в reconcile (Java)

| Шаг | Ключ |
|-----|------|
| Поиск базы | `(ra_period базы, ra_num)` → `ra_key` |
| Поиск/insert RC | `RcChangeMatchKey` = **`(ra_period изменения, ra_key, № изм.)`** ≡ колонки UX |
| NEW | `INSERT ra_change` + одна версия `ra_change_summ` |
| CHANGED | `UPDATE` полей жизненного цикла на той же строке; новая версия сумм только при отличии от latest |

Натуральный ключ кода **совпадает** с UX: второе представление с тем же № в том же периоде на ту же базу → либо 2601, либо «ambiguous» в read-model, если бы в БД уже было две строки (UX это запрещает).

---

## 6. Образец РАЛП (для 1.4.2.2)

| Таблица | Unique зерно | Что хранит |
|--------|--------------|------------|
| `ralpRa` | (логика FindRalpRa) | отчёт аренды |
| `ralpRaAu` | **`(ralpraRa, ralpraArrived)`** (`IX_ralpRaAu`) | **одно представление** (письмо поступления + даты СЗ/возврата) |

Несколько подходов = несколько Au на один `ralpRa`. У RC аналога Au **нет**: письмо поступления — колонка на `ra_change`.

---

## 7. Факт по блокеру apply (уточнение зерна)

Ключ ошибки apply: `(ra_period, rac_ra, rac_num) = (229, 113328, 2)`.

На `FishEye_prod_noM6` **после** отката TX такой строки в `ra_change` **нет** → конфликт был **внутри одного apply** (две NEW-строки Excel с одним зерном), а не «вторжение» в уже существующую запись.

---

## 8. Выводы → скетч 1.4.2.2

1. **Узкое место — строка `ra_change`:** UX + поля рассмотрения 1:1.  
2. **Суммы уже версионны** (`ra_change_summ`); этого недостаточно для истории писем/СЗ.  
3. **Потребители** (`ra_chSmLt`, `RRcTimeList`, `fnMasteringRa*`, reconcile) завязаны на `rac_key` + latest sum.  
4. **Ближайший аналог** мульти-представления — `ralpRaAu` с зерном `(родитель, идентификатор представления)`.  
5. Расширение UX (вариант B) должно явно ответить, куда деваются **разные** `ra_arrived`/`ra_sent` при одном `rac_key`.

**Скетч выполнен:** [04-rc-model-sketch-a-vs-b.md](./04-rc-model-sketch-a-vs-b.md) — рекомендация **A**.

---

## 9. Ссылки на код

- `AllAgentsReconcileService` — `RcChangeMatchKey`, `loadDomainRcChangeRows`, insert/update RC  
- `RalpReconcileService` — match Au по `(ralpraRa, ralpraArrived)`  
- SQL: `MSSQL2012/03b1_…fnMasteringFact_2606.sql` (`fnMasteringRaCostSet_2606` / `RaCostBase`)
