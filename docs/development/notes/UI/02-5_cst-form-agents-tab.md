# UI Access: форма `cst`, вкладка «агенты»

**Дата:** 2026-07-23  
**Источник:** скриншоты Access (dark/light), VBA-экспорт, DDL `ags.*` (DBHub)  
**План:** [chat-plan-26-0722-forms-ia-cst.md](../chats/chat-plan/chat-plan-26-0722-forms-ia-cst.md)  
**Скриншоты:** [26-0723-cst-agents-dark.png](../assets/cst-forms/26-0723-cst-agents-dark.png), [26-0723-cst-agents-light.png](../assets/cst-forms/26-0723-cst-agents-light.png)

---

## 1. Каркас формы `cst`

| Зона | Содержимое |
|------|------------|
| Master (сверху, на всю ширину) | Грида `cstName` + `cstKey`; фильтр; длинные имена читаются горизонтально |
| Контекст | Полоса полного `cstName` выбранной строки (под master) |
| Detail | Вкладки (см. §2) |
| Вкладка «агенты» | **Дерево** агент → САК → филиал с multi-expand (как nested datasheet Access) |

**FEMSQ (2026-07-23):** master сверху (не боковой список); контролы flat/dense по Design chrome (без filled primary).

**Связь смены записи:** как в VBA `Form_Current` — при смене `cst` перезагружается detail (агенты и др.).

---

## 2. Вкладки (по светлому скрину, надёжнее)

1. **агенты** (изучена)  
2. отчёты  
3. отчёты, аренда  
4. инвестпрограммы  
5. общее  
6. освоение  
7. график, всего  
8. график, виды  

Остальные вкладки — **вне MVP** до отдельных скринов/RecordSource.

---

## 3. Вкладка «агенты» — иерархия 3 уровней

```text
cst (master)
 └── cstAg          — агент на стройке (1:N)
      └── cstAgPn   — САК / код пункта ИП (1:N)
           └── cstAgPnBranch — филиал + период (1:N)
```

| Уровень | Access-колонки на экране | Домен SQL | Примечание |
|---------|--------------------------|-----------|------------|
| 0 Master | `cstName`, `cstKey` | `ags.cst` | RecordSource `ags_cst`; Order By `cstName`; Add/Edit/Delete=Да |
| 1 | `cstaKey`, `cstaAg`, `cstaCst`, … | `ags.cstAg` | RecordSource — SELECT полей `cstAg`; Link: `cstaCst`↔`cstKey`. **Combo `cstaAg`:** Row Source `ags_ogAgCs` (bound=ogaKey) |
| 2 | `cstapKey`, `cstapCsta`, `cstapIpgPnN`, … | `ags.cstAgPn` | RecordSource — SELECT полей `cstAgPn`; Order By `cstapIpgPnN`; Link: `cstapCsta`↔`cstaKey` |
| 3 | `cstapbKey`, `cstapbBranch`, `cstapbCstAgPn`, `cstapbStart`, `cstapbEnd` | `ags.cstAgPnBranch` | RecordSource — все поля таблицы. **Combo `cstapbBranch`:** `SELECT ogKey, ogNm FROM ags_og ORDER BY ogNm` |

Проверка dev: `cstKey=3321` → `cstaKey=1445`, `ogaCode=049` — совпадает со скрином «049 Газпромтранс…».

**Источники Access (2026-07-23), вкладка «агенты»:**

```sql
-- Master
-- RecordSource: ags_cst  (Order By cstName)

-- L1 RecordSource
SELECT cstaKey, cstaAg, cstaCst, cstaOidOld FROM ags_cstAg;
-- L1 Combo cstaAg Row Source: ags_ogAgCs  (ogaKey, ogaNm = code+' '+name)

-- L2 RecordSource
SELECT cstapKey, cstapCsta, cstapIpgPnN, cstapOidOld FROM ags_cstAgPn;
-- Order By: cstapIpgPnN

-- L3 RecordSource
SELECT cstapbKey, cstapbCstAgPn, cstapbBranch, cstapbStart, cstapbEnd
FROM ags_cstAgPnBranch;

-- L3 Combo cstapbBranch
SELECT ogKey, ogNm FROM ags_og ORDER BY ogNm;
```

На экране datasheet L1 колонка «cstAg» — подпись из `ogAgCs`; колонка «cstKey» в datasheet-режиме часто показывает **`cstaKey`**.

---

## 4. Достаточно ли для Java?

| Область | Достаточно? | Комментарий |
|---------|-------------|-------------|
| Layout master–detail + вкладки | ✅ | Скрины + паттерн Organizations |
| Данные уровня 1–3 вкладки «агенты» | ✅ | DDL полный; join агента через `ogAg` |
| Фильтр/поиск master | ✅ | как `cstCol` / Organizations |
| GraphQL MVP (чтение) | ✅ | списки + дерево по `cstKey` |
| Точная подпись агента (`код + имя`) | ✅ | Combo `cstaAg` → **`ags_ogAgCs`** (не просто `og`) |
| Lookup названия филиала (`cstapbBranch`) | ✅ | Combo → `ags_og` (`ogKey`/`ogNm`) |
| RecordSource L1 / L2 | ✅ | `ags_cstAg` / `ags_cstAgPn` (поля как в SELECT оператора) |
| CRUD / правила ввода | ✅ | Решение оператора 2026-07-23: **CRUD сразу** (как в Access: Allow Add/Edit/Delete=Да) |
| Остальные вкладки | ❌ | Только имена; без RecordSource/скринов содержимого |
| Форма `cstAgPn` (отдельная) | ✅ | Режим TopBar «САК (cstAgPn)»: список кодов слева + тот же каркас `cst` справа; GraphQL `cstAgPnCodes` |

**Вывод:** для **MVP экрана Стройки = форма `cst` + вкладка «агенты»** данных достаточно; **CRUD включён в MVP** (2026-07-23). Остальные вкладки — stub.

---

## 5. Рекомендуемый MVP Java (фаза C, уточнение)

1. Список `cst` + карточка имени.  
2. Вкладки: «агенты» рабочая; прочие — disabled/stub.  
3. Дерево/вложенные таблицы: `cstAg` → `cstAgPn` → `cstAgPnBranch`.  
4. TopBar «Стройки» ▾: «Стройки (cst)» и «САК (cstAgPn)» (фильтр Like по коду → выбор → каркас `cst`).
