- **Цель чата**: перевести весь доменный API проекта с REST на GraphQL согласно исходной архитектурной концепции проекта: установить Apollo Client на фронтенде, добавить GraphQL-схему домена ревизий на бэкенде, заменить все REST-вызовы на фронтенде и удалить устаревшие REST-контроллеры.
- **Основание**: в ходе анализа чата `chat-plan-26-0311.md` установлено, что фронтенд никогда не использовал Apollo Client — все API-вызовы идут через `fetch` на REST. Это отступление от архитектурного замысла создаёт техдолг, который целесообразнее устранить до, а не после реализации Excel-функционала.
- **Текущее состояние**:
  - Backend: GraphQL-контроллер для организаций (`OgGraphqlController`) уже есть; схема `og-schema.graphqls` готова; зависимость `spring-boot-starter-graphql` подключена. Домен ревизий (`ra_a`, `ra_at`, `ra_dir`) покрыт только REST-контроллерами.
  - Frontend: Apollo Client **не установлен**; все 8 API-файлов используют `fetch`; домен ревизий полностью на REST.

---

## 1. Фаза 1: Backend — схема и контроллер домена ревизий

### 1.1. Создать `ra-schema.graphqls`

**Задачи:**
- Создать файл `code/femsq-backend/femsq-web/src/main/resources/graphql/ra-schema.graphqls` со следующими типами и операциями:

  **Типы домена:**
  ```graphql
  type Audit {
    adtKey: Int
    adtName: String!
    adtDate: String
    adtResults: String
    adtDir: Int
    adtType: Int
    adtAddRA: Boolean
    adtCreated: String
    adtUpdated: String
    adtStatus: AuditRunStatus!  # вычисляемое, из AuditExecutionRegistry
    directory: AuditDirectory    # @SchemaMapping — lazy
    auditType: AuditType         # @SchemaMapping — lazy
  }
  enum AuditRunStatus { IDLE RUNNING COMPLETED FAILED }
  type AuditDirectory { key: Int dirName: String dir: String dirCreated: String dirUpdated: String }
  type AuditType { atKey: Int atName: String }
  type AuditExecutionResult { started: Boolean! alreadyRunning: Boolean! message: String }
  input AuditCreateInput { adtName: String! adtDir: Int! adtType: Int! adtAddRA: Boolean }
  input AuditUpdateInput { adtName: String! adtDate: String adtDir: Int! adtType: Int! adtAddRA: Boolean }
  ```

  **Расширения корневых типов:**
  ```graphql
  extend type Query {
    audits: [Audit!]!
    audit(id: Int!): Audit
    auditTypes: [AuditType!]!
    directories: [AuditDirectory!]!
  }
  extend type Mutation {
    createAudit(input: AuditCreateInput!): Audit!
    updateAudit(id: Int!, input: AuditUpdateInput!): Audit!
    deleteAudit(id: Int!): Boolean!
    executeAudit(id: Int!): AuditExecutionResult!
  }
  ```

- Проверить, что `og-schema.graphqls` использует `schema { query: Query mutation: Mutation }` (корневые типы) — новый файл расширяет их через `extend type`.

**Ожидаемый результат:** файл `ra-schema.graphqls` содержит все типы домена `ra_a/ra_at/ra_dir`, запросы и мутации домена ревизий.

### 1.2. Создать `RaAGraphqlController`

**Задачи:**
- Создать `com.femsq.web.api.graphql.RaAGraphqlController` (`@Controller`):
  - `@QueryMapping audits()` — список всех ревизий;
  - `@QueryMapping audit(@Argument int id)` — одна ревизия;
  - `@QueryMapping auditTypes()` — справочник типов;
  - `@QueryMapping directories()` — справочник директорий;
  - `@MutationMapping createAudit`, `updateAudit`, `deleteAudit` — CRUD;
  - `@MutationMapping executeAudit(@Argument int id)` — возвращает `AuditExecutionResult`:
    - `tryMarkRunning(id)` не прошёл → `{ started: false, alreadyRunning: true, ... }` (HTTP 409 больше не используется);
    - успех → запуск `@Async`, `{ started: true, alreadyRunning: false }`;
  - `@SchemaMapping(typeName="Audit", field="directory")` — lazy-загрузка директории (вызывается только если фронт запросил поле);
  - `@SchemaMapping(typeName="Audit", field="auditType")` — аналогично.
- Внедрить `AuditExecutionResult` как Java `record` в пакете `com.femsq.web.api.dto`.

**Ожидаемый результат:** `RaAGraphqlController` работает параллельно с REST-контроллерами; все операции проверяются через GraphiQL (`/graphiql`).

### 1.3. Проверка сборки бэкенда

**Задачи:**
- Инкрементировать версию JAR.
- Собрать: `mvn -pl femsq-backend/femsq-web -am -DskipTests package`.
- Вручную проверить через GraphiQL: `audits`, `audit(id:12)` с вложенными полями, `executeAudit(id:12)`.
- REST-контроллеры на этом этапе **ещё работают** — фронтенд не поломан.

**Ожидаемый результат:** проект собирается, GraphQL-эндпоинт работает, `adtStatus` передаётся корректно.

---

## 2. Фаза 2: Frontend — установка Apollo Client

### 2.1. Установка зависимостей

**Задачи:**
- Выполнить:
  ```bash
  npm install @apollo/client @vue/apollo-composable graphql
  ```
- Создать `code/femsq-frontend-q/src/plugins/apollo.ts`:
  ```typescript
  import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client/core';
  const httpLink = createHttpLink({ uri: '/graphql' });
  export const apolloClient = new ApolloClient({
    link: httpLink,
    cache: new InMemoryCache(),
  });
  ```
- Подключить в `src/main.ts`:
  ```typescript
  import { DefaultApolloClient } from '@vue/apollo-composable';
  import { apolloClient } from './plugins/apollo';
  app.provide(DefaultApolloClient, apolloClient);
  ```
- Проверить `tsconfig.json` — возможно потребуется `"moduleResolution": "bundler"` для Apollo.

**Ожидаемый результат:** проект собирается без ошибок типов, Apollo Client доступен через `provide`.

### 2.2. Создать `.graphql`-файлы запросов

**Задачи:**
- Создать директорию `src/graphql/` с файлами:
  - `audits.graphql` — все запросы/мутации домена ревизий:
    - `GetAudits`, `GetAudit($id: Int!)`, `GetAuditWithDetails($id: Int!)`;
    - `CreateAudit`, `UpdateAudit`, `DeleteAudit`, `ExecuteAudit`.
  - `audit-types.graphql` — `GetAuditTypes`.
  - `directories.graphql` — `GetDirectories`.
  - `organizations.graphql` — `GetOrganizations`, `GetOrganizationsLookup`.
- Добавить в `vite.config.ts` поддержку `*.graphql`-файлов (через `vite-plugin-graphql-loader` или inline-импорт через `gql` тег).

**Ожидаемый результат:** все GraphQL-запросы оформлены как именованные операции, сборка проходит.
---

## 3. Фаза 3: Frontend — замена API-клиентов домена ревизий

### 3.1. Переписать `audits-api.ts`

**Задачи:**
- Заменить `src/api/audits-api.ts` полностью: вместо `apiGet`/`apiPost`/`apiPut`/`apiDelete` использовать `apolloClient.query` и `apolloClient.mutate`.
- Сохранить ту же сигнатуру функций (`getAudits()`, `getAuditById()`, `createAudit()`, ...) — стор не меняется.
- Обновить типа: `executeAudit` теперь возвращает `AuditExecutionResult` (не `boolean`).

**Ожидаемый результат:** `audits-api.ts` работает через GraphQL; опасных изменений стора не требуется.

### 3.2. Переписать `audit-types-api.ts` и `directories-api.ts`

**Задачи:**
- `audit-types-api.ts`: `getAuditTypes()` → `apolloClient.query({ query: GET_AUDIT_TYPES })`.
- `directories-api.ts`:
  - `getDirectories()` → `apolloClient.query({ query: GET_DIRECTORIES })`;
  - `getAuditDirectory(id)` → `apolloClient.query({ query: GET_AUDIT_DIRECTORY, variables: { id } })`.

**Ожидаемый результат:** справочники при загрузке спрашиваются через GraphQL.

### 3.3. Переписать `organizations-api.ts`

**Задачи:**
- Заменить REST-вызовы `getOrganizations()` и `getOrganizationsLookup()` на GraphQL-запросы `GET_ORGANIZATIONS` / `GET_ORGANIZATIONS_LOOKUP` через `apolloClient.query`.
- Схема `og-schema.graphqls` уже готова — никаких изменений бэкенда не нужно.

**Ожидаемый результат:** все API-клиенты домена `ra_a` и `og` используют GraphQL.

---

## 4. Фаза 4: Удаление устаревших REST-артефактов

### 4.1. Удалить REST-контроллеры домена ревизий

**Задачи:**
- Удалить (REST-контроллеры домена ревизий больше не нужны):
  - `RaARestController.java` (CRUD + `/execute`);
  - `RaAtRestController.java` (типы ревизий);
  - `RaAuditDirectoryRestController.java` (директории).
- **Оставить** REST-контроллеры `OgRestController`, `OgAgRestController`, `OgLookupRestController`, `LookupRestController` — они могут использоваться другими потребителями.
- Добавить запись в `application.properties`: `spring.graphql.graphiql.enabled=true` (уже есть); проверить `spring.mvc.pathmatch.use-suffix-pattern`.

**Ожидаемый результат:** REST-артефакты домена ревизий удалены; проект собирается без ошибок.

### 4.2. Удалить устаревшие REST API-файлы фронтенда

**Задачи:**
- Удалить (REST API-клиенты домена ревизий больше не нужны):
  - `src/api/audits-api.ts` (REST-версия, заменена в 3.1);
  - `src/api/audit-types-api.ts` (REST-версия, заменена в 3.2);
  - `src/api/directories-api.ts` (REST-версия, заменена в 3.2).
- **Оставить** `src/api/organizations-api.ts` — переписан на GraphQL в 3.3, REST-версия удаляется вместе с ним.
- **Оставить** `src/api/http.ts` — может использоваться для иных целей (status check и т.d.).

**Ожидаемый результат:** директория `src/api/` содержит только GraphQL-клиенты для доменных API.
---

## 5. Фаза 5: Обновление стора и компонента `AuditsView.vue`

### 5.1. Обновить `useAuditsStore`

**Задачи:**
- Импорт `audits-api.ts` остаётся прежним — никаких изменений в сторе не нужно (API-клиент изменён, интерфейс сохранён).
- Обновить тип `AuditExecutionResult` в `pollAuditStatus` / `executeAudit`:
  - `executeAudit` проверяет `result.alreadyRunning` — показывает `Notify.create` с предупреждением если `alreadyRunning === true`.

**Ожидаемый результат:** стор не знает о том, что транспортный слой изменился.

### 5.2. Проверить `AuditsView.vue`

**Задачи:**
- Проверить, что `AuditsView.vue` не обращается напрямую к API-файлам — всё идёт через стор. Изменений не требуется.
- Проверить, что `handleExecuteAudit` обрабатывает `AuditExecutionResult` (новый тип) корректно.

**Ожидаемый результат:** `AuditsView.vue` не требует изменений при миграции.

---

## 6. Фаза 6: Сборка, деплой, верификация

### 6.1. Инкрементировать версию, собрать JAR

**Задачи:**
- Увеличить четвёртую цифру версии во всех `pom.xml`.
- `mvn -pl femsq-backend/femsq-web -am -DskipTests package`.
- Убедиться, что в новом бандле нет `fetch`-вызовов в к API REST домена ревизий.

### 6.2. Деплой в тестовую папку

**Задачи:**
- Очистить тестовую папку, скопировать JAR, запустить сервер.
- Открыть `http://localhost:8080/graphiql`:
  - Выполнить запрос `{ audits { adtKey adtName adtStatus } }`;
  - Выполнить `mutation { executeAudit(id: 12) { started alreadyRunning } }`;
  - Убедиться, что повторный вызов возвращает `alreadyRunning: true`.
- Открыть Chrome DevTools → Network → убедиться, что запросы идут на `/graphql`, а не на `/api/ra/...`.

### 6.3. Обновить документацию

**Задачи:**
- Обновить `docs/project/project-docs.json`, `docs/development/project-development.json`, `docs/journal/project-journal.json` — отметить:
  - GraphQL является единственным API-транспортом доменных операций;
  - Apollo Client установлен на фронтенде;
  - REST остаётся только для `status check` и внешних интеграций.
- Подготовить `chat-resume-26-0317-graphql-migration.md`.

**Ожидаемый результат:** вся документация соответствует архитектуре с единым GraphQL API.

---

## 7. Граница чата

**Чат считается завершённым, если:**
- все REST-контроллеры домена ревизий удалены;
- все API-клиенты фронтенда домена ревизий используют GraphQL;
- Chrome DevTools показывает запросы на `/graphql` (не `/api/ra/...`);
- `AuditsView.vue` полностью работоспособен через новый транспорт;
- документация обновлена.

**Следующий чат** — реализация Excel-обработки в `AuditExecutionServiceImpl` (чтение .xlsx, перебор листов, запись в `adt_results`).

---

**Файл создан:** 2026-03-17
**Последнее обновление:** 2026-03-17
**Версия:** 1.0.0
**Автор:** Александр
