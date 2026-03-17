- **Цель чата**: перевести весь доменный API проекта с REST на GraphQL согласно исходной архитектурной концепции проекта: установить Apollo Client на фронтенде, добавить GraphQL-схему домена ревизий на бэкенде, заменить все REST-вызовы на фронтенде и удалить устаревшие REST-контроллеры.
- **Основание**: в ходе анализа чата `chat-plan-26-0311.md` установлено, что фронтенд никогда не использовал Apollo Client — все API-вызовы идут через `fetch` на REST. Это отступление от архитектурного замысла создаёт техдолг, который целесообразнее устранить до, а не после реализации Excel-функционала.
- **Текущее состояние**:
  - Backend: GraphQL-контроллер для организаций (`OgGraphqlController`) уже есть; схема `og-schema.graphqls` готова; зависимость `spring-boot-starter-graphql` подключена. Домен ревизий (`ra_a`, `ra_at`, `ra_dir`) покрыт только REST-контроллерами.
  - Frontend: Apollo Client **не установлен**; все 8 API-файлов используют `fetch`; домен ревизий полностью на REST.

---

## 1. Фаза 1: Backend — схема и контроллер домена ревизий

### 1.1. Создать `ra-schema.graphqls` ✅

**Задачи:**
- Создать файл `code/femsq-backend/femsq-web/src/main/resources/graphql/ra-schema.graphqls` со следующими типами и операциями:

  **Скаляр и типы домена:**
  ```graphql
  scalar DateTime

  type Audit {
    adtKey: Int
    adtName: String!
    adtDate: DateTime
    adtResults: String
    adtDir: Int
    adtType: Int
    adtAddRA: Boolean
    adtCreated: DateTime
    adtUpdated: DateTime
    adtStatus: AuditRunStatus!  # вычисляемое, из AuditExecutionRegistry
    directory: AuditDirectory    # @SchemaMapping — lazy
    auditType: AuditType         # @SchemaMapping — lazy
  }
  enum AuditRunStatus { IDLE RUNNING COMPLETED FAILED }
  type AuditDirectory {
    key: Int
    dirName: String!
    dir: String!
    dirCreated: DateTime
    dirUpdated: DateTime
  }
  type AuditType { atKey: Int atName: String }
  type AuditExecutionResult { started: Boolean! alreadyRunning: Boolean! message: String }
  input AuditCreateInput {
    adtName: String!
    adtDate: DateTime
    adtResults: String
    adtDir: Int!
    adtType: Int!
    adtAddRA: Boolean!
  }
  input AuditUpdateInput {
    adtName: String!
    adtDate: DateTime
    adtResults: String
    adtDir: Int!
    adtType: Int!
    adtAddRA: Boolean!
  }
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
- Зарегистрировать скаляр `DateTime` в `com.femsq.web.config.GraphQlConfig`:
  ```java
  // Добавить второй @Bean рядом с существующим uuidScalarConfigurer()
  @Bean
  public RuntimeWiringConfigurer dateTimeScalarConfigurer() {
      return builder -> builder.scalar(ExtendedScalars.DateTime);
  }
  ```
  `graphql-java-extended-scalars` уже в `pom.xml`; `ExtendedScalars.DateTime` сериализует
  `LocalDateTime` в ISO-8601 и десериализует обратно автоматически.
- В `RaAGraphqlController` (п.1.2) использовать **существующие** `RaACreateRequest` и
  `RaAUpdateRequest` как тип аргумента `@Argument` — Spring GraphQL сопоставит поля
  `AuditCreateInput`/`AuditUpdateInput` напрямую, новые Java-классы для GraphQL-ввода
  **не нужны**.

**Ожидаемый результат:** файл `ra-schema.graphqls` содержит все типы домена `ra_a/ra_at/ra_dir`
с корректными типами полей; `DateTime` скаляр зарегистрирован; схема компилируется без ошибок.

##### Результат (исполнено)

- Создан `code/femsq-backend/femsq-web/src/main/resources/graphql/ra-schema.graphqls`:
  `scalar DateTime`, типы `Audit`, `AuditRunStatus`, `AuditDirectory`, `AuditType`,
  `AuditExecutionResult`, инпуты `AuditCreateInput`/`AuditUpdateInput`,
  `extend type Query` (4 запроса) и `extend type Mutation` (4 мутации).
- В `GraphQlConfig.java` добавлен `@Bean dateTimeScalarConfigurer()` →
  `ExtendedScalars.DateTime`; новый импорт не потребовался.

### 1.2. Создать `RaAGraphqlController` ✅

#### 1.2.1. Создать DTO результата запуска ревизии (`AuditExecutionResult`) ✅

**Задачи:**
- Создать `com.femsq.web.api.dto.AuditExecutionResult` как Java `record`:
  - `started: boolean`
  - `alreadyRunning: boolean`
  - `message: String` (nullable)

**Ожидаемый результат:** `AuditExecutionResult` доступен для использования в GraphQL-мутации `executeAudit`.

##### Результат (исполнено)

- Создан `code/femsq-backend/femsq-web/src/main/java/com/femsq/web/api/dto/AuditExecutionResult.java`:
  `record AuditExecutionResult(boolean started, boolean alreadyRunning, String message)`.

#### 1.2.2. Реализовать Query-операции домена ревизий ✅

**Задачи:**
- В `com.femsq.web.api.graphql.RaAGraphqlController` (`@Controller`) реализовать:
  - `@QueryMapping audits()` — список всех ревизий;
  - `@QueryMapping audit(@Argument int id)` — одна ревизия;
  - `@QueryMapping auditTypes()` — справочник типов;
  - `@QueryMapping directories()` — справочник директорий.

**Ожидаемый результат:** запросы из `extend type Query` (п.1.1) выполняются в GraphiQL.

##### Результат (исполнено)

- Создан `code/femsq-backend/femsq-web/src/main/java/com/femsq/web/api/graphql/RaAGraphqlController.java`:
  реализованы `@QueryMapping` методы `audits`, `audit(id)`, `auditTypes`, `directories`.
- Сборка `mvn -pl femsq-backend/femsq-web -am -DskipTests package` проходит успешно.

#### 1.2.3. Реализовать CRUD-мутации домена ревизий ✅

**Задачи:**
- В `RaAGraphqlController` реализовать:
  - `@MutationMapping createAudit(input)` — создание;
  - `@MutationMapping updateAudit(id, input)` — обновление;
  - `@MutationMapping deleteAudit(id)` — удаление.

**Ожидаемый результат:** CRUD-мутации работают параллельно с существующим REST и проверяются в GraphiQL.

##### Результат (исполнено)

- В `RaAGraphqlController` добавлены `@MutationMapping`:
  - `createAudit(input: RaACreateRequest): RaADto`
  - `updateAudit(id, input: RaAUpdateRequest): RaADto`
  - `deleteAudit(id): boolean` (возвращает `true`, при отсутствии ревизии — NOT_FOUND).
- Сборка `mvn -pl femsq-backend/femsq-web -am -DskipTests package` проходит успешно.

#### 1.2.4. Реализовать мутацию запуска ревизии `executeAudit` ✅

**Задачи:**
- `@MutationMapping executeAudit(@Argument int id)` — возвращает `AuditExecutionResult`:
  - `tryMarkRunning(id)` не прошёл → `{ started: false, alreadyRunning: true, message: ... }`
    (HTTP 409 больше не используется);
  - успех → запуск `auditExecutionService.executeAudit(id)` (асинхронно), вернуть
    `{ started: true, alreadyRunning: false, message: ... }`.

**Ожидаемый результат:** повторный вызов `executeAudit` для уже выполняющейся ревизии возвращает `alreadyRunning: true`.

##### Результат (исполнено)

- В `RaAGraphqlController` добавлена мутация `executeAudit(id): AuditExecutionResult`:
  проверка существования ревизии, защита от повторного запуска через `AuditExecutionRegistry.tryMarkRunning`,
  асинхронный запуск через `AuditExecutionService.executeAudit`.
- Сборка `mvn -pl femsq-backend/femsq-web -am -DskipTests package` проходит успешно.

#### 1.2.5. Реализовать lazy-поля через `@SchemaMapping` ✅

**Задачи:**
- `@SchemaMapping(typeName = "Audit", field = "directory")` — возвращает `AuditDirectory` по `adtDir`.
- `@SchemaMapping(typeName = "Audit", field = "auditType")` — возвращает `AuditType` по `adtType`.

**Ожидаемый результат:** вложенные поля загружаются только при запросе их фронтендом; отсутствует лишняя загрузка справочников.

##### Результат (исполнено)

- В `RaAGraphqlController` добавлены `@SchemaMapping`:
  - `Audit.directory` → загрузка директории по `adtDir`
  - `Audit.auditType` → загрузка типа по `adtType`
- Сборка `mvn -pl femsq-backend/femsq-web -am -DskipTests package` проходит успешно.

**Итоговый ожидаемый результат п.1.2:** `RaAGraphqlController` работает параллельно с REST-контроллерами; все операции проверяются через GraphiQL (`/graphiql`).

##### Результат (исполнено)

- Созданы и успешно собираются:
  - `AuditExecutionResult` (record, п.1.2.1)
  - `RaAGraphqlController` с 4 × `@QueryMapping`, 4 × `@MutationMapping`, 2 × `@SchemaMapping` (пп.1.2.2–1.2.5)
- Дополнительно: в `RaAtService`/`DefaultRaAtService` добавлен метод `getById(int)`;
  резолвер `Audit.auditType` переведён с `getAll().stream().filter()` на `getById`.
- Последняя сборка: `mvn -pl femsq-backend/femsq-web -am -DskipTests package` — **BUILD SUCCESS**.

### 1.3. Проверка сборки бэкенда ✅

**Задачи:**
- Инкрементировать версию JAR.
- Собрать: `mvn -pl femsq-backend/femsq-web -am -DskipTests package`.
- Вручную проверить через GraphiQL: `audits`, `audit(id:12)` с вложенными полями, `executeAudit(id:12)`.
- REST-контроллеры на этом этапе **ещё работают** — фронтенд не поломан.

**Ожидаемый результат:** проект собирается, GraphQL-эндпоинт работает, `adtStatus` передаётся корректно.

##### Результат (исполнено)

- Инкремент версии: `0.1.0.88-SNAPSHOT` → `0.1.0.89-SNAPSHOT` (pom.xml синхронизированы по parent-версиям).
- Сборка: `mvn -pl femsq-backend/femsq-web -am -DskipTests package` — **BUILD SUCCESS**.
- Ручная проверка GraphQL (через HTTP, т.к. UI GraphiQL зависает на “Loading…” при недоступном CDN `unpkg.com`):
  - `audits { adtKey adtName adtStatus }` — список возвращается, `adtStatus` корректен (`IDLE`/`COMPLETED`).
  - `audit(id: 12)` с вложенными `directory` и `auditType` — работает (проверка `@SchemaMapping`).
  - `executeAudit(id: 12)` — возвращает `started=true`.
  - Повторный вызов `executeAudit` может снова вернуть `started=true`, если ревизия завершается слишком быстро;
    при этом `audit(id: 12).adtStatus` после запуска становится `COMPLETED`.

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
- Добавить в `vite.config.ts` в секцию `server.proxy` проксирование `/graphql`:
  ```typescript
  '/graphql': {
    target: 'http://localhost:8080',
    changeOrigin: true,
    secure: false
  }
  ```
  **Обязательно:** без этой записи в dev-режиме (Vite на порту 5175) все GraphQL-запросы
  не достигают backend и возвращают 404 — сейчас `proxy` покрывает только `/api`.

**Ожидаемый результат:** проект собирается без ошибок типов, Apollo Client доступен через `provide`, dev-сервер корректно проксирует `/graphql`.

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
  - `RaAuditDirectoryRestController.java` (`/api/ra/audits/{id}/directory`);
  - `RaDirRestController.java` (`/api/ra/directories` — `getDirectories()` и `getDirectoryById()`).
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
- Импорт `audits-api.ts` остаётся прежним — транспортный слой изменён, интерфейс сохранён.
- Обновить функцию `executeAudit` в сторе:
  - Сейчас: `await auditsApi.executeAudit(id)` возвращает `void`, после чего вызывается `fetchAudits()`.
  - После миграции: `auditsApi.executeAudit(id)` возвращает `AuditExecutionResult { started, alreadyRunning, message }`.
  - Если `result.alreadyRunning === true` — показать `Notify.create` с предупреждением и **не вызывать** `fetchAudits()` / не запускать polling (это не ошибка, обработка через `return`).
  - Если `result.started === true` — поведение прежнее.
- Убедиться, что `pollAuditStatus` использует `fetchPolicy: 'network-only'` в `apolloClient.query` —
  иначе InMemoryCache Apollo будет возвращать устаревшие данные вместо актуального `adtStatus`.

**Ожидаемый результат:** стор корректно обрабатывает оба сценария запуска (`started` и `alreadyRunning`); транспортный слой скрыт за API-интерфейсом.

### 5.2. Проверить прямые вызовы `directoriesApi` в компонентах и сторах

**Задачи:**
- Убедиться, что GraphQL-версия `directories-api.ts` (п.3.2) сохраняет прежние сигнатуры функций
  (`getDirectories`, `getDirectoryById`, `getDirectoryByAuditId`) — это условие корректной работы
  всех потребителей без дополнительных правок.
- **Потребители `directories-api.ts`** (4 файла обращаются к API напрямую):
  - `stores/directories.ts` — `getAllDirectories()`, `getDirectoryById(id)`, `getDirectoryByAuditId(auditId)`;
  - `stores/lookups/directories.ts` — `getDirectories()`;
  - `views/audits/AuditsView.vue` строка 489 — `getDirectoryByAuditId(auditId)` (прямой вызов в компоненте);
  - `components/audits/AuditFilesTab.vue` строка 56 — `getDirectoryByAuditId(auditId)` (прямой вызов в компоненте).
- Проверить, что `handleExecuteAudit` в `AuditsView.vue` корректно обрабатывает `AuditExecutionResult`
  (новый тип возврата после миграции стора).

**Ожидаемый результат:** при сохранении сигнатур в `directories-api.ts` все 4 потребителя
продолжают работать без изменений; `handleExecuteAudit` работает с новым типом.

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
**Версия:** 1.3.0
**Автор:** Александр
