# План: FemsqTable на устаревших гридах (org / цепочки / ревизии)

**Дата создания:** 2026-11-17  
**Последнее обновление:** 2026-11-17  
**Проект:** FEMSQ  
**Версия плана:** 0.3.0  
**Статус плана:** ✅ completed  
**Задача:** [0093](../../../project-development.json)  
**Дорожная карта:** [chat-plan-26-1116-roadmap-r1.md](./chat-plan-26-1116-roadmap-r1.md) — хвост после docs-sync блок 5; продолжение манифеста [02-8](../../UI/02-8_femsq-table-component.md) (фаза C)  
**Автор:** Александр  

> **Зачем.** После удаления доменного REST (docs-sync блок 5) UI org / цепочек / ревизий работает через GraphQL, но гриды всё ещё на сыром Quasar `QTable`/`QList`/`q-table`. Эталон — `FemsqTable` из feQuLib (договоры, стройки, СУДЗ).

---

## 0. Цель

1. Перевести табличные списки экранов **Организации**, **Инвестиционные цепочки**, **Ревизии (файлы + список)** на `FemsqTable`.
2. Убрать ad-hoc фильтры там, где их закрывает chrome FemsqTable; сохранить server-пагинацию org/цепочек.
3. Обновить манифест потребителей в `02-8_femsq-table-component.md`.
4. Удалить мёртвый `AuditsView.v68.backup`.

**Критерий закрытия:** три экрана без `QTable`/`q-table` в списках данных; импорт `fequlib`; type-check / vitest зелёные по затронутым тестам; манифест обновлён; план `completed`.

**Не входит:** визуальный контракт feQuLib §8 / 0011 (бэклог R1 §6); деревья FemsqTree/WalkTree; native Rslt preview.

---

## 1. Дерево работ

Легенда: ☐ · 🔶 · ✅

```text
1. FemsqTable на legacy-гридах                                    🔶
│
├─ 1.1 Задача 0093 + реестр планов + журнал                        ✅
├─ 1.2 OrganizationsView: master + ids + names + agents            ✅
├─ 1.3 InvestmentChainsView: master + relations                    ✅
├─ 1.4 AuditsView список + FilesList таблица; удалить .v68.backup ✅
├─ 1.5 Манифест 02-8 + тесты                                       ✅
└─ 1.6 Закрытие плана                                              ✅
```

### Закрытие (2026-11-17)

Выполнено: org / цепочки / audits list + FilesList на `FemsqTable`; `AuditsView.v68.backup` удалён; манифест 02-8 обновлён; vitest 90/90. Диалоги остаются на `QCard`. Визуал feQuLib §8 / 0011 — по-прежнему бэклог R1 §6.

---

## 2. Решения

| # | Решение |
|---|---------|
| 1 | Master org/цепочек — `mode="server"` + `@request` → существующие store page/sort/filter |
| 2 | Detail/relations/files/agents — `mode="client"` (малые наборы) |
| 3 | Диалоги на `QCard` оставляем (не гриды) |
| 4 | Год цепочек — внешний `QInput` (нет в chrome FemsqTable) |

---

## 3. Журнал правок

| Дата | Версия | Что изменили |
|------|--------|----------------|
| 2026-11-17 | 0.3.0 | План закрыт: миграция + тесты 90; задача 0093 completed |
| 2026-11-17 | 0.2.0 | Код: org / цепочки / audits+FilesList на FemsqTable; backup удалён |
| 2026-11-17 | 0.1.0 | Создан план; старт миграции |
