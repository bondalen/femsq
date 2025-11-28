# Reports Module Gap List

**Дата:** 2025-11-24  
**Автор:** Александр (по результатам аудита)

## Цель
Сравнить две существующие реализации фронтенда (`code/femsq-frontend` и `code/femsq-frontend-q`) и зафиксировать отсутствующий функционал в Quasar-версии, который необходимо перенести перед удалением старого клиента.

- **`code/femsq-frontend` (Vite + custom UI):** старая реализация; используется как источник оригинальных компонентов и тестов.
- **`code/femsq-frontend-q` (Vite + Quasar UI):** основная рабочая версия. Содержит API клиент, типы, Pinia store, каталог, диалог параметров и контекстную генерацию (перенос завершён 2025‑11‑24), собирается в Spring Boot JAR через `frontend-maven-plugin`.

## Детализация расхождений
| Область | `code/femsq-frontend` | `code/femsq-frontend-q` | Гэп |
| --- | --- | --- | --- |
| API клиент | `src/api/reports-api.ts` с методами `getAvailableReports`, `getReportMetadata`, `getReportParameters`, `generateReport`, `generatePreview`. Базовый URL `/api/v1/reports`. | Нет файлов `reports-api`, нет вызовов `/api/v1/reports`. | Требуется создать/перенести API клиент.
| Типы | `src/types/reports.ts` описывает ReportInfo/Metadata/Parameter, ContextMenu и т.д. | Отсутствуют соответствующие типы. | Перенести типы и обновить импорты.
| Pinia store | `src/stores/reports.ts` + `reports.test.ts`: кэш, фильтры, actions, async loading. | Нет store, нет тестов Vitest. | Перенести store, настройку Vitest и тесты.
| Модуль Reports | `src/modules/reports/views/ReportsCatalog.vue` (+ 12 тестов), `components/ReportParametersDialog.vue` (+ 14 тестов), `utils/context-resolver.ts`. | Директории `modules/reports` отсутствуют. | Перенести компоненты и утилиты, адаптировать под Quasar (QCard/QDialog/etc.).
| Навигация/TopBar | `TopBar.vue` содержит кнопку "Отчёты", `connection.store` поддерживает `ActiveView = 'reports'`, `App.vue` рендерит `<ReportsCatalog />`. | TopBar содержит только "Подключение", "Организации", "Инвестиционные цепочки"; `ActiveView` не имеет значения `reports`. | Добавить новый view, состояние и кнопку.
| Контекстная генерация | `components/contractors/ContractorCard.vue` и `components/objects/ObjectsList.vue` добавляют меню отчётов с использованием `context-resolver`. | Указанные компоненты отсутствуют (Quasar имеет собственные реализации без отчётов). | Расширить соответствующие компоненты Quasar (карточки/таблицы) аналогичным функционалом.
| Тесты | 54 теста (store + два компонента) в `femsq-frontend`. | Store + component тесты перенесены в `femsq-frontend-q` (Vitest + @vue/test-utils). | ✅ Гэп закрыт 2025‑11‑24.
| Сборка backend | `femsq-backend/femsq-web/pom.xml` использует `frontend-maven-plugin`. | Плагин собирает `code/femsq-frontend-q` и копирует артефакты в `target/static`. | ✅ Гэп закрыт 2025‑11‑24.
| Документация/скрипты | README и REPORTS_LAUNCH_GUIDE описывают работу каталога; отсылают к текущему UI. | Для Quasar нет упоминаний. | Обновить документы после миграции.

## Дополнительные наблюдения
1. Поиск `find code/femsq-frontend-q -maxdepth 3 -name '*reports*'` возвращает только зависимости в `node_modules/istanbul-reports` → модуль не реализован.
2. В Quasar TopBar (`code/femsq-frontend-q/src/components/layout/TopBar.vue`) активно управление инвестиционными цепочками; потребуется расширение навигации и новые маршруты.
3. Pinia store `code/femsq-frontend-q/src/stores/connection.ts` поддерживает только `ActiveView = 'home' | 'organizations' | 'investment-chains'` → необходимо добавить `reports` и соблюсти бизнес-логику (кнопка активна без подключения).
4. В Quasar-проекте нет Vitest тестов для `reports` (ни конфигурации, ни моков). Потребуется подключить `happy-dom`/`@vue/test-utils`, аналогично тому, как сделано в Vite-версии.
5. Папка `code/femsq-frontend-q/src/components` не содержит эквивалентов `ContractorCard.vue` или `ObjectsList.vue` из новой реализации, поэтому перенос контекстной генерации потребует адаптации к существующим quasar-компонентам (например, `views/investment-chains/InvestmentChainsView.vue`).

## Рекомендации по миграции (в привязке к плану 05.13.A)
1. Перенести API, типы, Pinia store и утилиты → убедиться в совместимости с Quasar настройками сборки.
2. Реализовать UI (каталог, диалог, контекстные меню) на компонентах Quasar.
3. Обновить навигацию, активные вью и connection store.
4. Перенести и адаптировать тесты (Vitest + @vue/test-utils + happy-dom).
5. После прохождения проверок удалить `code/femsq-frontend` (плагин уже переключён на `code/femsq-frontend-q`).
