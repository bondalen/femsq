# План работы в чате: Миграция системы ревизий

> 📦 **Архив** (2026-11-17, docs-sync 12.1). Исторический план: статус — `completed` (архив), открытые отметки не ведутся. Текущие цели и бэклог — [дорожная карта R1](./chat-plan-26-1116-roadmap-r1.md).

**Дата создания:** 2026-01-12  
**Проект:** FEMSQ - Миграция функционала ревизий из MS Access  
**Подход:** Пошаговая разработка (step-by-step)

---

## 🎯 Цель

Создать веб-интерфейс для работы с ревизиями Excel-файлов, мигрируя функционал из MS Access в веб-приложение на базе Spring Boot + Vue.js.

---

## 📋 Этап 1: Базовая структура данных и форма ревизий

### ✅ Выполнено

- ✅ Анализ структуры таблиц MS Access
- ✅ Экспорт VBA кода из Access (123 файла .bas/.cls)
- ✅ Изучение формы `ra_a` и связанных таблиц
- ✅ **Создание таблиц в MS SQL Server** ✅ (2026-01-12)
  - ✅ Таблица `ags.ra_at` создана (1 запись: "ревизия отчётов агента")
  - ✅ Таблица `ags.ra_dir` создана (11 директорий для годов 2018-2025)
  - ✅ Таблица `ags.ra_a` создана с FK constraints
  - ✅ SQL скрипты: `01_create_ra_tables.sql`, `02_insert_ra_data.sql`
  - ✅ Индексы настроены (UNIQUE, NONCLUSTERED)
- ✅ **Перенос данных из MS Access в SQL Server** ✅ (2026-01-12)
  - ✅ `ags.ra_at`: 1 запись перенесена
  - ✅ `ags.ra_dir`: 11 записей перенесены
  - ✅ `ags.ra_a`: 8 записей ревизий перенесены (без HTML-результатов)
  - ✅ Создан Python скрипт импорта: `03_import_ra_a_data.py`
  - ✅ Создан bash скрипт: `import_ra_a.sh`

### 📌 Задачи на будущее

**Импорт HTML-результатов ревизий**
- [ ] Импортировать поле `adt_results` для всех 8 ревизий (размер до 180KB каждый)
- [ ] Использовать Python скрипт с pyodbc: `code/config/sql/03_import_ra_a_data.py`
- [ ] Или импортировать через приложение после создания API

### 🔄 В работе

#### 1.2 Создание Java Entity классов

- ✅ Создать `com.femsq.database.model.RaA` (Audit/Revision entity) ✅
- ✅ Создать `com.femsq.database.model.RaAt` (AuditType entity) ✅
- ✅ Создать `com.femsq.database.model.RaDir` (AuditDirectory entity) ✅
- ✅ Настроить маппинг и связи между сущностями ✅ (record классы с валидацией)
- ✅ Создать репозитории (DAO интерфейсы) для каждой сущности ✅
  - ✅ `RaAtDao` - интерфейс для работы с типами ревизий
  - ✅ `RaDirDao` - интерфейс для работы с директориями
  - ✅ `RaADao` - интерфейс для работы с ревизиями

#### 1.3 Backend: REST API

**1.3.1 JDBC реализации DAO**
- ✅ Расширить интерфейс `RaADao` методами `create`, `update`, `delete` для CRUD ✅
- ✅ Создать `JdbcRaAtDao` - реализация для типов ревизий ✅
- ✅ Создать `JdbcRaDirDao` - реализация для директорий ✅
- ✅ Создать `JdbcRaADao` - реализация для ревизий (с полным CRUD) ✅

**1.3.2 Сервисный слой**
- ✅ Создать интерфейсы: `RaAtService`, `RaDirService`, `RaAService` ✅
- ✅ Создать реализации: `DefaultRaAtService`, `DefaultRaDirService`, `DefaultRaAService` ✅
- ✅ Добавить валидацию бизнес-правил ✅

**1.3.3 DTO классы**
- ✅ Создать DTO: `RaAtDto`, `RaDirDto`, `RaADto` ✅
- ✅ Создать Request DTO: `RaACreateRequest`, `RaAUpdateRequest` ✅

**1.3.4 Mapper классы**
- ✅ Создать `RaAtMapper` для преобразования RaAt ↔ RaAtDto ✅
- ✅ Создать `RaDirMapper` для преобразования RaDir ↔ RaDirDto ✅
- ✅ Создать `RaAMapper` для преобразования RaA ↔ RaADto и Request DTO ✅

**1.3.5 REST контроллеры**
- ✅ Создать `RaARestController` с endpoints:
  - `GET /api/ra/audits` - список ревизий ✅
  - `GET /api/ra/audits/{id}` - детали ревизии ✅
  - `POST /api/ra/audits` - создание ревизии ✅
  - `PUT /api/ra/audits/{id}` - обновление ревизии ✅
  - `DELETE /api/ra/audits/{id}` - удаление ревизии ✅
- ✅ Создать `RaAtRestController`:
  - `GET /api/ra/audit-types` - список типов ревизий ✅
- ✅ Создать `RaDirRestController`:
  - `GET /api/ra/directories` - список директорий ✅

**1.3.6 Регистрация в конфигурации**
- ✅ Зарегистрировать DAO бины в `DatabaseModuleConfiguration` ✅
- ✅ Зарегистрировать сервисы в `DatabaseModuleConfiguration` ✅

#### 1.4 Frontend: Vue.js компоненты

**1.4.1 API клиент и типы**
- ✅ Создать API клиент `audits-api.ts` для работы с `/api/ra/audits` ✅
- ✅ Создать API клиент `audit-types-api.ts` для `/api/ra/audit-types` ✅
- ✅ Создать API клиент `directories-api.ts` для `/api/ra/directories` ✅
- ✅ Определить TypeScript типы для DTO (RaADto, RaAtDto, RaDirDto, Request DTO) ✅
- ✅ Добавить `apiPut` и `apiDelete` в `http.ts` ✅

**1.4.2 Pinia store**
- ✅ Создать store `audits.ts` для управления состоянием ревизий ✅
- ✅ Создать store для справочников (типы ревизий и директории) ✅
- ✅ Реализовать actions: load, create, update, delete ✅
- ✅ Реализовать загрузку справочников ✅

**1.4.3 Единая страница ревизий (`AuditsView.vue`)**

**Правая панель (навигация по ревизиям):**
- ✅ Список ревизий (сортировка по `adt_name`) ✅
- ✅ Отображение `adt_name` для каждой ревизии ✅
- ✅ Выбор ревизии → загрузка данных в форму ✅
- ✅ Кнопка "Создать новую" → создание новой ревизии ✅

**Основная область (левая часть):**

**Форма ревизии:**
- ✅ Поля формы: ✅
  - ✅ "имя ревизии" (`adt_name`) - текстовое поле ✅
  - ✅ "ревизия, тип" (`adt_type`) - выпадающий список из `ra_at` ✅
  - ✅ "директория" (`adt_dir`) - выпадающий список из `ra_dir` ✅
  - ✅ "обновляем базу данных?" (`adt_AddRA`) - чекбокс ✅
  - ✅ "дата и время" (`adt_date`) - datetime picker ✅
- ✅ Кнопка "Сохранить" - сохранение изменений ревизии ✅
- ✅ Кнопка "Выполнить ревизию" - заглушка (всплывающее окно с сообщением) ✅
- ✅ Валидация полей ✅
- ✅ Обработка ошибок ✅

**Вкладки:**
- ✅ Вкладка "ход ревизии" - область для отображения лога выполнения ✅
  - ✅ Заглушка (пока отображается сообщение или пустая область) ✅
  - 📋 Реализация лога будет в отдельном подэтапе при разработке "Выполнить ревизию"
- ✅ Вкладка "файлы для проверки" - заглушка (будет отдельным подэтапом) ✅

**1.4.4 Навигация и интеграция**
- ✅ Добавить кнопку "Ревизии" в TopBar ✅
- ✅ Добавить маршрут/переключение на страницу ревизий ✅
- ✅ Интеграция с connection store для отображения кнопки ✅

**1.4.5 Дополнительные задачи (отложены на будущее)**
- [ ] Реализация кнопки "Выполнить ревизию" (импорт из Excel)
- [ ] Реализация лога выполнения в вкладке "ход ревизии"
- [ ] Реализация вкладки "файлы для проверки" (субформа)

#### 1.5 Интеграция и тестирование

- ✅ Настроить роутинг Vue Router (используется connection store + activeView вместо Vue Router) ✅
- ✅ Настроить API клиент (Axios/Fetch) ✅
  - ✅ API клиент `http.ts` с методами `apiGet`, `apiPost`, `apiPut`, `apiDelete` ✅
  - ✅ API клиенты для ревизий: `audits-api.ts`, `audit-types-api.ts`, `directories-api.ts` ✅
  - ✅ Настроен Vite proxy для development режима ✅
- ✅ Создать Pinia store для управления состоянием ✅
  - ✅ `audits.ts` - управление состоянием ревизий ✅
  - ✅ `audit-types.ts` - справочник типов ревизий ✅
  - ✅ `directories.ts` - справочник директорий ✅
- ✅ Тестирование CRUD операций ✅
  - ✅ Unit тесты для `useAuditsStore` (13 тестов) ✅
  - ✅ Unit тесты для `useAuditTypesStore` (3 теста) ✅
  - ✅ Unit тесты для `useDirectoriesStore` (3 теста) ✅
  - ✅ Все тесты проходят успешно (19/19) ✅
- ✅ Проверка работы выпадающих списков ✅
  - ✅ Выпадающий список типов ревизий (`ra_at`) ✅
  - ✅ Выпадающий список директорий (`ra_dir`) ✅
  - ✅ Данные загружаются через соответствующие stores ✅
- ✅ UI/UX тестирование формы ✅
  - ✅ Форма ревизии интегрирована в `AuditsView.vue` ✅
  - ✅ Валидация полей формы ✅
  - ✅ Обработка ошибок с отображением в UI ✅
  - ✅ Уведомления об успешных операциях (Quasar Notify) ✅
  - ✅ Интеграция с TopBar и навигацией ✅
- ✅ Тестирование в браузере (2026-01-15) ✅
  - ✅ Сборка Thin JAR и развертывание в `/home/alex/femsq-test/test-26-0115/` ✅
  - ✅ Исправление проблем с URL API (дублирование `/api/v1`) ✅
  - ✅ Проверка работы страницы ревизий с реальной БД ✅
  - ✅ Проверка загрузки данных (ревизии, типы, директории) ✅
  - ✅ Проверка CRUD операций (создание, редактирование, удаление ревизий) ✅
  - ✅ Проверка работы выпадающих списков с данными из БД ✅
  - ✅ Оптимизация UI: уменьшение ширины левой панели в 2.5 раза ✅
  - ✅ Оптимизация UI: уменьшение вертикальных отступов формы в 4 раза для увеличения места под лог ревизии ✅
  - ✅ Страница работает корректно в production режиме (Thin JAR) ✅

---

## 📌 Следующие этапы (будут детализированы позже)

### Этап 2: Работа с файлами для ревизии

#### 2.1 База данных: Создание таблиц и перенос данных

**2.1.1 Анализ структуры таблиц в MS Access** ✅ (2026-01-15)
- ✅ Изучить структуру таблицы `ra_f` в MS Access ✅
  - Проанализирован VBA код из `Form_ra_a.cls`
  - Определены поля: `af_key`, `af_name`, `af_dir`, `af_type`, `af_execute`, `af_source`
  - Выявлены дополнительные поля: `af_is_done`, `af_is_source` (упомянуты в плане)
- ✅ Изучить структуру справочных таблиц `ra_ft_s`, `ra_ft_sn`, `ra_ft_st` ✅
  - `ra_ft_st`: `st_key`, `st_name` (типы источников)
  - `ra_ft_s`: `ft_s_key`, `ft_s_type`, `ft_s_num`, `ft_s_sheet_type` (источники/листы)
  - `ra_ft_sn`: `ftsn_key`, `ftsn_ft_s`, `ftsn_name` (имена источников)
- ✅ Определить связи между таблицами (FK constraints) ✅
  - `ra_f.af_dir` → `ra_dir.key`
  - `ra_ft_s.ft_s_sheet_type` → `ra_ft_st.st_key`
  - `ra_ft_sn.ftsn_ft_s` → `ra_ft_s.ft_s_key`
  - `ra_f.af_type` → связь по значению с `ra_ft_s.ft_s_type`
- ✅ Определить связи с таблицей `ra_a` (связь файлов с ревизиями) ✅
  - Текущая реализация: фильтрация по `af_dir = adt_dir`
  - Рекомендация: добавить явную FK `af_adt_key → ra_a.adt_key`
- ✅ Документировать поля и их типы данных ✅
  - Создан документ: `docs/development/notes/analysis/ra-f-tables-structure-analysis.md`
  - Определены типы данных для SQL Server
  - Документированы типы файлов (значения `af_type`: 1-6)
  - Описаны особенности обработки для каждого типа

**2.1.2 Создание таблицы `ags.ra_f` (файлы для проверки)** ✅ (2026-01-15)
- ✅ Создать SQL скрипт `04_create_ra_f_tables.sql` ✅
  - Создан скрипт: `code/config/sql/04_create_ra_f_tables.sql`
- ✅ Определить структуру таблицы ✅
  - `af_key` - первичный ключ (BIGINT IDENTITY(1,1)) ✅
  - `af_name` - имя файла (NVARCHAR(255) NOT NULL) ✅
  - `af_dir` - FK к `ags.ra_dir.key` (INT NOT NULL) ✅
  - `af_type` - тип файла (INT NOT NULL, значения 1-6) ✅
  - `af_execute` - флаг выполнения проверки (BIT NOT NULL DEFAULT 1) ✅
  - `af_source` - источник данных (INT NULL) ✅
  - `af_adt_key` - FK к `ags.ra_a.adt_key` (BIGINT NULL, связь с ревизией) ✅
  - `af_is_done` - флаг завершения проверки (BIT NOT NULL DEFAULT 0) ✅
  - `af_is_source` - флаг источника данных (BIT NOT NULL DEFAULT 0) ✅
  - `af_created`, `af_updated` - даты создания/обновления (DATETIME2 DEFAULT GETDATE()) ✅
- ✅ Создать индексы ✅
  - PRIMARY KEY на `af_key` ✅
  - NONCLUSTERED на `af_dir` (IX_ra_f_dir) ✅
  - NONCLUSTERED на `af_type` (IX_ra_f_type) ✅
  - NONCLUSTERED на `af_adt_key` с фильтром WHERE (IX_ra_f_adt_key) ✅
  - NONCLUSTERED на `af_execute` с фильтром WHERE (IX_ra_f_execute) ✅
  - NONCLUSTERED на `af_name` (IX_ra_f_name) ✅
  - Составной индекс на `af_dir, af_type, af_execute` (IX_ra_f_dir_type_execute) ✅
- ✅ Добавить FK constraints ✅
  - FK к `ags.ra_dir` (FK_ra_f_dir: `af_dir` → `ra_dir.key`) ✅
  - FK к `ags.ra_a` (FK_ra_f_adt: `af_adt_key` → `ra_a.adt_key`) ✅
- ✅ Добавить комментарии к таблице (Extended Properties) ✅
  - Комментарий к таблице ✅
  - Комментарии ко всем полям с описанием назначения ✅

**2.1.3 Создание справочных таблиц типов файлов** ✅ (2026-01-15)
- ✅ Создать таблицу `ags.ra_ft_st` (типы источников) ✅
  - Поля: `st_key` (PK, INT IDENTITY), `st_name` (NVARCHAR(255) NOT NULL), `st_created`, `st_updated` ✅
  - UNIQUE индекс на `st_name` ✅
- ✅ Создать таблицу `ags.ra_ft_s` (источники/листы) ✅
  - Поля: `ft_s_key` (PK, INT IDENTITY), `ft_s_type` (INT NOT NULL), `ft_s_num` (INT NOT NULL), `ft_s_sheet_type` (INT NOT NULL, FK к `ra_ft_st.st_key`), `ft_s_created`, `ft_s_updated` ✅
  - Индексы: `IX_ra_ft_s_type`, `IX_ra_ft_s_sheet_type`, `IX_ra_ft_s_type_num` (составной) ✅
  - FK constraint: `FK_ra_ft_s_sheet_type` → `ags.ra_ft_st.st_key` ✅
- ✅ Создать таблицу `ags.ra_ft_sn` (имена источников) ✅
  - Поля: `ftsn_key` (PK, INT IDENTITY), `ftsn_ft_s` (INT NOT NULL, FK к `ra_ft_s.ft_s_key`), `ftsn_name` (NVARCHAR(255) NOT NULL), `ftsn_created`, `ftsn_updated` ✅
  - Индексы: `IX_ra_ft_sn_ft_s`, `IX_ra_ft_sn_name` ✅
  - FK constraint: `FK_ra_ft_sn_ft_s` → `ags.ra_ft_s.ft_s_key` ✅
- ✅ Создать индексы для справочных таблиц ✅
  - Все необходимые индексы созданы (см. выше) ✅
- ✅ Добавить FK constraints ✅
  - `ra_ft_s.ft_s_sheet_type` → `ra_ft_st.st_key` ✅
  - `ra_ft_sn.ftsn_ft_s` → `ra_ft_s.ft_s_key` ✅
  - Примечание: связь `ra_f.af_type` с `ra_ft_s.ft_s_type` реализована по значению (не FK), так как `af_type` может иметь значения, не представленные в справочнике ✅
- ✅ Добавить комментарии к таблицам (Extended Properties) ✅
  - Комментарии ко всем трем таблицам и их полям ✅

**2.1.4 Перенос данных из MS Access** ✅ (2026-01-15)
- ✅ Экспортировать данные из `ra_f` в CSV или JSON ✅
  - Bash скрипт автоматически экспортирует данные из MS Access в CSV ✅
  - Используется утилита `mdb-export` из пакета `mdbtools` ✅
- ✅ Экспортировать данные из справочных таблиц ✅
  - Экспорт `ra_ft_st`, `ra_ft_s`, `ra_ft_sn` в отдельные CSV файлы ✅
  - Все таблицы экспортируются автоматически при запуске скрипта ✅
- ✅ Создать Python скрипт импорта: `05_import_ra_f_data.py` ✅
  - Скрипт импортирует данные в правильном порядке (с учетом FK constraints) ✅
  - Обрабатывает BIT поля (af_execute, af_is_done, af_is_source) ✅
  - Обрабатывает NULL значения и значения по умолчанию ✅
  - Поддерживает различные форматы дат из MS Access ✅
  - Сохраняет оригинальные ключи через IDENTITY_INSERT ✅
- ✅ Создать bash скрипт: `import_ra_f.sh` ✅
  - Автоматический экспорт данных из MS Access ✅
  - Проверка наличия зависимостей (pyodbc, mdbtools) ✅
  - Интерактивное подтверждение перезаписи существующих CSV файлов ✅
  - Подсчет записей для импорта ✅
  - Запуск Python скрипта импорта ✅
- ✅ Выполнить импорт данных в SQL Server ✅ (2026-01-15)
  - ✅ Экспорт данных из MS Access в CSV файлы выполнен ✅
  - ✅ Созданы таблицы в базе данных FishEye ✅
  - ✅ Импортированы данные:
    - `ra_ft_st`: 6 записей ✅
    - `ra_ft_s`: 41 запись ✅
    - `ra_ft_sn`: 126 записей ✅
    - `ra_f`: 138 записей ✅
  - ✅ Всего импортировано: 311 записей ✅
- ✅ Проверить целостность данных и связи ✅ (2026-01-15)
  - ✅ Проверка FK constraints выполнена ✅
  - ✅ Все связи корректны (ra_f → ra_dir, ra_ft_s → ra_ft_st, ra_ft_sn → ra_ft_s) ✅
  - ✅ Данные соответствуют экспортированным из MS Access ✅

**2.1.5 Исправление структуры БД после анализа UI** ✅ (2026-01-15)
- ✅ Выполнен анализ форм MS Access и сравнение с БД ✅
- ✅ Исправлена таблица `ags.ra_f`:
  - ✅ Удалены лишние поля: `af_is_done`, `af_is_source`, `af_adt_key` ✅
  - ✅ Добавлены поля: `af_num` (INT), `ra_org_sender` (INT) ✅
  - ✅ Изменен тип: `af_source` (INT → BIT) ✅
  - ✅ Обновлено 138 записей с инициализацией `af_num` ✅
  - ✅ Созданы индексы: `IX_ra_f_num`, `IX_ra_f_org_sender` ✅
- ✅ Исправлена таблица `ags.ra_ft_s`:
  - ✅ Добавлено поле: `ft_s_period` (NVARCHAR(50)) ✅
  - ✅ Создан индекс: `IX_ra_ft_s_period` ✅

**2.1.6 Перенос справочника типов файлов (ra_ft)** ✅ (2026-01-15)
- ✅ Создать таблицу `ags.ra_ft` (справочник типов файлов) ✅
  - Поля: `ft_key` (INT PK IDENTITY), `ft_name` (NVARCHAR(255) NOT NULL) ✅
  - Индекс: `IX_ra_ft_name` ✅
  - Комментарий: "Справочник типов файлов для проверки (lookup для ra_f.af_type)" ✅
- ✅ Импортировать данные из MS Access (6 записей): ✅
  1. "отчёты агента" (107 файлов)
  2. "хранение оборудования и стройконтроль" (11 файлов)
  3. "аренда земли" (6 файлов)
  4. "агентское вознаграждение" (4 файла)
  5. "отчёты всех агентов" (5 файлов)
  6. "23-0627_агентское вознаграждение" (5 файлов)
- ✅ Добавить FK constraint: `ra_f.af_type` → `ra_ft.ft_key` ✅
- ✅ Добавить FK constraint: `ra_f.ra_org_sender` → `og.ogKey` ✅
- ✅ Проверить целостность данных ✅
  - Все значения `af_type` корректны (0 некорректных) ✅
  - Все значения `ra_org_sender` корректны (0 некорректных) ✅

#### 2.2 Backend: Entity классы и DAO

**2.2.1 Создание Entity классов**
- ✅ Создать `com.femsq.database.model.RaF` (AuditFile entity) ✅
  - Record класс с валидацией полей ✅
  - Маппинг на таблицу `ags.ra_f` ✅
  - Поля: `afKey`, `afName`, `afDir`, `afType`, `afExecute`, `afSource`, `afAdtKey`, `afIsDone`, `afIsSource`, `afCreated`, `afUpdated` ✅
- ✅ Создать `com.femsq.database.model.RaFtSt` (FileSourceType entity) ✅
  - Поля: `stKey`, `stName`, `stCreated`, `stUpdated` ✅
- ✅ Создать `com.femsq.database.model.RaFtS` (FileSource entity) ✅
  - Поля: `ftSKey`, `ftSType`, `ftSNum`, `ftSSheetType`, `ftSCreated`, `ftSUpdated` ✅
- ✅ Создать `com.femsq.database.model.RaFtSn` (FileSourceName entity) ✅
  - Поля: `ftsnKey`, `ftsnFtS`, `ftsnName`, `ftsnCreated`, `ftsnUpdated` ✅
- ✅ Настроить связи между сущностями ✅
  - Связи реализованы через FK в базе данных, Entity классы содержат соответствующие поля ✅

**2.2.2 Создание DAO интерфейсов**
- ✅ Создать `RaFDao` - интерфейс для работы с файлами ревизий ✅
  - Методы: `findAll()`, `findById()`, `findByAuditId()`, `findByDirId()`, `findByFileType()`, `create()`, `update()`, `delete()`, `count()` ✅
- ✅ Создать `RaFtSDao` - интерфейс для работы с источниками ✅
  - Методы: `findAll()`, `findById()`, `findByFileType()`, `findBySheetType()`, `create()`, `update()`, `delete()`, `count()` ✅
- ✅ Создать `RaFtSnDao` - интерфейс для работы с именами источников ✅
  - Методы: `findAll()`, `findById()`, `findByFtS()`, `create()`, `update()`, `delete()`, `count()` ✅
- ✅ Создать `RaFtStDao` - интерфейс для работы с типами источников ✅
  - Методы: `findAll()`, `findById()`, `create()`, `update()`, `delete()`, `count()` ✅

**2.2.3 JDBC реализации DAO** ✅
- ✅ Создать `JdbcRaFDao` - реализация для файлов ревизий (с полным CRUD) ✅
  - Реализованы все методы интерфейса ✅
  - Обработка NULL значений для `afSource` и `afAdtKey` ✅
  - Логирование операций ✅
- ✅ Создать `JdbcRaFtSDao` - реализация для источников ✅
  - Реализованы все методы интерфейса ✅
  - Сортировка по `ft_s_num` для `findByFileType()` и `findBySheetType()` ✅
- ✅ Создать `JdbcRaFtSnDao` - реализация для имен источников ✅
  - Реализованы все методы интерфейса ✅
  - Метод `findByFtS()` для получения всех имен для источника ✅
- ✅ Создать `JdbcRaFtStDao` - реализация для типов источников ✅
  - Реализованы все методы интерфейса ✅
- ✅ Добавить обработку ошибок и логирование ✅
  - Все DAO используют `DaoException` для обработки ошибок ✅
  - Логирование через `java.util.logging.Logger` ✅
  - Подробные сообщения об ошибках на русском языке ✅
- ✅ Зарегистрировать DAO в `DatabaseModuleConfiguration` ✅
  - Добавлены бины для всех четырех DAO ✅

#### 2.3 Backend: Сервисный слой и REST API

**2.3.1 Сервисный слой** ✅
- ✅ Создать интерфейсы: `RaFService`, `RaFtSService`, `RaFtSnService`, `RaFtStService` ✅
- ✅ Создать реализации: `DefaultRaFService`, `DefaultRaFtSService`, `DefaultRaFtSnService`, `DefaultRaFtStService` ✅
- ✅ Добавить валидацию бизнес-правил: ✅
  - ✅ Проверка существования ревизии при создании файла ✅
  - ✅ Проверка уникальности имени файла в рамках ревизии ✅
  - ⚠️ Валидация путей к файлам (отложено до этапа 2.3.6) ⚠️

**2.3.2 DTO классы** ✅
- ✅ Создать DTO: `RaFDto`, `RaFtSDto`, `RaFtSnDto`, `RaFtStDto` ✅
- ✅ Создать Request DTO: `RaFCreateRequest`, `RaFUpdateRequest` ✅
- ✅ Добавить валидацию полей через аннотации ✅
  - Использованы `@NotBlank`, `@NotNull`, `@Size` для валидации ✅

**2.3.3 Mapper классы** ✅
- ✅ Создать `RaFMapper` для преобразования RaF ↔ RaFDto и Request DTO ✅
- ✅ Создать `RaFtSMapper` для преобразования RaFtS ↔ RaFtSDto ✅
- ✅ Создать `RaFtSnMapper` для преобразования RaFtSn ↔ RaFtSnDto ✅
- ✅ Создать `RaFtStMapper` для преобразования RaFtSt ↔ RaFtStDto ✅

**2.3.4 REST контроллеры** ✅
- ✅ Создать `RaFRestController` с endpoints: ✅
  - ✅ `GET /api/ra/files` - список всех файлов ✅
  - ✅ `GET /api/ra/audits/{auditId}/files` - список файлов для ревизии ✅
  - ✅ `GET /api/ra/files/{id}` - детали файла ✅
  - ✅ `POST /api/ra/audits/{auditId}/files` - создание файла для ревизии ✅
  - ✅ `PUT /api/ra/files/{id}` - обновление файла ✅
  - ✅ `DELETE /api/ra/files/{id}` - удаление файла ✅
- ✅ Создать `RaFtSRestController`: ✅
  - ✅ `GET /api/ra/file-sources` - список источников ✅
- ✅ Создать `RaFtSnRestController`: ✅
  - ✅ `GET /api/ra/file-source-names` - список имен источников ✅
- ✅ Создать `RaFtStRestController`: ✅
  - ✅ `GET /api/ra/file-source-types` - список типов источников ✅

**2.3.5 Регистрация в конфигурации**
- ✅ Зарегистрировать DAO бины в `DatabaseModuleConfiguration` ✅
  - Добавлены: `raFDao`, `raFtStDao`, `raFtSDao`, `raFtSnDao` ✅
- ✅ Зарегистрировать сервисы в `DatabaseModuleConfiguration` ✅
  - Добавлены бины: `raFService`, `raFtStService`, `raFtSService`, `raFtSnService` ✅
- ✅ Зарегистрировать новые бины: ✅ (2026-01-15)
  - `raFtDao`, `raFtService` ✅

**2.3.6 Сервисная логика для работы с файловой системой**
- [ ] Создать `FileSystemService` для проверки существования файлов
- [ ] Реализовать валидацию путей к файлам
- [ ] Добавить логирование операций с файлами
- [ ] Обработка ошибок доступа к файлам

#### 2.4 Frontend: Vue.js компоненты

**2.4.1 API клиенты и типы** ✅ (2026-01-15)
- ✅ Создать API клиент `files-api.ts` для работы с `/api/ra/files` ✅
  - `GET /api/ra/files` - получить все файлы ✅
  - `GET /api/ra/files/{id}` - получить файл по ID ✅
  - `GET /api/ra/directories/{dirId}/files` - получить файлы директории ✅
  - `POST /api/ra/files` - создать файл ✅
  - `PUT /api/ra/files/{id}` - обновить файл ✅
  - `DELETE /api/ra/files/{id}` - удалить файл ✅
- ✅ Создать API клиент `file-types-api.ts` для `/api/ra/file-types` (lookup) ✅
  - `GET /api/ra/file-types` - получить все типы ✅
  - `GET /api/ra/file-types/{id}` - получить тип по ID ✅
- ✅ Создать API клиент `organizations-api.ts` для `/api/og` (lookup для ra_org_sender) ✅
  - `GET /api/og` - получить все организации ✅
  - `GET /api/og/{id}` - получить организацию по ID ✅
  - `getOrganizationsLookup()` - упрощенная версия для select ✅
- ✅ Создать API клиент `directories-api.ts` для `/api/ra/directories` ✅
  - `GET /api/ra/directories` - получить все директории ✅
  - `GET /api/ra/directories/{id}` - получить директорию по ID ✅
  - `GET /api/ra/audits/{auditId}/directory` - получить директорию ревизии (1:1) ✅
- ✅ Определить TypeScript типы: ✅
  - `RaFDto` (обновленный: с `af_num`, `ra_org_sender`, без `af_is_done`, `af_is_source`, `af_adt_key`) ✅
  - `RaFCreateRequest`, `RaFUpdateRequest` ✅
  - `RaFtDto` (справочник типов файлов) ✅
  - `DirectoryDto` (для отображения директории) ✅
  - `OrganizationDto`, `OrganizationLookupDto` (для lookup отправителя) ✅

**2.4.2 Pinia stores** ✅ (2026-01-15)
- ✅ Создать store `useFilesStore` для управления файлами ✅
  - Actions: `loadByDirId`, `loadAll`, `loadById`, `create`, `update`, `deleteFile`, `clearFiles` ✅
  - State: `files`, `currentDirId`, `loading`, `error` ✅
  - Getters: `filesByDirId`, `fileById`, `filesByType`, `sortedFiles` ✅
- ✅ Создать store `useLookupsStore` для справочников ✅
  - Actions: `loadFileTypes`, `loadOrganizations`, `loadAllLookups`, `clearAll` ✅
  - State: `fileTypes`, `organizations`, загрузки и флаги ✅
  - Getters: `fileTypeNameById`, `organizationNameById`, `*Options` для select ✅
- ✅ Создать store `useDirectoriesStore` для работы с директориями ✅
  - Actions: `loadAll`, `loadById`, `loadByAuditId`, `setCurrentDirectory`, `clearDirectories` ✅
  - State: `directories`, `currentDirectory`, `loading`, `error` ✅
  - Getters: `directoryById`, `directoriesOptions` ✅

**2.4.3 Компоненты для вкладки "файлы для проверки"** ✅ (2026-01-16)

**Главный компонент (Master-Detail):**
- ✅ Создать `AuditFilesTab.vue` - главный компонент вкладки ✅
  - Верхняя секция: информация о директории (readonly) ✅
  - Нижняя секция: таблица файлов с CRUD операциями ✅
  - Загрузка директории по `auditId` (1:1 связь) ✅
  - Передача `dirId` в дочерние компоненты ✅
  - Обработка ошибок загрузки ✅

**Компонент информации о директории:**
- ✅ Создать `DirectoryInfo.vue` (readonly) ✅
  - Отображение полей: `key`, `path` ✅
  - Компактный вид (q-card) ✅
  - Без возможности редактирования ✅
  - Отображение дат создания/обновления ✅
  - Индикатор загрузки (q-linear-progress) ✅

**Компонент списка файлов:**
- ✅ Создать `FilesList.vue` - таблица файлов ✅
  - Колонки (q-table): ✅
    - `№` (`af_num`) - номер по порядку ✅
    - `Имя файла` (`af_name`) с иконкой ✅
    - `Тип` (`af_type`) - lookup в `ra_ft.ft_name` (chip) ✅
    - `Отправитель` (`ra_org_sender`) - lookup в `og.ogNm` ✅
    - `Рассмотрение` (`af_execute`) - иконка ✅
    - `Из Excel` (`af_source`) - иконка ✅
    - Действия (редактировать, удалить) ✅
  - Сортировка по `af_num` (по умолчанию) ✅
  - Фильтрация: поиск по имени + фильтр по типу ✅
  - Кнопка "Добавить файл" ✅
  - Диалог подтверждения удаления ✅
  - Quasar Notify для уведомлений ✅

**Форма редактирования файла:**
- ✅ Создать `FileEditDialog.vue` - модальное окно ✅
  - Поля формы (с валидацией): ✅
    - `af_name` - текстовое поле (обязательное, max 500) ✅
    - `af_type` - select с lookup в `ra_ft` (обязательное) ✅
    - `ra_org_sender` - select с lookup в `og` (необязательное) ✅
    - `af_execute` - чекбокс (по умолчанию false) ✅
    - `af_source` - чекбокс (необязательное) ✅
    - `af_num` - число (для сортировки, необязательное) ✅
  - Валидация полей (q-form + rules) ✅
  - Обработка ошибок от API ✅
  - Режимы: создание/редактирование ✅
  - Persistent dialog (не закрывается при клике вне) ✅
  - Автозагрузка справочников ✅

**Демо-представление:**
- ✅ Создать `AuditsView.vue` - страница с вкладками ✅
  - Вкладка "Файлы для проверки" (активна) ✅
  - Остальные вкладки (заглушки) ✅

**2.4.4 Дополнительные backend endpoints** ✅ (2026-01-16)
- ✅ Создать `OgLookupRestController` для lookup организаций (`/api/og`) ✅
  - `GET /api/og` - получить все организации ✅
  - `GET /api/og/{id}` - получить организацию по ID ✅
- ✅ Создать `RaAuditDirectoryRestController` для получения директории ревизии ✅
  - `GET /api/ra/audits/{auditId}/directory` - получить директорию по audit ID (1:1) ✅
- ✅ Обновить `RaDirRestController` ✅
  - Добавлен `GET /api/ra/directories/{id}` - получить директорию по ID ✅
- ✅ Обновить `RaDirService` ✅
  - Добавлен метод `getById(int key)` ✅
- ✅ Обновить `DefaultRaDirService` ✅
  - Реализован метод `getById(int key)` ✅

**2.4.5 Исправление компонентов на Quasar Framework** ✅ (2026-01-16)
- ✅ Исправлена критическая ошибка: компоненты были написаны для Vuetify 3 вместо Quasar ✅
- ✅ Переписаны все Vue компоненты (5 файлов): ✅
  - `DirectoryInfo.vue` - карточка директории ✅
  - `FileEditDialog.vue` - форма создания/редактирования ✅
  - `FilesList.vue` - таблица с CRUD операциями ✅
  - `AuditFilesTab.vue` - главный компонент ✅
  - `AuditsView.vue` - страница с вкладками ✅
- ✅ Замены компонентов Vuetify → Quasar: ✅
  - v-card → q-card, v-dialog → q-dialog, v-form → q-form ✅
  - v-text-field → q-input, v-select → q-select ✅
  - v-data-table → q-table, v-chip → q-chip ✅
  - v-snackbar → $q.notify (Quasar plugin) ✅
  - v-tabs/v-tab → q-tabs/q-tab ✅
  - v-window → q-tab-panels ✅
- ✅ Использование Quasar особенностей: ✅
  - `useQuasar()` для notifications ✅
  - Quasar grid система (row/col классы) ✅
  - q-table с шаблонами для колонок ✅
  - Material Icons через Quasar ✅

**2.4.6 Интеграция функционала (готово к тестированию)** ✅ (2026-01-16)
- ✅ Все компоненты интегрированы ✅
- ✅ CRUD операции полностью реализованы ✅
- ✅ Lookup справочники работают с кешированием ✅
- ✅ Master-Detail архитектура (Директория → Файлы) реализована ✅
- ✅ Валидация на frontend и backend ✅
- ✅ Обработка ошибок и уведомления ✅
- ✅ Линтер ошибок не находит ✅
- 📋 Требуется запуск и тестирование в браузере

#### 2.5 Интеграция и тестирование

**2.5.1 Unit тесты**
- [ ] Unit тесты для `useFilesStore` (CRUD операции)
- [ ] Unit тесты для `useLookupsStore` (справочники)
- [ ] Unit тесты для `useDirectoriesStore` (директории)
- [ ] Проверка всех тестов (должны проходить успешно)

**2.5.2 Интеграционное тестирование**
- [ ] Проверка работы CRUD операций с файлами через API
- [ ] Проверка загрузки файлов для конкретной директории
- [ ] Проверка работы выпадающих списков (типы файлов, организации)
- [ ] Проверка валидации полей формы
- [ ] Проверка работы lookup справочников с кешированием

**2.5.3 UI/UX тестирование**
- [ ] Проверка отображения списка файлов во вкладке "файлы для проверки"
- [ ] Проверка работы формы добавления/редактирования файлов
- [ ] Проверка интеграции директории с файлами (Master-Detail)
- [ ] Проверка фильтрации и сортировки файлов
- [ ] Проверка обработки ошибок и уведомлений (Quasar Notify)
- [ ] Проверка работы диалогов (создание, редактирование, удаление)

**2.5.4 Тестирование в браузере**
- [ ] Сборка Thin JAR и развертывание приложения
- [ ] Проверка работы страницы `/audits` с вкладкой "файлы для проверки"
- [ ] Проверка создания, редактирования, удаления файлов
- [ ] Проверка работы с реальной БД (138 файлов, 6 типов)
- [ ] Проверка корректного отображения lookup полей (организации)
- [ ] Подтверждение корректной работы в production режиме
- [ ] Проверка работы Quasar компонентов в браузере

### Этап 3: Запуск ревизии и импорт Excel

**Анализ VBA логики:**
- [ ] Детальный анализ функций из `Module1.bas`
  - `CellFind` - поиск данных в Excel
  - `DateConvertToQuery` - конвертация дат
  - `StringClean` - очистка строк
  - `FindCstAP` - поиск контрагентов
- [ ] Анализ функций из `ClassFunc.bas`
  - `varEditField*` - редактирование полей
  - `varReadField` - чтение полей

**Миграция алгоритмов на Java:**
- [ ] Разработка утилит для работы с Excel (Apache POI)
- [ ] Реализация алгоритмов поиска и валидации данных
- [ ] Миграция бизнес-логики проверки файлов
- [ ] Обработка ошибок и логирование

**Асинхронное выполнение:**
- [ ] Spring @Async для фоновых задач
- [ ] Таблица для хранения статуса выполнения
- [ ] SSE (Server-Sent Events) для отправки прогресса
- [ ] Frontend компонент отображения прогресса

**Импорт данных в `ags` схему:**
- [ ] Маппинг Excel → таблицы БД
- [ ] Batch insert для производительности
- [ ] Обработка дубликатов и конфликтов
- [ ] Откат транзакций при ошибках

### Этап 4: Дополнительный функционал

- [ ] История запусков ревизий (audit log)
- [ ] Сравнение результатов между запусками
- [ ] Email уведомления о завершении ревизии
- [ ] Экспорт результатов в PDF/Excel
- [ ] Dashboard с аналитикой по ревизиям

---

## 🔗 Связанные документы

- **VBA Код:** `docs/project/proposals/vba-analysis/VBA-Code-Export/`
- **Анализ:** `docs/project/proposals/vba-analysis/VBA-ANALYSIS-SUMMARY.md`
- **Схема БД:** Диаграмма связей из Access (см. скриншоты)
- **Proposal:** `docs/project/proposals/excel-import-proposal.md`

---

## 📝 Заметки

- Код VBA содержит много устаревших фрагментов
- Миграция будет выборочной, только актуальный функционал
- Приоритет: современный, поддерживаемый код
- Пошаговый подход с валидацией на каждом этапе

---

## ✅ Статус выполнения

### Этап 1: Базовая структура данных и форма ревизий ✅ ЗАВЕРШЁН
- **Этап 1.1:** ✅ Завершён (Таблицы созданы, данные перенесены)
- **Этап 1.2:** ✅ Завершён (Entity классы и DAO интерфейсы созданы)
- **Этап 1.3:** ✅ Завершён (REST API полностью реализован)
  - ✅ 1.3.1: JDBC реализации DAO
  - ✅ 1.3.2: Сервисный слой
  - ✅ 1.3.3: DTO классы
  - ✅ 1.3.4: Mapper классы
  - ✅ 1.3.5: REST контроллеры
  - ✅ 1.3.6: Регистрация в конфигурации
- **Этап 1.4:** ✅ Завершён (Frontend)
  - ✅ 1.4.1: API клиент и типы
  - ✅ 1.4.2: Pinia store
  - ✅ 1.4.3: Единая страница ревизий (AuditsView.vue)
  - ✅ 1.4.4: Навигация и интеграция
  - 📋 1.4.5: Дополнительные задачи (отложены)
- **Этап 1.5:** ✅ Завершён (Интеграция и тестирование)
  - ✅ Настройка API клиента и роутинга
  - ✅ Создание и тестирование Pinia stores
  - ✅ Unit тесты (19 тестов, все проходят)
  - ✅ Проверка UI/UX и интеграции компонентов

### Этап 2: Работа с файлами для ревизии ✅ ОСНОВНОЕ ЗАВЕРШЕНО, ТРЕБУЕТСЯ ТЕСТИРОВАНИЕ
- **Этап 2.1:** ✅ Завершён (База данных: Создание таблиц и перенос данных)
  - ✅ 2.1.1: Анализ структуры таблиц в MS Access
  - ✅ 2.1.2: Создание таблицы `ags.ra_f` (файлы для проверки)
  - ✅ 2.1.3: Создание справочных таблиц типов файлов
  - ✅ 2.1.4: Перенос данных из MS Access (311 записей)
  - ✅ 2.1.5: Исправление структуры БД после анализа UI
  - ✅ 2.1.6: Перенос справочника типов файлов (ra_ft)
- **Этап 2.2:** ✅ Завершён (Backend: Entity классы и DAO)
  - ✅ 2.2.1: Создание Entity классов (RaF, RaFt, RaFtS, RaFtSn, RaFtSt)
  - ✅ 2.2.2: Создание DAO интерфейсов
  - ✅ 2.2.3: JDBC реализации DAO
- **Этап 2.3:** ✅ Завершён (Backend: Сервисный слой и REST API)
  - ✅ 2.3.1: Сервисный слой с валидацией
  - ✅ 2.3.2: DTO классы
  - ✅ 2.3.3: Mapper классы
  - ✅ 2.3.4: REST контроллеры
  - ✅ 2.3.5: Регистрация в конфигурации
  - 📋 2.3.6: Сервисная логика для работы с файловой системой (отложено)
- **Этап 2.4:** ✅ Завершён (Frontend: Vue.js компоненты)
  - ✅ 2.4.1: API клиенты и типы (files, file-types, organizations, directories)
  - ✅ 2.4.2: Pinia stores (useFilesStore, useLookupsStore, useDirectoriesStore)
  - ✅ 2.4.3: Компоненты для вкладки "файлы для проверки" (5 компонентов)
  - ✅ 2.4.4: Дополнительные backend endpoints (Og, Directory)
  - ✅ 2.4.5: Исправление компонентов на Quasar Framework
  - ✅ 2.4.6: Интеграция функционала (готово к тестированию)
- **Этап 2.5:** 📋 В работе (Интеграция и тестирование)
  - 📋 2.5.1: Unit тесты (TODO)
  - 📋 2.5.2: Интеграционное тестирование (TODO)
  - 📋 2.5.3: UI/UX тестирование (TODO)
  - 📋 2.5.4: Тестирование в браузере (TODO)
- **Этап 2.6:** 🔧 В работе (Исправление проблем сборки - 2026-01-16)
  - 📋 2.6.1: Исправление модуля femsq-reports (КРИТИЧНО)
  - 📋 2.6.2: Исправление unit тестов (СРЕДНИЙ)
  - 📋 2.6.3: Настройка Thin JAR (НИЗКИЙ, опционально)
  - 📋 2.6.4: Финальная сборка

### Этапы 3-4: Запланированы
- **Этап 3:** 📋 Запуск ревизии и импорт Excel (запланирован)
- **Этап 4:** 📋 Дополнительный функционал (запланирован)

---

## 📈 Сводка по этапу 2 "Файлы для проверки"

### ✅ Завершено (2026-01-16):
- 📊 **База данных:** 5 таблиц, 311 записей импортировано
- 🔧 **Backend:** 5 Entity, 5 DAO, 5 Service, 5 REST контроллеров
- 🎨 **Frontend:** 4 API клиента, 3 Pinia store, 5 Vue компонентов (Quasar)
- 🔗 **Интеграция:** CRUD полный цикл, Master-Detail UI, Lookup справочники

### 📋 Следующие шаги:

#### **Этап 2.6: Исправление проблем сборки** 🔧 (В работе - 2026-01-16)

**Обнаруженные проблемы при сборке test-26-0116:**

**2.6.1 Исправление модуля femsq-reports** ⚠️ КРИТИЧНО
- [ ] Проверить наличие классов `Og` и `OgAg` в femsq-database
- [ ] Определить правильные пути импорта
- [ ] Исправить импорты в `ReportParametersController.java`:
  - Строка 3: `import com.femsq.database.model.Og;`
  - Строка 4: `import com.femsq.database.model.OgAg;`
- [ ] Исправить импорты в `ReportGenerationService.java`:
  - Пакеты `com.femsq.database.config`
  - Пакеты `com.femsq.database.connection`
- [ ] Проверить компиляцию модуля femsq-reports

**2.6.2 Исправление unit тестов** ⚠️ СРЕДНИЙ
- [ ] Определить, какой параметр добавлен в `DatabaseConfigurationProperties`
- [ ] Обновить все тесты с конструктором (примерно 30+ мест):
  - `AuthenticationProvidersTest.java` (6 мест)
  - `ConfigurationComponentTest.java` (15 мест)
  - `ConnectionFactoryIntegrationTest.java` (1 место)
  - `ConnectionFactoryTest.java` (4 места)
  - `DaoIntegrationTestSupport.java` (1 место)
  - `JdbcOgAgDaoSchemaTest.java` (1 место)
  - `JdbcOgDaoSchemaTest.java` (2 места)
- [ ] Проверить компиляцию всех тестов
- [ ] Запустить unit тесты для проверки

**2.6.3 Настройка Thin JAR** 📦 НИЗКИЙ (опционально)
- [ ] Проверить конфигурацию `spring-boot-maven-plugin`
- [ ] Отключить frontend-maven-plugin временно (если мешает)
- [ ] Собрать Thin JAR отдельно
- [ ] Собрать frontend через `npm run build`
- [ ] Настроить копирование frontend dist в JAR
- [ ] Проверить размер и структуру Thin JAR

**2.6.4 Финальная сборка**
- [ ] Выполнить полную сборку с тестами: `mvn clean package`
- [ ] Проверить успешность всех модулей
- [ ] Скопировать Thin JAR в `/home/alex/femsq-test/test-26-0116/`
- [ ] Обновить документацию в README-BUILD.md

#### **Этап 2.7: Тестирование в браузере** (после 2.6)
1. **Запустить приложение** (backend + frontend)
2. **Открыть страницу** `/audits` в браузере
3. **Протестировать функционал** "файлы для проверки":
   - Отображение директории для ревизии
   - Загрузка списка файлов (138 файлов)
   - Создание нового файла
   - Редактирование существующего файла
   - Удаление файла
   - Фильтрация и сортировка
   - Работа lookup справочников (типы, организации)
4. **Написать unit тесты** для stores (при необходимости)
5. **Задокументировать результаты** тестирования

---

**Дата создания:** 2026-01-12  
**Последнее обновление:** 2026-01-16  
**Автор:** Александр
