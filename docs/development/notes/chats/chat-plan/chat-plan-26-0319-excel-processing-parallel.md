# План работы: Excel-конвейер в ревизии (параллельная разработка, af_type=2/3/5/6)

**Дата создания:** 2026-03-19  
**Проект:** FEMSQ  
**Версия плана:** 0.7.0  
**Цель:** Реализовать параллельный конвейер переноса Excel → staging (`ags.ra_stg_*`) → доменные таблицы для всех активных типов файлов (`af_type=2,3,5,6`) с минимизацией type-specific кода на ранних этапах.

---

## Ссылки

- **Архитектура процессоров файлов / технические решения:** `docs/development/notes/analysis/ra-audit-file-processor-architecture.md`
- **Анализ VBA / оригинальная логика:** `docs/development/notes/analysis/ra-audit-btnAuditRun-analysis.md`
- **VBA-исходник AllAgents:** `docs/project/proposals/vba-analysis/VBA-Code-Export/Class-Modules/ra_aAllAgents.cls`
- **VBA-исходник формы:** `docs/project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_ra_a.cls`

---

## Зафиксированный scope по `af_type`

| `af_type` | ft_name | Статус |
|-----------|--------|--------|
| 1 | отчёты агента | УСТАРЕВШИЙ — не реализовывать (пропуск с логом) |
| 2 | хранение оборудования и стройконтроль | В работе: `CnPrDocAuditFileProcessor` |
| 3 | аренда земли | В работе: `RalpAuditFileProcessor` (2 листа) |
| 4 | агентское вознаграждение | УСТАРЕВШИЙ — не реализовывать (пропуск с логом) |
| 5 | отчёты всех агентов | В работе: `AllAgentsAuditFileProcessor` |
| 6 | 23-0627_агентское вознаграждение | В работе: `AgFee2306AuditFileProcessor` |

---

## Что считается техническим “каркасом” (вынесено в архитектуру)

Все решения по:
- иерархии процессоров и template method lifecyle,
- модели доступа к файлу (`af_name` / `af_temp_path`),
- декларативному маппингу колонок (`ra_sheet_conf`, `ra_col_map`),
- staging-таблицам (`ags.ra_stg_*`) и их naming,
- двум стадиям заполнения staging и месту computed/derived полей,

описаны в `ra-audit-file-processor-architecture.md` и **не дублируются** здесь.

---

## Фаза 0: Подготовительные правки (общие для всех типов)

**Цель:** подготовить сервис к асинхронной обработке и корректному разрешению файла.

### 0.1. Apache POI
- Добавить зависимость `org.apache.poi:poi-ooxml` в `femsq-web/pom.xml`
- Проверить отсутствие конфликтов (`mvn dependency:tree`)

### 0.2. Async для `executeAudit`
- Добавить `@EnableAsync` / `@Async` в `AuditExecutionServiceImpl.executeAudit`
- Проверить, что GraphQL mutation возвращает ответ немедленно

### 0.3. Резолв пути файла + пропуск устаревших типов
- `resolveFileAccess()` реализовать по модели из архитектуры (прямой / загрузка)
- В `switch(file.getAfType())` добавить явные `case 1, 4`:
  - log `WARN`
  - пропуск без открытия Excel

---

## Фаза 1: Liquibase/DDL для staging и маппинга колонок (один раз)

**Цель:** обеспечить полностью воспроизводимую схему на любых окружениях.

### 1.0. JPA/DAO слой для конфигурации маппинга и сессий
- Создать JPA-сущности `RaSheetConf`, `RaColMap` и репозиторий `AuditColumnMappingRepository`
- Обновить хранение статуса исполнения: `AuditExecutionRegistry` → `ra_execution` (через `RaExecutionDao`)

### 1.1. `ra_execution`
- Хранение статуса/изоляция запуска ревизии

### 1.2. staging-таблицы
- `ags.ra_stg_ra`
- `ags.ra_stg_cn_prdoc`
- `ags.ra_stg_ralp`
- `ags.ra_stg_ralp_sm`
- `ags.ra_stg_agfee`

### 1.3. `ra_sheet_conf` и `ra_col_map`
- Таблицы **должны быть доступны через DBHub/SQL Server**
- Данные для типов `2/3/5/6` должны быть загружены в `ra_col_map` и `ra_sheet_conf`

> Примечание: в текущей ветке схема и данные уже присутствуют на сервере, но в этом плане требуется добавить Liquibase `changeSet` (runOnChange="false") для воспроизводимости.

---

## Фаза 2: Общая Excel-инфраструктура (`audit.excel`)

**Цель:** дать общий набор компонентов чтения Excel без type-specific “ручной магии”.

### 2.1. Компоненты
- `AuditExcelReader` (`withWorkbook`)
- `AuditExcelColumnLocator` (якорь + headers по `ra_col_map`)
- `AuditExcelCellReader` (typed reads: String/Date/Int/Decimal)
- `AuditExcelException`

---

## Фаза 3: Stage 1 (Excel → staging) — параллельно по типам

**Цель:** заполнить staging-таблицы полностью результатом Excel:
- Stage 1 прямой перенос данных по `ra_col_map`
- context поля (`*_exec_key` и т.п. по соглашению из архитектуры)
- **без** reconcileWithDb и без вычислений derived, которые логически относятся к Stage 2.

### 3.1. Реализовать `AuditStagingService` (generic)
- Схема вызовов:
  - найти лист(ы) и anchor row по `ra_sheet_conf`
  - собрать `Map<stgCol, excelColIdx>` по `ra_col_map` с приоритетами `rcm_xl_hdr_pri`
  - итерировать строки данных
  - batch-INSERT в staging-таблицу

### 3.2. Wire-up в процессоры
- `AllAgentsAuditFileProcessor` (type 5) → `ags.ra_stg_ra`
- `CnPrDocAuditFileProcessor` (type 2) → `ags.ra_stg_cn_prdoc`
- `RalpAuditFileProcessor` (type 3):
  - `Аренда_Земли` → `ags.ra_stg_ralp`
  - `учет_аренды` → `ags.ra_stg_ralp_sm`
- `AgFee2306AuditFileProcessor` (type 6) → `ags.ra_stg_agfee`

---

## Фаза 4: Stage 2a/2b (FK и derived/computed) — параллельно по типам

**Цель:** довести staging-данные до формы, пригодной для `reconcileWithDb()`.

### 4.1. Type 5
- no-op (данные уже готовы для reconcile)

### 4.2. Type 2
- FK resolution по текстовым полям staging

### 4.3. Type 3
- FK resolution по текстовым полям staging
- Java computation derived-поля (пример: `ralprtStatus` через три флага)

### 4.4. Type 6
- FK resolution по текстовым полям staging
- соблюсти guard: `ctx.auditType == 1` (как в архитектуре)

---

## Фаза 5: reconcileWithDb (staging → домен) — параллельно по типам

**Цель:** перенести данные из staging-таблиц в доменные таблицы согласно логике VBA.

### 5.0. Достать Access SQL-логику сверки и адаптировать под staging
- Для каждой операции сверки взять соответствующие SQL-определения/логики из Access (см. `ra-audit-btnAuditRun-analysis.md`)
- Адаптировать под источники staging (т.е. вместо `ra_ImpNew` — использовать `ags.ra_stg_*`)
- Реализовать как SQL Server VIEW/SQL в DAO (вариант: через Liquibase)

Параллелизм:
- можно делать reconcile для каждого типа после готовности Stage 1–4 для этого типа.

Ожидаемые deliverables:
- Type 5: 8 операций сверки `ra_aAllAgents.Audit()` → перенос в `ags_ra` / `ags_ra_change`
- Type 2: reconcile по VBA `RAAudit_cn_PrDoc`
- Type 3: reconcile по VBA `RAAudit_ralp` (2 листа)
- Type 6: reconcile по VBA `RAAudit_AgFee_Month` + `ra_aAgFee23_06.Audit`

---

## Фаза 6: Сборка и ручная проверка

### 6.1. Сборка
- `npm run type-check`
- `mvn ... package` (fat JAR)

### 6.2. Ручная проверка (минимальный чек-лист)
- Запустить JAR для ревизии с `af_type=2,3,5,6`
- Убедиться, что UI не зависает (`@Async` работает)
- Проверить через DBHub:
  - staging-таблицы заполнены
  - записи привязаны к правильному `*_exec_key`
- Проверить: при `af_source=false` staging не загружается (лог отражает счётчики)
- Проверить: при `af_source=true` и `addRa=true` доменные таблицы получают новые/обновлённые данные

---

## Что остаётся за рамками этого плана

- `ra_aTtl` (итоговые суммы ревизии) — отдельный шаг: очистка и заполнение таблиц итогов
- `ra_aTtl` / итоговые агрегаты не включены в reconcile типов 2/3/5/6
- Типы `1` и `4` (устаревшие) — пропуск с логом

---

## Последнее обновление

**Дата:** 2026-03-19
**Версия:** 0.7.0

