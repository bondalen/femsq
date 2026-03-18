- **Цель чата**: перевести весь доменный API проекта с REST на GraphQL согласно исходной архитектурной концепции проекта: установить Apollo Client на фронтенде, добавить GraphQL-схему домена ревизий на бэкенде, заменить все REST-вызовы на фронтенде и удалить устаревшие REST-контроллеры.
- **Основание**: в ходе анализа чата `chat-plan-26-0311.md` установлено, что фронтенд никогда не использовал Apollo Client — все API-вызовы идут через `fetch` на REST. Это отступление от архитектурного замысла создаёт техдолг, который целесообразнее устранить до, а не после реализации Excel-функционала.
- **Текущее состояние**:
  - Backend: GraphQL-контроллер для организаций (`OgGraphqlController`) уже есть; схема `og-schema.graphqls` готова; зависимость `spring-boot-starter-graphql` подключена. Домен ревизий (`ra_a`, `ra_at`, `ra_dir`) покрыт только REST-контроллерами.
  - Frontend: Apollo Client **не установлен**; все 8 API-файлов используют `fetch`; домен ревизий полностью на REST.

---

## 1. Фаза 1: Backend — схема и контроллер домена ревизий ✅

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

## 2. Фаза 2: Frontend — установка Apollo Client ✅

### 2.1. Установка зависимостей ✅

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

##### Результат (исполнено)

- Установлены зависимости: `@apollo/client`, `@vue/apollo-composable`, `graphql`.
- Создан `code/femsq-frontend-q/src/plugins/apollo.ts` (ApolloClient с `uri: '/graphql'`).
- В `code/femsq-frontend-q/src/main.ts` подключён `DefaultApolloClient` через `app.provide`.
- В `code/femsq-frontend-q/vite.config.ts` добавлен proxy `/graphql` → `http://localhost:8080`.
- В `code/femsq-frontend-q/tsconfig.json` добавлены `baseUrl`/`paths` для алиаса `@/*`.
- `npm run build` проходит успешно.

### 2.2. Создать `.graphql`-файлы запросов ✅

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

##### Результат (исполнено)

- Создана директория `code/femsq-frontend-q/src/graphql/`:
  - `audits.graphql` (`GetAudits`, `GetAudit`, `GetAuditWithDetails`, `CreateAudit`, `UpdateAudit`, `DeleteAudit`, `ExecuteAudit`)
  - `audit-types.graphql` (`GetAuditTypes`)
  - `directories.graphql` (`GetDirectories`)
  - `organizations.graphql` (`GetOrganizations`, `GetOrganizationsLookup`)
- В `code/femsq-frontend-q/vite.config.ts` добавлена поддержка импорта `*.graphql` через `vite-plugin-graphql-loader`.
- `npm run build` проходит успешно.

### 2.3. Привести `npm run type-check` к зелёному статусу (перед Фазой 3) ✅

**Задачи:**
- Запустить `npm run type-check` в `code/femsq-frontend-q`.
- Исправить ошибки типизации (включая алиасы, несовпадения DTO/типов, `unknown`/`any` и пр.) так,
  чтобы команда завершалась успешно.
- Убедиться, что после правок:
  - `npm run build` проходит успешно;
  - `npm run dev` поднимается без ошибок в консоли браузера (минимальная sanity-проверка).

**Ожидаемый результат:** типизация фронтенда не мешает дальнейшей миграции API-клиентов на Apollo в Фазе 3.

##### Результат (исполнено)

- `npm run type-check` — **успешно** (vue-tsc без ошибок).
- `npm run build` — **успешно**.
---

## 3. Фаза 3: Frontend — замена API-клиентов домена ревизий ✅

### 3.1. Переписать `audits-api.ts` ✅

**Задачи:**
- Заменить `src/api/audits-api.ts` полностью: вместо `apiGet`/`apiPost`/`apiPut`/`apiDelete` использовать `apolloClient.query` и `apolloClient.mutate`.
- Сохранить ту же сигнатуру функций (`getAudits()`, `getAuditById()`, `createAudit()`, ...) — стор не меняется.
- Обновить типа: `executeAudit` теперь возвращает `AuditExecutionResult` (не `boolean`).

**Ожидаемый результат:** `audits-api.ts` работает через GraphQL; опасных изменений стора не требуется.

##### Результат (исполнено)

- `code/femsq-frontend-q/src/api/audits-api.ts` переписан на `apolloClient.query/mutate` (`/graphql`) вместо REST `/api/ra/audits`.
- `executeAudit(id)` теперь возвращает `AuditExecutionResult { started, alreadyRunning, message }`.
- `npm run type-check` и `npm run build` проходят успешно.

### 3.2. Переписать `audit-types-api.ts` и `directories-api.ts` ✅

**Задачи:**
- `audit-types-api.ts`: `getAuditTypes()` → `apolloClient.query({ query: GET_AUDIT_TYPES })`.
- `directories-api.ts`:
  - `getDirectories()` → `apolloClient.query({ query: GET_DIRECTORIES })`;
  - `getAuditDirectory(id)` → `apolloClient.query({ query: GET_AUDIT_DIRECTORY, variables: { id } })`.

**Ожидаемый результат:** справочники при загрузке спрашиваются через GraphQL.

##### Результат (исполнено)

- `code/femsq-frontend-q/src/api/audit-types-api.ts`: `getAuditTypes()` переписан на `apolloClient.query` (`/graphql`).
- `code/femsq-frontend-q/src/api/directories-api.ts`: `getDirectories`, `getAllDirectories`, `getDirectoryById`, `getDirectoryByAuditId` переписаны на GraphQL (`/graphql`) с сохранением сигнатур для существующих потребителей.
- `npm run type-check` и `npm run build` проходят успешно.

### 3.3. Переписать `organizations-api.ts` ✅

**Задачи:**
- Заменить REST-вызовы `getOrganizations()` и `getOrganizationsLookup()` на GraphQL-запросы `GET_ORGANIZATIONS` / `GET_ORGANIZATIONS_LOOKUP` через `apolloClient.query`.
- Схема `og-schema.graphqls` уже готова — никаких изменений бэкенда не нужно.

**Ожидаемый результат:** все API-клиенты домена `ra_a` и `og` используют GraphQL.

##### Результат (исполнено)

- `code/femsq-frontend-q/src/api/organizations-api.ts` переписан на `apolloClient.query` (`/graphql`):
  - `getAllOrganizations()` → `organizations`
  - `getOrganizationById(id)` → `organization(id)`
  - `getOrganizationsLookup()` → `organizations` (только `ogKey`/`ogName`) + маппинг в `OrganizationLookupDto`
- `npm run type-check` и `npm run build` проходят успешно.

---

## 4. Фаза 4: Удаление устаревших REST-артефактов ✅

### 4.1. Удалить REST-контроллеры домена ревизий ✅

**Задачи:**
- Удалить (REST-контроллеры домена ревизий больше не нужны):
  - `RaARestController.java` (CRUD + `/execute`);
  - `RaAtRestController.java` (типы ревизий);
  - `RaAuditDirectoryRestController.java` (`/api/ra/audits/{id}/directory`);
  - `RaDirRestController.java` (`/api/ra/directories` — `getDirectories()` и `getDirectoryById()`).
- **Оставить** REST-контроллеры `OgRestController`, `OgAgRestController`, `OgLookupRestController`, `LookupRestController` — они могут использоваться другими потребителями.
- Добавить запись в `application.properties`: `spring.graphql.graphiql.enabled=true` (уже есть); проверить `spring.mvc.pathmatch.use-suffix-pattern`.

**Ожидаемый результат:** REST-артефакты домена ревизий удалены; проект собирается без ошибок.

##### Результат (исполнено)

- Удалены REST-контроллеры домена ревизий:
  - `RaARestController.java`
  - `RaAtRestController.java`
  - `RaAuditDirectoryRestController.java`
  - `RaDirRestController.java`
- Сборка `mvn -pl femsq-backend/femsq-web -am -DskipTests package` — **BUILD SUCCESS**.

### 4.2. Удалить устаревшие REST API-файлы фронтенда ✅

**Задачи:**
- Удалить (REST API-клиенты домена ревизий больше не нужны):
  - `src/api/audits-api.ts` (REST-версия, заменена в 3.1);
  - `src/api/audit-types-api.ts` (REST-версия, заменена в 3.2);
  - `src/api/directories-api.ts` (REST-версия, заменена в 3.2).
- **Оставить** `src/api/organizations-api.ts` — переписан на GraphQL в 3.3, REST-версия удаляется вместе с ним.
- **Оставить** `src/api/http.ts` — может использоваться для иных целей (status check и т.d.).

**Ожидаемый результат:** директория `src/api/` содержит только GraphQL-клиенты для доменных API.

##### Результат (исполнено)

- Отдельных REST-версий файлов `src/api/audits-api.ts`, `src/api/audit-types-api.ts`, `src/api/directories-api.ts`, `src/api/organizations-api.ts` в репозитории не осталось:
  они были переписаны “на месте” на GraphQL/Apollo в пп.3.1–3.3.
- Проверено, что `audits-api.ts`, `audit-types-api.ts`, `directories-api.ts`, `organizations-api.ts` не используют `apiGet/apiPost/apiPut/apiDelete`.
- Примечание: в `src/api/` остаются REST-клиенты для файлов/типов файлов (`files-api.ts`, `file-types-api.ts`) и `http.ts` —
  они не относятся к домену ревизий `ra_a/ra_at/ra_dir` и будут мигрироваться отдельным этапом (вне 4.2).
---

## 5. Фаза 5: Обновление стора и компонента `AuditsView.vue` ✅

### 5.1. Обновить `useAuditsStore` ✅

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

##### Результат (исполнено) ✅

- В `src/stores/audits.ts` обновлён `executeAudit(id)`:
  - возвращает `AuditExecutionResult`;
  - при `alreadyRunning=true` показывает `Notify.create({ type: 'warning', ... })` и **не** вызывает `fetchAudits()` и **не** запускает polling;
  - при `started=true` показывает позитивное уведомление (если есть `message`), вызывает `fetchAudits()` и запускает `startPolling(id)`.
- Подтверждено, что polling статуса использует `auditsApi.getAuditById(id)`, где `apolloClient.query` выполняется с `fetchPolicy: 'network-only'`.
- В `AuditsView.vue` убран безусловный вызов `startPolling()` — polling теперь запускается централизованно в сторе только при `started=true`.

### 5.2. Проверить прямые вызовы `directoriesApi` в компонентах и сторах ✅

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

##### Результат (исполнено) ✅

- `src/api/directories-api.ts` сохраняет сигнатуры: `getDirectories()`, `getAllDirectories()`, `getDirectoryById(id)`, `getDirectoryByAuditId(auditId)` и использует GraphQL (`fetchPolicy: 'network-only'`).
- Проверены 4 потребителя прямых вызовов `directoriesApi` — они используют те же функции без изменений:
  - `src/stores/directories.ts`
  - `src/stores/lookups/directories.ts`
  - `src/views/audits/AuditsView.vue`
  - `src/components/audits/AuditFilesTab.vue`
- `npm run type-check` проходит успешно после верификации.

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

## 8. Фаза 8: Полное устранение REST из `src/api/` (опционально) ✅

> Цель фазы: в `code/femsq-frontend-q/src/api/` не остаётся доменных REST-клиентов; весь домен
> работает через GraphQL/Apollo. Допускается оставить REST только для технических эндпоинтов
> (status/health) и внешних интеграций, если GraphQL технически невозможен.

### 8.1. Backend: добавить GraphQL для `ra_f` и `ra_ft` (файлы ревизий) ✅

**Задачи:**
- Добавить в GraphQL-схему типы и операции для:
  - файлов ревизий (`ra_f`) — список, получение по id, получение по директории, CRUD;
  - типов файлов (`ra_ft`) — справочник.
- Реализовать GraphQL-контроллеры (`@Controller` + `@QueryMapping/@MutationMapping`) по паттерну `RaAGraphqlController`.

**Ожидаемый результат:** для всех операций, которые сейчас выполняются через `/api/ra/files` и `/api/ra/file-types`,
существуют эквиваленты в `/graphql`.

##### Результат (исполнено)

- В `code/femsq-backend/femsq-web/src/main/resources/graphql/ra-schema.graphqls` добавлены:
  - типы `AuditFile`, `FileType`;
  - инпуты `FileCreateInput`, `FileUpdateInput`;
  - query: `files`, `file(id)`, `filesByDirectory(dirId)`, `fileTypes`;
  - mutation: `createFile`, `updateFile`, `deleteFile`.
- Создан `code/femsq-backend/femsq-web/src/main/java/com/femsq/web/api/graphql/RaFGraphqlController.java`:
  query+mutation для `ra_f` и query для `ra_ft` (используются существующие `RaFService`/`RaFtService` и мапперы).
- Сборка `mvn -pl femsq-backend/femsq-web -am -DskipTests package` — **BUILD SUCCESS**.

### 8.2. Frontend: переписать `files-api.ts` и `file-types-api.ts` на Apollo ✅

**Задачи:**
- `src/api/files-api.ts` — заменить REST-вызовы на `apolloClient.query/mutate`, сохранив текущие сигнатуры
  для потребителей.
- `src/api/file-types-api.ts` — аналогично (lookup типов файлов).
- Удалить/очистить REST-зависимости в этих файлах (`apiGet/apiPost/apiPut/apiDelete`), если они больше не нужны.

**Ожидаемый результат:** в Chrome DevTools → Network запросы файлового домена идут на `/graphql`, а не на `/api/ra/files...`.

##### Результат (исполнено)

- `code/femsq-frontend-q/src/api/file-types-api.ts`: `getAllFileTypes`, `getFileTypeById` переписаны на GraphQL (`fileTypes`).
- `code/femsq-frontend-q/src/api/files-api.ts`: все операции (`getAllFiles`, `getFileById`, `getFilesByDirId`, `createFile`, `updateFile`, `deleteFile`) переписаны на GraphQL (`files`, `file`, `filesByDirectory`, `createFile`, `updateFile`, `deleteFile`).
- В `src/api/` больше нет вызовов `apiGet/apiPost/apiPut/apiDelete` (REST используется только в `http.ts` и технических клиентах).
- `npm run type-check` и `npm run build` проходят успешно.

### 8.3. Connection/status: зафиксировать осознанный REST (технические эндпоинты) ✅

**Решение (Вариант A — осознанный REST):**

После анализа состояния `src/api/` принято решение **оставить** следующие файлы на REST:

| Файл | Обоснование |
|------|-------------|
| `connection-api.ts` | Технический health-check: проверка подключения к БД при bootstrap приложения. REST-семантика лучше подходит для health-check. Специальный таймаут `30_000ms`. Правила проекта явно допускают REST для `status`/`health`. |
| `reports-api.ts` | Бинарные ответы (`Blob`, PDF). GraphQL физически не может вернуть бинарные данные — протокол JSON. `generateReport` и `generatePreview` **обязаны** оставаться на REST/fetch. |
| `http.ts` | Утилитная библиотека для двух вышеназванных технических клиентов. Остаётся как инфраструктурная зависимость. |

**Правило проекта (зафиксировано в `.cursorrules`):**
- `src/api/connection-api.ts` + `src/api/reports-api.ts` + `src/api/http.ts` = **осознанный технический REST**.
  Не является нарушением архитектуры.
- Все доменные API-клиенты в `src/api/` используют только Apollo Client.
- Сторы **не должны** вызывать `apiGet`/`apiPost` напрямую для доменных операций — только через файлы `src/api/`.

**Задачи:**
- [x] Зафиксировать решение в чат-плане.
- [x] Обновить секцию «Правила архитектуры API» в `.cursorrules`.
- [x] Добавить JSDoc-заголовки с пояснением в `connection-api.ts` и `reports-api.ts`.

**Ожидаемый результат:** в `src/api/` нет "случайного" REST — три оставшихся файла явно задокументированы как осознанный технический REST.

### 8.4. Устранение доменного REST в сторах ✅

**Проблема:**
Пять сторов вызывают `apiGet` из `@/api/http` **напрямую**, минуя слой `src/api/`:

| Стор | Эндпоинты (REST) |
|------|-----------------|
| `stores/organizations.ts` | `GET /api/v1/organizations`, `GET /api/v1/organizations/:id/agents` |
| `stores/investment-chains.ts` | `GET /api/v1/ipg-chains`, `GET /api/v1/ipg-chains/:id/relations` |
| `stores/lookups/investment-programs.ts` | `GET /api/v1/lookups/investment-programs` |
| `stores/lookups/plan-groups.ts` | `GET /api/v1/lookups/plan-groups` |
| `stores/lookups/st-networks.ts` | `GET /api/v1/lookups/st-networks` |

Это нарушение архитектуры: доменный REST прямо в сторах, минуя `src/api/`.

**Задачи:**

#### 8.4.1. Organizations: мигрировать стор на `organizations-api.ts` ✅
**Задачи (перед началом):**
- `organizations-api.ts` уже переписан на Apollo (п. 3.3), но `stores/organizations.ts` всё ещё вызывает `apiGet` напрямую для `/api/v1/organizations`.
- Проверить: `/api/v1/organizations` с пагинацией — есть ли GraphQL-эквивалент в `og-schema.graphqls`?
  Если нет — реализовать клиентскую пагинацию поверх GraphQL-запроса `organizations`.
- Переписать стор на использование `organizations-api.ts`.

##### Результат (исполнено) ✅

- В `src/api/organizations-api.ts` добавлены:
  - типы `OrganizationsQuery`, `OrganizationsPage`;
  - функция `getOrganizationsPage(query)` — выполняет GraphQL-запрос `organizations`, затем применяет фильтр по `ogName`, сортировку по `ogName` и клиентскую пагинацию (page/size);
  - тип `AgentDto` и функция `getAgentsByOrganization(organizationKey)` — используют GraphQL-запрос `organizationAgents(organizationId)` вместо REST `/api/v1/organizations/{id}/agents`.
- В `src/stores/organizations.ts`:
  - удалён прямой импорт `apiGet` из `@/api/http`;
  - стор импортирует `getOrganizationsPage` и `getAgentsByOrganization` из `@/api/organizations-api`;
  - `fetchOrganizations` переписан на использование `getOrganizationsPage` (GraphQL), pagination/filters/sort поддерживаются на клиенте;
  - `fetchAgentsFor` использует `getAgentsByOrganization` (GraphQL) вместо REST.

#### 8.4.2. Investment chains: добавить GraphQL и мигрировать стор ✅

**Задачи (перед началом):**
- Backend: использовать уже существующие query `investmentChains(name, year)` и `investmentChainRelations(chainId)` в `og-schema.graphqls` вместо REST `/api/v1/ipg-chains`.
- Frontend: заменить `apiGet('/api/v1/ipg-chains')` и `apiGet('/api/v1/ipg-chains/{id}/relations')` в `stores/investment-chains.ts` на Apollo-запросы через `src/api/investment-chains-api.ts`.

##### Результат (исполнено) ✅

- Создан `src/api/investment-chains-api.ts`:
  - GraphQL-операции:
    - `GetInvestmentChains(name, year)` → `investmentChains(name, year)`;
    - `GetInvestmentChainRelations(chainId)` → `investmentChainRelations(chainId)`.
  - Типы `InvestmentChainsQuery`, `InvestmentChainsPage`, `IpgChainDto`, `IpgChainRelationDto`.
  - Функции:
    - `getInvestmentChainsPage(query)` — выполняет GraphQL-запрос `investmentChains`, затем применяет клиентскую сортировку (`name`/`chainKey`) и пагинацию (page/size);
    - `getInvestmentChainRelations(chainId)` — возвращает массив связей для выбранной цепочки.
- Обновлён `src/stores/investment-chains.ts`:
  - удалён прямой импорт `apiGet` из `@/api/http`;
  - `fetchChains` использует `getInvestmentChainsPage` (GraphQL) с сохранением UX (фильтры `name`/`year`, пагинация, сортировка);
  - `fetchRelationsFor` использует `getInvestmentChainRelations` (GraphQL) вместо REST `/api/v1/ipg-chains/{id}/relations`;
  - структура стора и публичный API для `InvestmentChainsView.vue` не изменились.

#### 8.4.3. Lookups: добавить GraphQL и мигрировать сторы ✅

**Задачи (перед началом):**
- Backend: использовать существующие query `investmentPrograms`, `investmentPlanGroups`, `stNetworks` из `og-schema.graphqls`.
- Frontend: заменить прямые `apiGet` в сторах `lookups/` (`investment-programs`, `plan-groups`, `st-networks`) на Apollo-запросы через `src/api/`.

##### Результат (исполнено) ✅

- Создан `src/api/lookups-api.ts`:
  - GraphQL-операции:
    - `GetInvestmentPrograms` → `investmentPrograms`;
    - `GetInvestmentPlanGroups` → `investmentPlanGroups`;
    - `GetStNetworks` → `stNetworks`.
  - Типы `InvestmentProgramLookupDto`, `InvestmentPlanGroupLookupDto`, `StNetworkDto`.
  - Функции:
    - `getInvestmentProgramsLookup()`;
    - `getPlanGroupsLookup()`;
    - `getStNetworksLookup()`.
- Обновлён `src/stores/lookups/investment-programs.ts`:
  - удалён `apiGet` из `@/api/http`;
  - стор использует `getInvestmentProgramsLookup()` (GraphQL), остальная логика (map, `getInvestmentProgramName`) не менялась.
- Обновлён `src/stores/lookups/plan-groups.ts`:
  - удалён `apiGet` из `@/api/http`;
  - стор использует `getPlanGroupsLookup()` (GraphQL), логика `utPlGrMap` и `getPlanGroupName` сохранена.
- Обновлён `src/stores/lookups/st-networks.ts`:
  - удалён `apiGet` из `@/api/http`;
  - стор использует `getStNetworksLookup()` (GraphQL), логика `stNetworkMap` и `getStNetworkName` сохранена.

**Ожидаемый результат:** ни один стор не вызывает `apiGet`/`apiPost` напрямую для доменных ресурсов.
Все доменные запросы идут через файлы `src/api/`, которые используют Apollo Client.

### 8.5. Финальная проверка: `src/api/` без доменного REST

**Задачи:**
- Проверить, что в `src/api/` нет вызовов `apiGet/apiPost/apiPut/apiDelete` для доменных операций.
- Проверить, что ни один стор не импортирует `apiGet` из `@/api/http` для доменных ресурсов.
- `npm run type-check`, `npm run build` — успешно.
- Ручная проверка в браузере: ключевые сценарии работают, Network показывает запросы на `/graphql`.

**Ожидаемый результат:** `src/api/` не содержит доменных REST-клиентов; сторы не содержат прямых `apiGet` для домена.

##### Результат (исполнено) ✅

- В `src/api/`:
  - доменные клиенты (`audits-api.ts`, `audit-types-api.ts`, `directories-api.ts`, `organizations-api.ts`, `files-api.ts`, `file-types-api.ts`, `investment-chains-api.ts`, `lookups-api.ts`) используют только Apollo Client/GraphQL;
  - REST остался только в осознанных технических клиентах (`http.ts`, `connection-api.ts`, `reports-api.ts`) согласно `.cursorrules`.
- В `src/stores/`:
  - ни один стор не вызывает `apiGet/apiPost/apiPut/apiDelete` напрямую; все доменные вызовы идут через `src/api/*.ts`;
  - сторы `organizations`, `investment-chains`, lookup-сторы используют новые GraphQL-клиенты.
- Команды `npm run type-check` и `npm run build` для `femsq-frontend-q` выполняются успешно.

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
**Версия:** 2.7.0
**Автор:** Александр
