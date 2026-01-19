# Анализ проблемы: пустой список организаций в FileEditDialog

**Дата:** 2026-01-19  
**Проблема:** При создании файла невозможно выбрать организацию в выпадающем списке - список открывается пустым.

---

## Текущая реализация

### 1. FileEditDialog.vue

**Загрузка справочников:**
- При открытии диалога (`watch` на `props.modelValue`) вызывается `loadLookups()` (строка 154)
- `loadLookups()` вызывает `lookupsStore.loadAllLookups()` (строка 175)
- `loadAllLookups()` загружает и типы файлов, и организации через `Promise.all`

**Использование организаций:**
- `organizationsOptions` - computed property, который берёт данные из `lookupsStore.organizationsOptions` (строка 147)
- `organizationsOptions` используется в `q-select` для поля "Отправитель" (строка 42)

### 2. lookups.ts (Store)

**Метод `loadOrganizations`:**
```typescript
async function loadOrganizations(force = false) {
  if (organizationsLoaded.value && !force) {
    return organizations.value  // ⚠️ Возвращает уже загруженные данные (может быть пустой массив)
  }
  
  loadingOrganizations.value = true
  try {
    const data = await organizationsApi.getOrganizationsLookup()
    organizations.value = data
    organizationsLoaded.value = true
    return data
  } catch (err) {
    console.error('Failed to load organizations:', err)
    throw err
  } finally {
    loadingOrganizations.value = false
  }
}
```

**Проблема:** Если первая загрузка завершилась с ошибкой или вернула пустой массив, флаг `organizationsLoaded.value = true` всё равно устанавливается, и повторная загрузка не произойдёт без `force = true`.

**Метод `loadAllLookups`:**
```typescript
async function loadAllLookups(force = false) {
  await Promise.all([
    loadFileTypes(force),
    loadOrganizations(force)
  ])
}
```

### 3. organizations-api.ts

**Метод `getOrganizationsLookup`:**
```typescript
export async function getOrganizationsLookup(): Promise<OrganizationLookupDto[]> {
  const orgs = await apiGet<OrganizationDto[]>('/api/og')
  // Преобразуем в упрощенный формат для lookup
  return orgs.map((org) => ({
    ogKey: org.ogKey,
    ogNm: org.ogNm
  }))
}
```

**Проблема:** Если API `/api/og` возвращает пустой массив или ошибку, то и `getOrganizationsLookup()` вернёт пустой массив.

### 4. FilesList.vue

**Загрузка при монтировании:**
- `watch` на `props.dirId` с `immediate: true` вызывает `loadAllLookups()` (строка 324)
- Это означает, что при загрузке компонента `FilesList` справочники должны загружаться

---

## Возможные причины проблемы

### 1. ⚠️ API возвращает пустой массив
- Backend endpoint `/api/og` может возвращать пустой массив
- Нужно проверить, есть ли организации в БД
- Нужно проверить, правильно ли работает backend endpoint

### 2. ⚠️ Ошибка при загрузке не обрабатывается
- Если `getOrganizationsLookup()` выбрасывает ошибку, она ловится в `loadOrganizations()`, но:
  - Ошибка только логируется в консоль (`console.error`)
  - `organizationsLoaded.value` НЕ устанавливается в `true` при ошибке
  - Но если ошибка происходит после установки флага, то повторная загрузка не произойдёт

### 3. ⚠️ Проблема с флагом `organizationsLoaded`
- Если первая загрузка вернула пустой массив (но без ошибки), флаг устанавливается в `true`
- При последующих вызовах `loadOrganizations()` без `force = true` данные не перезагружаются
- `FileEditDialog` вызывает `loadAllLookups()` без параметра `force`, поэтому если данные уже были загружены (даже пустые), повторная загрузка не произойдёт

### 4. ⚠️ Проблема с timing
- `FileEditDialog` вызывает `loadLookups()` при открытии диалога
- Но если диалог открывается очень быстро после монтирования `FilesList`, может быть race condition
- Если `FilesList` ещё не завершил загрузку, а `FileEditDialog` уже открылся, данные могут быть не готовы

### 5. ⚠️ Проблема с форматом данных
- API может возвращать данные в неправильном формате
- `OrganizationDto` может не содержать поля `ogKey` или `ogNm`
- Преобразование в `OrganizationLookupDto` может не работать корректно

---

## Рекомендации по диагностике

### 1. Проверить консоль браузера
- Открыть DevTools → Console
- Проверить, есть ли ошибки при загрузке организаций
- Проверить, вызывается ли `getOrganizationsLookup()`

### 2. Проверить Network tab
- Открыть DevTools → Network
- Найти запрос к `/api/og`
- Проверить:
  - Статус ответа (200, 404, 500?)
  - Тело ответа (пустой массив `[]` или есть данные?)
  - Формат данных

### 3. Проверить состояние store
- В консоли браузера выполнить:
  ```javascript
  // Получить store
  const store = useLookupsStore()
  // Проверить состояние
  console.log('Organizations:', store.organizations)
  console.log('Organizations loaded:', store.organizationsLoaded)
  console.log('Organizations options:', store.organizationsOptions)
  ```

### 4. Проверить backend
- Проверить, что endpoint `/api/og` существует и работает
- Проверить, что в БД есть организации
- Проверить логи backend при запросе

---

## Предполагаемые решения

### Решение 1: Исправить обработку ошибок
- Не устанавливать `organizationsLoaded = true` при ошибке
- Добавить явную обработку ошибок в `FileEditDialog`

### Решение 2: Всегда загружать при открытии диалога
- Изменить `loadLookups()` в `FileEditDialog`:
  ```typescript
  async function loadLookups() {
    await lookupsStore.loadAllLookups(true); // force = true
  }
  ```

### Решение 3: Добавить состояние загрузки в UI
- Показывать индикатор загрузки в `q-select` для организаций
- Показывать сообщение, если список пустой

### Решение 4: Проверить и исправить API
- Убедиться, что backend endpoint `/api/og` возвращает данные
- Проверить формат данных

---

**Дата создания:** 2026-01-19
