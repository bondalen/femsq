# Анализ различий между версиями .53 и .68

**Дата анализа:** 2026-01-19  
**Версия .53:** AuditsViewV53.vue (595 строк)  
**Версия .68:** AuditsView.vue (533 строки)

---

## 1. Computed Properties

### Версия .53:
- `sortedAudits`: сортировка по имени (`localeCompare`)
- `auditTypesOptions`: прямое обращение к store
- `directoriesOptions`: прямое обращение к store
- `isFormValid`: проверяет дату И время

### Версия .68:
- `sortedAudits`: сортировка по дате (новые сверху) - **УЛУЧШЕНИЕ**
- `selectedAudit`: computed из store (реактивность) - **УЛУЧШЕНИЕ**
- `auditTypesOptions`: прямое обращение к store
- `directoriesOptions`: прямое обращение к store
- `isFormValid`: проверяет только дату (время опционально) - **УЛУЧШЕНИЕ**

---

## 2. Методы обработки данных

### `handleSelectAudit`:

**Версия .53:**
```typescript
async function handleSelectAudit(id: number): Promise<void> {
  if (selectedAuditId.value === id && selectedAudit.value) {
    return; // Проверка дублирования
  }
  // Загружает через API fetchAuditById
  const audit = await auditsStore.fetchAuditById(id);
  selectedAudit.value = audit;
  loadAuditToForm(audit);
}
```

**Версия .68:**
```typescript
function handleSelectAudit(auditId: number) {
  selectedAuditId.value = auditId;
  isNewAudit.value = false;
  activeTab.value = 'progress';
}
// Использует watch для автоматической загрузки формы
```

**Анализ:** Версия .68 проще, но версия .53 более надежна (загружает свежие данные).  
**Рекомендация:** Оставить подход .53 (загрузка через API), но добавить watch для реактивности.

---

### `formatDate`:

**Версия .53:**
```typescript
function formatDate(dateString: string | null | undefined): string {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleDateString('ru-RU', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}
```
- Полное форматирование с часами и минутами
- Месяц прописью

**Версия .68:**
```typescript
function formatDate(dateString: string | null): string {
  if (!dateString) return '';
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
  } catch {
    return '';
  }
}
```
- Упрощенное форматирование (только дата)
- Обработка ошибок через try-catch

**Анализ:** Версия .53 более информативна, версия .68 безопаснее.  
**Рекомендация:** Использовать версию .53 (полное форматирование), но добавить try-catch из .68.

---

### `validateForm`:

**Версия .53:**
```typescript
function validateForm(): boolean {
  errors.value = {};
  // Проверяет дату И время
  if (!form.value.adtDateDate || !form.value.adtDateTime) {
    errors.value.adtDate = 'Дата и время обязательны для заполнения';
  }
  return Object.keys(errors.value).length === 0;
}
```

**Версия .68:**
```typescript
function validateForm(): boolean {
  errors.value = { adtName: '', adtType: '', adtDir: '', adtDate: '' };
  let valid = true;
  // Проверяет только дату (время опционально)
  if (!form.value.adtDateDate) {
    errors.value.adtDate = 'Введите дату';
    valid = false;
  }
  return valid;
}
```

**Анализ:** Версия .68 более гибкая (время опционально), но версия .53 строже.  
**Рекомендация:** Использовать версию .68 (время опционально), но улучшить сообщения об ошибках из .53.

---

### `handleSave`:

**Версия .53:**
```typescript
async function handleSave(): Promise<void> {
  // ...
  try {
    const adtDate = new Date(`${form.value.adtDateDate}T${form.value.adtDateTime}`).toISOString();
    // ...
    Notify.create({ type: 'positive', message: 'Ревизия успешно создана' });
  } catch (err) {
    errorMessage.value = err instanceof Error ? err.message : 'Не удалось сохранить ревизию';
    Notify.create({ type: 'negative', message: errorMessage.value });
  }
}
```
- Использует `Notify.create()` для уведомлений
- Обрабатывает ошибки с уведомлениями

**Версия .68:**
```typescript
async function handleSave() {
  // ...
  try {
    let adtDate = form.value.adtDateDate;
    if (form.value.adtDateTime) {
      adtDate += 'T' + form.value.adtDateTime;
    } else {
      adtDate += 'T00:00:00';
    }
    // ...
  } catch (error: any) {
    errorMessage.value = error.message || 'Ошибка при сохранении ревизии';
  }
}
```
- Простая обработка ошибок
- Время опционально (по умолчанию 00:00:00)

**Анализ:** Версия .53 лучше для UX (уведомления), версия .68 гибче (время опционально).  
**Рекомендация:** Объединить: использовать уведомления из .53 + гибкость времени из .68.

---

## 3. Watch и реактивность

**Версия .53:**
- Нет watch
- `selectedAudit` - ref, загружается вручную

**Версия .68:**
- `watch(selectedAudit)` - автоматически загружает форму при изменении
- `selectedAudit` - computed из store (реактивность)

**Анализ:** Версия .68 более реактивна.  
**Рекомендация:** Добавить watch из .68, но сохранить загрузку через API из .53.

---

## 4. onMounted

**Версия .53:**
```typescript
onMounted(async () => {
  await Promise.all([
    auditsStore.fetchAudits(),
    auditTypesStore.fetchAuditTypes(),
    directoriesStore.fetchDirectories()
  ]);
});
```

**Версия .68:**
```typescript
onMounted(async () => {
  await Promise.all([
    auditsStore.fetchAudits(),
    auditTypesStore.fetchAuditTypes(),
    directoriesStore.loadAll(),
  ]);
  // Auto-select first audit if available
  if (auditsStore.audits.length > 0 && !selectedAuditId.value) {
    selectedAuditId.value = sortedAudits.value[0]?.adtKey || null;
  }
});
```

**Анализ:** Версия .68 автоматически выбирает первую ревизию.  
**Рекомендация:** Добавить авто-выбор из .68.

---

## 5. Структура кода

**Версия .53:**
- Более подробные комментарии
- Логическая группировка методов
- Четкое разделение на секции

**Версия .68:**
- Более компактный код
- Меньше комментариев
- Использует `resetForm()` для переиспользования

**Анализ:** Версия .53 лучше структурирована.  
**Рекомендация:** Сохранить структуру .53, добавить `resetForm()` из .68.

---

## 6. Обработка ошибок

**Версия .53:**
- Использует `Notify.create()` для всех уведомлений
- Детальные сообщения об ошибках

**Версия .68:**
- Простая обработка через `errorMessage`
- Меньше уведомлений

**Анализ:** Версия .53 лучше для UX.  
**Рекомендация:** Использовать подход .53 с уведомлениями.

---

## 7. Типы данных

**Версия .53:**
- `RaADto`, `RaACreateRequest`, `RaAUpdateRequest`
- `RaDirDto` из `@/types/audits`

**Версия .68:**
- `RaAudit`, `RaAuditCreateRequest`, `RaAuditUpdateRequest`
- `DirectoryDto` из `@/types/files`

**Анализ:** Типы .53 соответствуют backend API.  
**Рекомендация:** Оставить типы .53 (они правильные).

---

## 8. Stores

**Версия .53:**
- `@/stores/lookups/directories` с методом `fetchDirectories()`
- Тип: `RaDirDto`

**Версия .68:**
- `@/stores/directories` с методом `loadAll()`
- Тип: `DirectoryDto`

**Анализ:** Store .53 соответствует backend API.  
**Рекомендация:** Оставить store .53 (он правильный).

---

## ИТОГОВЫЙ СПИСОК УЛУЧШЕНИЙ ДЛЯ ПЕРЕНОСА

### Приоритет 1 (Высокий - простые улучшения):
1. ✅ **Сортировка по дате** (из .68): `sortedAudits` сортировать по дате (новые сверху)
2. ✅ **Авто-выбор первой ревизии** (из .68): в `onMounted` автоматически выбирать первую ревизию
3. ✅ **Метод `resetForm()`** (из .68): выделить логику очистки формы в отдельный метод
4. ✅ **Try-catch в `formatDate`** (из .68): добавить обработку ошибок

### Приоритет 2 (Средний - улучшения UX):
5. ✅ **Время опционально** (из .68): в `validateForm` и `isFormValid` сделать время опциональным
6. ✅ **Computed `selectedAudit`** (из .68): использовать computed вместо ref для реактивности
7. ✅ **Watch для автоматической загрузки** (из .68): добавить watch для автоматической загрузки формы

### Приоритет 3 (Низкий - улучшения структуры):
8. ✅ **Улучшенные сообщения об ошибках** (из .53): использовать более детальные сообщения
9. ✅ **Логическая группировка методов** (из .53): сохранить хорошую структуру кода

### НЕ ПЕРЕНОСИТЬ:
- ❌ Типы данных (оставить .53 - они правильные)
- ❌ Stores (оставить .53 - они правильные)
- ❌ Упрощенное форматирование даты (оставить полное из .53)
- ❌ Простая обработка ошибок (оставить уведомления из .53)

---

**Дата создания:** 2026-01-19
