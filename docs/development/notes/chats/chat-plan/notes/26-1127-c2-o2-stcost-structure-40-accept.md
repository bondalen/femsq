# C2 O2 §4.0.3 — приёмка справочника структуры затрат

**Дата:** 2026-11-27 · **Задача:** 0081 · **План:** §4.0.3  
**Статус:** ✅  
**Prep:** [26-1127-c2-o2-stcost-structure-40.md](./26-1127-c2-o2-stcost-structure-40.md)  
**Стенд:** `FishEye_prod_noM6` @ `10.7.0.3` (машина asus-kubuntu / `localhost.localdomain`)

---

## 1. DoD §4.0 (проверка)

| # | Критерий | Результат |
|---|----------|-----------|
| 1 | Справочник: net=**3**, root=**214**, канон 212/195/172/187 с именами | ✅ `fnSt(3,214)` = **88** узлов; рёбра `212→195/172/187` есть |
| 2 | CRUD: сеть/узлы/alias/рёбра (паритет Structure ИПГ) | ✅ DAO smoke `StCostStructureSmokeMain` PASS |
| 3 | UtPl/load **не** требует выбора cost-net | ✅ (контракт процесса B; UI справочника отдельно) |
| 4 | Excel-reconcile затрат не обязателен | ✅ (вне scope) |

### Имена `MIN(stcnKey)` (канон)

| stcKey | stcnNm |
|--------|--------|
| 214 | Реализация инвестпроекта в форме стройки |
| 212 | Всего |
| 195 | СМР |
| 172 | оборудование |
| 187 | Прочие |

**Канон (минимум §4.0.2):** `satisfied` — 212 + linkedParts **3/3** (полный). Допустима и одна составляющая.

---

## 2. Smoke CRUD (cleanup)

Класс: `com.femsq.database.service.StCostStructureSmokeMain`

```bash
cd code/femsq-backend/femsq-database
mvn -q test-compile exec:java \
  -Dexec.mainClass=com.femsq.database.service.StCostStructureSmokeMain \
  -Dexec.classpathScope=test
```

Факт прогона 2026-11-27:

- costNetworks=1 (`stNet=3` «Стандартная» root=214)
- create/rename/addName/detach/delete temp `stc` под 187
- после cleanup: канон 3/3; temp-узел удалён из `stCost`/`stCostNm`/`fnSt`

UI GraphQL на живом JAR в DAO-шаге не гоняли; закрыто доп. UI-прогоном §2a ниже.

---

## 2a. UI-приёмка браузером (операторский сценарий, 2026-11-27)

**Стенд:** Vite `localhost:5175` + `spring-boot:run` `:8080` → `FishEye_prod_noM6`.  
**Инструмент:** Cursor IDE Browser.

| Шаг | Действие | Результат |
|-----|----------|-----------|
| 1 | Подключение (status connected / схема ags) | ✅ |
| 2 | Меню **Инвестиции → Структура затрат** | ✅ экран `CostStructureView` |
| 3 | CardStrip: «Стандартная» `stNet=3 · root=214` | ✅ |
| 4 | Баннер канона | ✅ зелёный «212 = 195+172+187 (полный)» |
| 5 | Дерево `fnSt`: root 214, expand 212… | ✅ 88 узлов |
| 6 | Выбор узла **187** (Прочие); имена aliases | ✅ footer `stcKey=187` |
| 7 | **Дочерний** → `ui-accept-403-temp` → confirm «Правка канона…» → OK | ✅ создан `stc=279` parent=187; дерево 89 |
| 8 | **Удалить узел** → confirm → OK | ✅ cleanup; дерево снова **88**; `stCost` 279 нет |

Замечание: после create footer «Имена» показывал aliases родителя — исправлено (`createChild` → `fetchNodeNames`).

---

## 3. Вердикт

**§4.0 закрыт** (DAO smoke + UI browser). Next: **§4.1** Access G3 UtPl → migrate.
