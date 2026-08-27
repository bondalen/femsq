# P1 — инвентарь зависимостей `dvDbt` (B1-prep)

**Дата:** 2026-08-26  
**Контекст:** S72 B1-prep; план [chat-plan-26-0802-sudz.md §S72](../../chats/chat-plan/chat-plan-26-0802-sudz.md)  
**Цель:** полный реестр того, что сломается при DROP `DbtValue.dvDbt`, и куда смотреть в P2/P4–P6.

---

## 1. Физика БД (DEV Docker)

### 1.1. Таблицы с колонкой `dvDbt`

| Схема | Таблица | Constraints (факт) | Строк (2026-08-26) |
|-------|--------|--------------------|--------------------|
| `sudz` | `DbtValue` | `dvDbt` NOT NULL; FK `FK_DbtValue_Dbt` → `sudz.Dbt`; UNIQUE `(dvDbt, dvUpl)` | **16** |
| `test_sudz` | `DbtValue` | зеркало (старый DDL) | **16** |

Нет колонки `dvInvDbt` (M2 ещё не накатан).

### 1.2. Объекты, в определении которых есть литерал `dvDbt`

| Схема | Объект | Тип | Действие при B1 |
|-------|--------|-----|-----------------|
| `sudz` | `trg_DbtValue_Consistency` | TRIGGER | **заменить** на §4.1 M2 (без `dvDbt`, с `dvInvDbt` + мост var) |
| `test_sudz` | `trg_DbtValue_Consistency` | TRIGGER | то же |
| `sudz` | `vw_Yr_DbtFact` | VIEW | **пересоздать**: `dbtKey` через `invDbtDbt` (LEFT JOIN); `DbtUplCstAg` по `dbtKey`, не `dv.dvDbt` |
| `test_sudz` | `vw_Yr_DbtFact` | VIEW | то же |

### 1.3. Косвенные зависимости (читают `vw_Yr_DbtFact.dbtKey`, не `dvDbt` напрямую)

| Схема | Объект | Тип | После rewrite view |
|-------|--------|-----|--------------------|
| `sudz` / `test_sudz` | `Yr_DbtChanges_mini` | PROCEDURE | **не трогать**, если колонка `dbtKey` сохранится |
| `sudz` / `test_sudz` | `Yr_DbtChangesD644` | PROCEDURE | то же |
| `sudz` / `test_sudz` | `Yr_DbtChangesD644Svod` | PROCEDURE | то же |
| `sudz` / `test_sudz` | `vw_Yr_DbtChanges_mini_2026` | VIEW | то же (через fact) |

### 1.4. Связанные таблицы (колонки не `dvDbt`, но join в view)

| Таблица | Колонка | Замечание |
|--------|---------|-----------|
| `sudz.DbtUplCstAg` | `ducaDbt` | FK на `Dbt`; в текущем `vw_Yr_DbtFact` join `duca.ducaDbt = dv.dvDbt`. После M2: join на выводимый `dbtKey` из `invDbtDbt`. **DDL таблицы не менять в B1.** |

### 1.5. Вне scope B1 (ложное/legacy совпадение)

| Объект | Почему не трогаем |
|--------|-------------------|
| `ags.tr_InsteadOfInsert` на `ags.invDbtValue` | Старая пустая таблица; совпадение по тексту `dvDbt` в модуле — **не** `sudz.DbtValue` |

---

## 2. Код приложения (прямые ссылки на `dvDbt`)

### 2.1. Backend

| Файл | Использование | Baseline (P2) | Патч (P6) |
|------|---------------|---------------|-----------|
| `code/.../JdbcSudzDao.java` | `findNewSumMatches`: `SELECT … dvDbt`; hints `sumsNew`: `JOIN invDbtDbt ON iddDbt = dv.dvDbt` | P2b, P2c | → `dvInvDbt`; `dbtKey` через `invDbtDbt` / LEFT JOIN |
| `code/.../SudzSfDoubleNewSumMatch.java` | поле `dvDbt` | P2b | → `dvInvDbt` + опц. `dbtKey` |
| `code/.../graphql/sudz-schema.graphqls` | `SudzSfDoubleNewSumMatch.dvDbt` | P2b | схема API |
| `code/.../RelationEdgeCatalog.java` | колонка folder `dvDbt`; рёбра `dbt.dv`, `dv.dbt` | P2d | M2: связь Value↔Dbt **через** `invDbt`/`invDbtDbt`, не прямой FK |

Косвенно (через view, без `dvDbt` в Java):

| Файл | Объект БД |
|------|-----------|
| `JdbcSudzDao.java` | `vw_Yr_DbtFact`, `Yr_DbtChangesD644`, `Yr_DbtChangesD644Svod` |
| `SudzExportRestController.java` / Excel exporters | Rslt / D644 / Svod |

### 2.2. Frontend

| Файл | Использование | Baseline | Патч |
|------|---------------|----------|------|
| `src/types/sudz.ts` | `dvDbt` | P2b | |
| `src/api/sudz-api.ts` | query field `dvDbt` | P2b | |
| `src/views/sudz/SudzSfDoubleView.vue` | колонка/маппинг `dvDbt` | P2b, P2c | |
| `src/trees/ksdsf-dv-sum.tree.json` | edge `dv.dbt` | P2d | |
| `src/trees/ksdsf-inv-num.tree.json` | edge `dbt.dv`, folder `DbtValue` | P2d | |

---

## 3. SQL-скрипты в репозитории (документация / повторный seed)

Прямой `dvDbt` в тексте (обновление → **B2**, не блокер apply B1 на живой БД):

| Пакет | Файлы |
|-------|--------|
| `26-0807-sudz-target-schema/` | `07_CREATE_TABLE_DbtValue.sql`, `09_SEED_dbt_82_85_Q4Q1Q2.sql`, `12`/`13`/`15` (view fact), `17_SEED_yr_2025_5slices_S45.sql` |
| `26-0807-sudz-test-schema/` | зеркала тех же имён |

---

## 4. Карта риска → baseline / пакет B1

| Риск при DROP `dvDbt` без подготовки | Митигация |
|--------------------------------------|-----------|
| Триггер INSERT/UPDATE Value | B1: `03_TRIGGER` |
| Rslt / D644 / Svod SQL error | B1: `04_VIEW` + smoke P2e |
| КСДСФ «Суммы · new» / hints | P6 JAR сразу после B1; baseline P2b/c |
| RelationTree `dv.dbt` | P6 каталог + JSON; baseline P2d |
| Повторный seed из git | B2 |
| Очередь `invDbtLoad` / слой I | **не** зависит от `dvDbt` (контроль P2a) |

---

## 5. Критерий закрытия P1

- [x] Реестр БД + код + скрипты собран  
- [x] Косвенные proc/view отмечены  
- [x] Legacy `ags.invDbtValue` исключён из scope  
- [x] Ссылка из плана B1-prep P1  

**Статус P1:** ✅ 2026-08-26  
**Next:** **P2** (baseline прогоны P2a–P2e).
