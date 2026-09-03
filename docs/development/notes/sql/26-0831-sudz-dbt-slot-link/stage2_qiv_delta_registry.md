# Stage2 QIV — реестр дельт: воронка 901 vs Access Rslt (variant B)

**Дата создания:** 2026-09-01  
**lastUpdated:** 2026-09-01  
**Статус:** черновик — пополняется по мере разбора групп A/B  
**Связь:** chat-plan [S76](../../chats/chat-plan/chat-plan-26-0802-sudz.md#s76--rslt-stage2-qiv-дельта-воронка-901-vs-access-variant-b-2026-09-01)

---

## 1. Контекст

| Параметр | Значение |
|----------|----------|
| Год / yr | 900 (variant 2025) |
| Upl QIV (FEMSQ) | **901** (`2026-01-15`) |
| Excel свода | `Дт Задолженность на 31.12.2025 (Общий свод).xlsx` |
| Tbl после excelToTbl | **1764** строк |
| DbtValue после apply | **1769** → после диагностики **1773** |
| Эталон Rslt | `ags_Yr_DbtChangesRslt_26-0212_26-0217.xlsx` |
| Access QIV asOf | **2026-01-30** (колонки `2026-01-30_Ttl` / `_Overd` / `_погашено`) |
| QIII | **вне scope** (колонки в эталоне игнорируются) |

**Важно:** PASS QIV от **2026-08-31** (`artifacts/stage2_qiv_verify_26-0831.json`) получен после **ручных SQL-правок**. Это доказательство «можем воспроизвести эталон оператора», но **не** gate «воронка из одного Excel без вмешательства».

---

## 2. Две группы

### Группа A — исправляется в коде загрузки

**Цепочка:** `excelToTbl` → … → `invDbtLoad` → `DbtValue@901` → `vw_Yr_DbtFact` → Rslt export.

**Критерий закрытия:** повторный apply воронки на upl 901 (или копии) **без** ручных DELETE/UPDATE/SEED → сверка QIV проходит.

**Зона кода:** `JdbcSudzDao.applyInvDbtLoad`, `rebuildInvDbtDoubleQueue`, CTE `calmOne` / `f1One` / `histInvDbtMulti`.

### Группа B — вне загруженного Excel / вне приложения

**Суть:** строки есть в **Access Rslt**, но **нет** в `CnInvDbtUplTbl@901` (и часто нет в DEV `ags.cn_inv_dbt`).

**Критерий закрытия:** для каждой строки — источник найден (другой файл, ручная правка Access, prod upl) **или** зафиксирован как **manual overlay** с суммой и основанием; FEMSQ не обязан воспроизводить без явного решения владельца.

---

## 3. Четыре явления — сводная таблица

| ID | Явление | Группа | Δ Ttl (ориентир) | Подгонка 31.08 | Направление fix |
|----|---------|--------|------------------|----------------|-----------------|
| **P1** | Дубли Value на sibling-слотах | A | +~2,79 млрд (inflated) | DELETE 4 dvKey | A1: один Value на iKey@upl |
| **P2** | 9240 / 90621 суммы QIV ≠ Tbl | A?/B? | +~10,75 млн net | UPDATE 2 Value | Forensics + политика asOf |
| **P3** | 9 строк 762210 QIV-only | B (data gap) | −592,89 млн (missing) | **не использовать B-seed** | Разрыв Excel X vs upl 901 |
| **P4** | `732` vs `732 от 10.01.24` | A | погашено +6,996 млн | INSERT/DELETE | A2: exact invNum |

---

## 4. Группа A — кейсы (детально)

### P1 — sibling duplicate Values

**Симптом:** одна строка Tbl (один `iKey`, одна сумма) попадает в **несколько** `DbtValue` на **разные** `invDbt` одного `iKey` (sibling-слоты: `idNum` 1, 2, …; L*, ciaName).

**Не путать с легитимным multi-slot:** у `iKey` 12032 / 12033 на 901 — **7** и **5** Values с **разными** `dvTtl` (несколько долгов на одной СФ в Tbl). Это **не** P1; Rslt схлопывает L* в одну строку, но суммы в БД различаются.

**Примеры P1 (901 до fix):**

| iKey | inv (СФ) | слоты с Value@901 | ttl | hist 801–803 | dbtKey | действие fix |
|------|----------|-------------------|-----|--------------|--------|--------------|
| 6760 | 28469 | 3398, 3399 | 2 733 213 421,80 ×2 | 3398=3, 3399=0 | **3398, 3399** (разные) | DELETE 3399 |
| 12032 | А19-16343/2021 | 4398 + hist-слоты | 186 961,48 ×2 на 4398/4405 | 4398=0, 4399+=hist | разные | DELETE 4398 |
| 329 | 0519CR0004 | 42, 43 | 7 454 ×2 | 42=3, 43=0 | разные | DELETE 43 |
| 5130 | 3616 CR 0005 | 2030, 2031 | 800,91 ×2 | 2030=0, 2031=3 | разные | DELETE 2030 |

**Отдельный подтип P1b (7454):** две строки Value с одной суммой, но на **разных** `iKey` (91571 / 91572) — не sibling, а **двойное разрешение EIA** на одну Tbl-строку. Лечится в очереди ambiguous / exact invNum, не только A1.

#### Механизм (подтверждено по коду)

Дублирование — **двухфазное**:

| Фаза | Шаг воронки | Что происходит |
|------|-------------|----------------|
| **1** | `invDbtLoad` → `insertValueF1` | Для `histInvDbtMulti` calm отключён; F1 находит слот с совпадением суммы в **истории** `DbtValue` (не обязательно на 801–803). Для 6760 — слот **3398** (hist=3). Проверка только `NOT EXISTS Value ON **этом** slot@upl`. |
| **2** | `dbtValueLoad` → `applyDbtValueLoadTail` | CTE `tailReady`: слоты с мостом `invDbtDbtVar`, **без** Value@curr, при **любой** Tbl-строке по `iKey`. Для 6760 — слот **3399** (`varCnt=1`), та же сумма из Tbl. Снова только `NOT EXISTS` на **своём** slot. |

Ключевой фрагмент tail (`JdbcSudzDao.applyDbtValueLoadTail`, ~3648):

- `FROM tailReady` — перебор **всех** sibling-слотов с мостом;
- `WHERE e.iKey = d.idInv` — привязка к СФ, **не** к конкретному слоту;
- нет условия «у sibling уже есть Value@upl с той же суммой».

**Почему calm не виноват для 6760:** `calm` исключает `histInvDbtMulti`; у 6760 два `invDbt` → только F1 + tail.

**Δ QIV:** четыре кейса same-ttl sibling ≈ **+2,79 млрд** inflated (6760 доминирует).

#### Ограничения на уровне БД — разбор

| Предложение | Статус | Эффект на P1 | Комментарий |
|-------------|--------|--------------|-------------|
| `UNIQUE(dvInvDbt, dvUpl)` | **уже есть** (`UX_DbtValue_InvDbtUpl`, M2) | один Value на **слот**@upl | Запрос пользователя по invDbt **выполнен** |
| `UNIQUE(dbtKey, dvUpl)` / `UX_DbtValue_DbtUpl` | **снято в M2** (колонка `dvDbt` удалена) | ловит L* с **общим** canonical `Dbt` | **Не** ловит 6760: `iddDbt` 3398 ≠ 3399. Можно вернуть **триггером** через `invDbtDbt` |
| `UNIQUE(iKey, dvUpl)` | нет | заблокировал бы P1 | **Сломает** 12032/12033 (легитимно несколько разных сумм на одной СФ) |
| Триггер «no sibling same ttl» | **рекомендуется** (черновик) | блокирует 6760, 329, 5130, дубль L* same sum | Не трогает multi-slot с разными ttl |
| Триггер «one Value per iKey@upl если Tbl rowCnt=1» | опционально, сложнее | точное правило A1 | Нужен доступ к `CnInvDbtUplTbl` / `#sudzEia` в триггере или материализованный признак |

**Рекомендуемый пакет DDL (черновик `11_TRIGGER_DbtValue_no_sibling_dup.sql`):**

1. **Оставить** `UX_DbtValue_InvDbtUpl` без изменений.
2. **Добавить** в `trg_DbtValue_Consistency` (или отдельный `trg_DbtValue_NoSiblingDupTtl`):
   - при INSERT/UPDATE: если существует другой `DbtValue` на том же `dvUpl`, другом `invDbt` того же `idInv`, и `ABS(dvTtl₁ − dvTtl₂) ≤ 0.01` → `RAISERROR`.
3. **Опционально** — `trg_DbtValue_OnePerDbtUpl` через join `invDbtDbt`: не более одного Value@upl на `iddDbt` (защита L*-canonical; не заменяет п.2).
4. **Не вводить** `UNIQUE(iKey, dvUpl)` без фильтра по Tbl.

**Trade-off триггера same-ttl:** теоретически два sibling с **намеренно одинаковой** суммой и двумя Tbl-строками — отклонение; таких кейсов в реестре 901 нет → отправлять в `invDbtDouble` queue.

#### Изменения кода (A1) — приоритет

| # | Где | Что |
|---|-----|-----|
| A1.1 | `applyDbtValueLoadTail` / `tailReady` | Исключить slot, если sibling того же `idInv` уже имеет Value@upl (при `tblIKey.rowCnt=1` — жёстко; при `rowCnt>1` — только если ttl совпадает ±0.01) |
| A1.2 | `insertValueF1` | Перед INSERT: `NOT EXISTS` Value@upl у **любого** sibling; приоритет слота: MAX(hist upl 801–803) → `DbtSlotLink` canonical → MIN(idKey) |
| A1.3 | `insertValue` (calm) | Аналогичная проверка sibling (на будущее, если calm попадёт в multi-slot) |
| A1.4 | Gate SQL | `99_VERIFY_qiv_stage2.sql`: same-ttl sibling count = 0; отдельно — отчёт multi-slot legit (разные ttl) |
| A1.1b | `tailCand` + `rnPick=1` | batch-safe tail; `isSingleTailRetry` для шага `dbtValueLoad` |

**Черновик gate (same-ttl sibling):**

```sql
SELECT d.idInv AS iKey, dv.dvUpl,
       COUNT(DISTINCT dv.dvInvDbt) AS slot_cnt,
       COUNT(DISTINCT CAST(dv.dvTtl AS decimal(19,2))) AS ttl_variants
FROM sudz.DbtValue dv
INNER JOIN sudz.invDbt d ON d.idKey = dv.dvInvDbt
WHERE dv.dvUpl = @upl
GROUP BY d.idInv, dv.dvUpl
HAVING COUNT(DISTINCT dv.dvInvDbt) > 1
   AND COUNT(DISTINCT CAST(dv.dvTtl AS decimal(19,2))) = 1;
-- ожидание: 0 строк
```

**Статус разбора:** ☑ механизм; ☑ fix в коде (`JdbcSudzDao` A1) + DDL `11_TRIGGER_…`; ☐ UAT на чистом apply  
**Ответственный шаг:** S76-A.1

---

### P4 — partial invNum match (`732`)

**Симптом:** Tbl содержит `732 от 10.01.24` (6 996 220,93); в Rslt Access QIV Ttl/Overd пусто, но **погашено** = 6 996 220,93 (долг исчез из QIV при сохранении base Overd). FEMSQ ошибочно создал Value на inv **`732`** (hist=0) вместо слота **`732 от 10.01.24`** (slot 8898, hist=3).

| Поле | Access (r≈512) | FEMSQ до fix | FEMSQ после fix (clean apply 26-0901) |
|------|----------------|--------------|----------------------------------------|
| inv | `732 от 10.01.24` | Value на `732` | Value на **8898** (`732 от 10.01.24`) |
| QIV Ttl | 6 996 220,93 (все периоды) | NULL | **6 996 220,93** |
| QIV погашено | NULL | 6 996 220,93 (ошибка) | NULL |

**Гипотеза:** `invDbtVarEnsure` / F1 сопоставил Tbl с укороченным `invNum` вместо exact match с hist-слотом.

**Предлагаемые изменения кода (A2):**

1. Exact `invNum` > prefix/substring при F1 и calm.
2. Если Tbl.`cidutCnInv` = полная строка и есть `invNum` с hist — не создавать новый inv.
3. Post-apply: anti-join Tbl → Value@U (отчёт «Tbl без Value»).

**A2.1 (var label vs entity) — реализовано 2026-09-01:**

1. **A2.1a** — `invPick` в `invDbtVarEnsure`: текст Tbl на `z.iKey`, не hist-ranking.
2. **A2.1b** — `insertInvNumAliasesFromEia`: alias `ags.invNum` при rename в Excel.
3. **A2.1c** — `CnCtptExistInvNotLoad`: alias вместо нового `ags.inv` при hist-sibling.
4. **A2.1e** — gate `99_VERIFY_qiv_stage2.sql`: для каждого Value@upl существует Tbl-строка с `cidutCnInv = var.inNum` (NOT EXISTS; без cross-sibling ложных пар).
5. Data-fix: `13_FIX_a21_732_invDbtVar.sql` (legacy; clean apply 244 — не требуется).

**Статус разбора:** ☑ A2 + A2.1; clean apply JAR **244** — slot **8898**, var **`732`**, gate **A2.1e=0** (исправлена семантика gate 26-0901)

---

### P2 — 9240 / 90621 (смешанный A/B)

**Симптом:** в Tbl@901 суммы **как в base–QII** эталона; в Access **QIV** — выше.

| inv | acc | Tbl@901 | Access QIV | base–QII (оба) |
|-----|-----|---------|------------|----------------|
| 9240 | 767502 | 53 759 277,17 | 64 511 132,60 | 53 759 277,17 |
| 90621 | 767502 | 2 500 000,00 | 3 000 000,00 | 2 500 000,00 |

**Гипотезы:**

- **B:** оператор обновил суммы в Access между 15.01 и 30.01 вне повторной загрузки свода.
- **A (слабая):** воронка должна была взять другой источник — противоречит канону E1′ (membership Tbl).

**Действия S76-B.2:**

1. VBA / SQL Rslt: откуда QIV Ttl при base=QII≠QIV.
2. Prod `ags.cn_inv_dbt`: факты между датами upl.
3. Решение владельца: эталон = Tbl **или** Access Rslt на 30.01.

**Статус разбора:** ☐  
**Ответственный шаг:** S76-B.2 (после A)

---

## 5. Группа B — кейсы (детально)

### P3 — девять строк Access QIV-only (~592,89 млн) — **разрыв входных данных**

**Класс:** группа B — **не баг воронки** при каноническом Excel upl 901. FEMSQ воспроизводит `excel/2025-12/debit/…31.12.2025 (Общий свод).xlsx`; Access Rslt QIV построен из **другого** набора строк.

#### Гипотеза «выгрузка X» (2026-09-01)

| Утверждение | Статус |
|-------------|--------|
| Существовала исправленная выгрузка **X** на **31.12.2025**, не архивированная на шаре | **не подтверждено** (X не найдена среди 35 `.xlsx` на шаре) |
| X содержала **9** долгов P3 и была QIV-2025 / base-2026 для оператора | **правдоподобно**, **8/9** косвенно подтверждены |
| `…31.03.2026 (Общий свод) -НОВЫЙ.xlsx` — **QI 2026**, не X; лишь **корроборация** 8 строк | **подтверждено** (точное совпадение org/cn/inv/ttl) |
| **105449** был в X, погашен ≈31.12.2025 → отсутствует в QI/QII excel | **правдоподобно**, **не доказано** без X |

**Почему 9, а не 8:** в Access QIV у **105449** срок погашения **31.12.2025**, overd=0; в QI/QII «НОВЫЙ» svod строки **нет** (ни `15-ЗБС/21-АС`, ни 110 642,38). В `ags_Yr_DbtChangesRslt_26-0505` при этом **base=110 642,38** — carry-forward из QIV. Контраргумент: у **105450** тот же maturity 31.12.2025, но строка **есть** в QI — правило «mat → выпадение» не универсально.

#### Таблица сверки источников

| dbtKey | QIV Ttl | OLD 31.12.2025 | QI НОВЫЙ 31.03.2026 | QII НОВЫЙ 30.06 (762210) | Rslt_26-0505 base |
|--------|---------|----------------|---------------------|--------------------------|-------------------|
| 6884 | 89,63M | нет | **да** | нет | 89,63M |
| 105449 | 0,11M | нет | нет | нет | **0,11M** |
| 105450 | 2,25M | нет | **да** | нет | 2,25M |
| 105451–105455 | 488,01M | нет | **да** (5 строк) | нет | да (5 строк) |
| 105456 | 12,89M | нет | **да** | нет | 12,89M |

**Канон upl 901:** `excel/2025-12/debit/…31.12.2025 (Общий свод).xlsx` — **0/9** P3-сумм.

**Корроборация:** `excel/2026_03/debit/…31.03.2026 (Общий свод) -НОВЫЙ.xlsx` — **8/9** (1:1 с Access по inv/ttl). Частичный лист: `26-0526_Головинова/762210 на 31.03.2026.xlsx` — **6/9** сумм.

#### Реестр строк (эталон Access `Rslt_26-0212`)

| access_dbtKey | acc | inv | org | QIV Ttl | QIV Overd | в Tbl@901 (OLD excel) | в QI НОВЫЙ |
|---------------|-----|-----|-----|---------|-----------|------------------------|------------|
| 6884 | 762210 | б/н | 1009345 | 89 633 019,16 | 0 | нет | **да** |
| 105449 | 762210 | б/н | 1255867 | 110 642,38 | 0 | нет | нет |
| 105450 | 762210 | б/н | 1143509 | 2 247 973,63 | 0 | нет | **да** |
| 105451 | 762210 | 06/44-3185 | 1009345 | 150 551 722,96 | =ttl | нет | **да** |
| 105452 | 762210 | 06/44-4194 | 1009345 | 253 324 136,00 | =ttl | нет | **да** |
| 105453 | 762210 | 06/44-4562 | 1009345 | 18 021 646,00 | =ttl | нет | **да** |
| 105454 | 762210 | 06/44-5561 | 1009345 | 54 250 324,36 | =ttl | нет | **да** |
| 105455 | 762210 | 06/44-5788 | 1009345 | 11 857 862,74 | =ttl | нет | **да** |
| 105456 | 762210 | Б/С | 1009345 | 12 892 753,24 | 0 | нет | **да** |
| | | | | **592 890 080,47** | | | **8/9** |

**Манифест (gate, не данные БД):** [p3_data_gap_manifest.json](./p3_data_gap_manifest.json)

#### Политика (2026-09-01)

- **Не** применять `10_SEED_access_q4_missing_9.sql` и любые синтетические INSERT в `Tbl`/`DbtValue`.
- Если B-seed уже накатывался — откат: `12_RESET_upl901_clean_apply.sql`.
- Искать **X** у оператора / prod (архив 15–30.01.2026, FishEye.ags, почта).
- До появления X: сверки сумм с полным Access Rslt — **с documented exclusion** P3 (≈592,9M на QIV@901).

**Статус разбора:** ☑ источник = разрыв Excel (OLD vs Access); X — TBD; B-seed **отменён** как стратегия  
**Ответственный шаг:** S76-B.3 (получить X); S76-G tiered gate (§7.4)

**Скрипт `10_SEED_access_q4_missing_9.sql`:** **deprecated** — только исторический артеfact подгонки 31.08; **не cutover**.

---

## 6. Подгонки 2026-08-31 (инвентарь)

| Действие | Тип | Группа | Комментарий |
|----------|-----|--------|-------------|
| DELETE dvKey 85105, 85106, 85103, 85104 | data fix | A → код A1 | sibling duplicates |
| UPDATE 9240, 90621 | data fix | B? | ждёт forensics |
| DELETE dvKey 85095 (7454 duplicate) | data fix | A → код A1 | |
| `10_SEED_access_q4_missing_9.sql` | synthetic seed | B | **deprecated — не применять** |
| INSERT Value slot 8898; убрать `732` | data fix | A → код A2 | |

---

## 7. Целевые gate (черновик)

### 7.1 `verify_qiv_excel_only` (строгий)

- Вход: Tbl@901 + apply воронки **без** ручных SQL / B-seed.
- Сверка: Rslt QIV vs Access **только** по строкам, присутствующим в Tbl.
- Ожидание: **PASS** (полное совпадение на пересечении). P3 в Access **вне** Tbl — не дефект.

### 7.2 `verify_qiv_full_access` (UAT с оператором)

- Полное совпадение base–QI–QII–QIV с эталоном.
- Требует: код A закрыт **и** documented overlay **или** полный исходник Excel.

### 7.4 Tiered gate — upl 901 / 902 / 903 (без имитаторов данных)

| Tier | Имя | upl | Что проверяет | Ожидание при data gap P3 |
|------|-----|-----|---------------|--------------------------|
| **T0** | SQL invariants | все | A1 sibling, A2.1e, UX | **PASS** (код) |
| **T1** | `verify_qiv_excel_only` | 901 | GEN vs Access **только** строки из Tbl@901 | **PASS** (полное совпадение на пересечении) |
| **T2** | `verify_qiv_full_access` | 901 | Полный multiset QIV | **FAIL** Δ ttl ≈ **−592,9M** — **ожидаемо** до X |
| **T2′** | `verify_qiv_full_access` + manifest | 901 | T2 минус строки [p3_data_gap_manifest.json](./p3_data_gap_manifest.json) | Δ → ≈ P2 (+ шум); **не** замена X |
| **T3** | Stage1 base–QI–QII | 902, 903 | Срезы до QIV | Частичный FAIL: Access **base@902** уже carry-forward P3 из QIV (`Rslt_26-0505`), FEMSQ — нет без X@901 |
| **T4** | Forward excel | 902+ | Tbl из QI/QII «НОВЫЙ» svod | **8/9** могут войти через excel@902; **105449** (~0,11M) — gap без X |

**Практика до получения X:**

1. **Exit code** по **T0 + T1** на каждом upl (код воронки).
2. **T2** — informational; в отчёте явно: `expected_data_gap_p3=592890080.47`.
3. **902/903:** не требовать PASS T2 по полному Access без manifest; отдельно отслеживать **105449** и P2.
4. После получения X — **перезагрузить upl 901** (или cutover-скрипт из реального Excel), затем T2 без manifest.

### 7.5 Компактный формат листа 606012 (QII, без шапки)

**Симптом:** лист `606012` в `…30.06.2026 (Общий свод) -НОВЫЙ.xlsx` — **без строки заголовков**; данные с row 1; колонки C–L сдвинуты относительно полного формата (901/902).

| Полный (901/902) | Компактный QII (903) |
|------------------|----------------------|
| C=Контрагент, E=№, F=Договор, H=СФ | C=№, D=Контрагент, E=Договор, F=СФ |
| D=ИНН, G=Дата договора | **отсутствуют** |

**Решение (JAR ≥247):** `excelToTbl` — авто-детект сигнатуры (`A1=D`, `B1=имя листа`, …) + фиксированная карта колонок (`SudzDbtUplExcelCompactLayout`). Не data gap; ~1172 строки на upl 903.

### 7.3 SQL-контроли после apply

```sql
-- A1: same-ttl sibling duplicates → 0 (см. §4 P1)
-- A1b: UX_DbtValue_InvDbtUpl — уже enforced
-- A3: Tbl rows without Value@901
-- см. будущий 99_VERIFY_qiv_stage2.sql, 11_TRIGGER_DbtValue_no_sibling_dup.sql
```

---

## 8. Порядок разбора в чате (согласовано)

1. **S76-A** — P1 (sibling), P4 (732), релевантные аспекты P2 в коде.
2. **S76-B** — P3 (9 строк), P2 (источник сумм 9240/90621).
3. **S76-G** — скрипты verify + повтор apply без SQL.

---

## 9. Связанные файлы

| Файл | Назначение |
|------|------------|
| `verify_rslt_stage1.py` | gate stage1 (не QIV) |
| `artifacts/stage2_qiv_verify_26-0831.json` | PASS после подгонки |
| `p3_data_gap_manifest.json` | manifest P3 для tiered gate (не данные БД) |
| `10_SEED_access_q4_missing_9.sql` | **deprecated** — не применять |
| `README.md` | пакет 26-0831 |

---

## 10. Журнал обновлений

| Дата | Изменение |
|------|-----------|
| 2026-09-01 | Черновик реестра; секция S76 в chat-plan |
| 2026-09-01 | P1: корневая причина (F1 + tail); предложения по DB constraints |
| 2026-09-01 | P1: реализованы A1 в JdbcSudzDao, `11_TRIGGER_…`, `99_VERIFY_qiv_stage2.sql` |
| 2026-09-01 | A1.1b tailCand; clean apply 901: base–QII OK, QIV Δ≈−790M (P3/P2/очередь) |
| 2026-09-01 | P4 A2: clean apply 901 — Tbl `732` → slot 8898 / `732 от 10.01.24`, gate A2=0 |
| 2026-09-01 | P4 A2.1: var label per upl — QI–QII `732 от 10.01.24`, QIV `732`; код + gate A2.1e |
| 2026-09-01 | **JAR 244** clean apply (4:23): funnel ≤5 мин; **S76-G gate FAIL** — QIV Δ ttl **−789,8M**; A1/A1b=0; A2.1e (старый gate)=230; multiset extras=1277 missing=2296 |
| 2026-09-01 | **A2.1e закрыт:** gate NOT EXISTS (без cross-sibling); clean apply 901 → **0**; код A2.1a–c подтверждён |
| 2026-09-01 | **P3 forensics:** гипотеза выгрузки X; 8/9 в QI НОВЫЙ; B-seed deprecated; [p3_data_gap_manifest.json](./p3_data_gap_manifest.json); tiered gate §7.4 |
| 2026-09-01 | **P3 B-seed (отменено):** эксперимент 26-0901 — не стратегия cutover |
