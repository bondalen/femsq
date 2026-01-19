# Анализ компонентов для этапа 3.1

**Дата:** 2026-01-19  
**Цель:** Проверка готовности компонентов к интеграции в AuditsViewV53.vue

---

## Обнаруженные компоненты

### 1. AuditFilesTab.vue
**Расположение:** `code/femsq-frontend-q/src/components/audits/AuditFilesTab.vue`

**Зависимости:**
- `useDirectoriesStore` из `@/stores/directories` ❌ (несовместимо с версией .53)
- `DirectoryInfo` компонент
- `FilesList` компонент

**Проблемы:**
- Использует store версии .68 (`@/stores/directories`)
- В версии .53 используется `@/stores/lookups/directories`
- Компоненты временно скрыты флагами `showDirectoryInfo` и `showFilesList` (false)

**Требуется адаптация:**
- Изменить импорт store на `@/stores/lookups/directories`
- Адаптировать методы store (использовать `fetchDirectories` вместо `loadByAuditId`)
- Убрать временные флаги скрытия

---

### 2. DirectoryInfo.vue
**Расположение:** `code/femsq-frontend-q/src/components/audits/DirectoryInfo.vue`

**Зависимости:**
- `DirectoryDto` из `@/types/files` ❌ (несовместимо с версией .53)

**Проблемы:**
- Использует тип `DirectoryDto` (версия .68)
- В версии .53 используется `RaDirDto` из `@/types/audits`
- Различия в полях:
  - `DirectoryDto.path` → `RaDirDto.dir` (путь)
  - `DirectoryDto.created` → `RaDirDto.dirCreated`
  - `DirectoryDto.updated` → `RaDirDto.dirUpdated`

**Требуется адаптация:**
- Изменить тип props с `DirectoryDto` на `RaDirDto`
- Изменить `directory.path` на `directory.dir`
- Изменить `directory.created` на `directory.dirCreated`
- Изменить `directory.updated` на `directory.dirUpdated`

---

### 3. FilesList.vue
**Расположение:** `code/femsq-frontend-q/src/components/audits/FilesList.vue`

**Зависимости:**
- `useFilesStore` из `@/stores/files` ✅ (совместимо)
- `useLookupsStore` из `@/stores/lookups` ✅ (совместимо)
- `FileEditDialog` компонент
- Типы `RaFDto`, `RaFCreateRequest`, `RaFUpdateRequest` из `@/types/files` ✅ (совместимо)

**Статус:** ✅ Готов к использованию (не требует изменений)

---

### 4. FileEditDialog.vue
**Расположение:** `code/femsq-frontend-q/src/components/audits/FileEditDialog.vue`

**Зависимости:**
- `useLookupsStore` из `@/stores/lookups` ✅ (совместимо)
- Типы `RaFDto`, `RaFCreateRequest`, `RaFUpdateRequest` из `@/types/files` ✅ (совместимо)

**Статус:** ✅ Готов к использованию (не требует изменений)

---

## Итоговый статус компонентов

| Компонент | Статус | Требуемые изменения |
|-----------|--------|---------------------|
| AuditFilesTab.vue | ⚠️ Требует адаптации | Изменить store на `@/stores/lookups/directories`, убрать флаги скрытия |
| DirectoryInfo.vue | ⚠️ Требует адаптации | Изменить тип на `RaDirDto`, адаптировать поля |
| FilesList.vue | ✅ Готов | Нет изменений |
| FileEditDialog.vue | ✅ Готов | Нет изменений |

---

## План адаптации

### Шаг 1: Адаптация DirectoryInfo.vue
1. Изменить импорт типа: `DirectoryDto` → `RaDirDto`
2. Изменить props: `directory: DirectoryDto | null` → `directory: RaDirDto | null`
3. Изменить поля в template:
   - `directory.path` → `directory.dir`
   - `directory.created` → `directory.dirCreated`
   - `directory.updated` → `directory.dirUpdated`

### Шаг 2: Адаптация AuditFilesTab.vue
1. Изменить импорт store: `@/stores/directories` → `@/stores/lookups/directories`
2. Адаптировать методы:
   - `directoriesStore.loadByAuditId()` → использовать API напрямую или адаптер
3. Убрать временные флаги `showDirectoryInfo` и `showFilesList` (установить в `true`)
4. Адаптировать передачу props в `DirectoryInfo` (использовать `RaDirDto`)

---

## Проверка API

**directories-api.ts:**
- ✅ `getDirectories()` возвращает `RaDirDto[]`
- ✅ `getDirectoryById()` возвращает `RaDirDto`
- ✅ `getDirectoryByAuditId()` возвращает `RaDirDto`
- ✅ Есть адаптер `getAllDirectories()` для совместимости с `DirectoryDto`

**Вывод:** API готов, но компоненты нужно адаптировать для использования `RaDirDto`.

---

**Дата создания:** 2026-01-19
