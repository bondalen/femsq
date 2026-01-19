# Анализ проблемы с таймаутом загрузки статуса подключения

**Дата:** 2026-01-19  
**Проблема:** При загрузке приложения в консоли браузера появляется ошибка:
```
[App] Failed to load connection status: RequestError: Превышено время ожидания ответа от сервера
```

## Анализ проблемы

### 1. Backend работает корректно
- Endpoint `/api/v1/connection/status` отвечает быстро (0.008 секунды)
- HTTP код: 200
- Ответ содержит корректные данные: `{"connected":true,"schema":"ags","database":"FishEye","message":"Подключение активно","error":null}`

### 2. Frontend настройки
- **DEFAULT_TIMEOUT:** 15 секунд (15000 мс) - достаточно для запроса
- **Endpoint:** `/api/v1/connection/status`
- **Метод:** GET
- **Обработка ошибок:** При таймауте устанавливается статус `idle` с сообщением "Ожидает подключения"

### 3. Возможные причины

#### Вариант 1: Запрос выполняется до полной готовности backend
- **Симптомы:** При первой загрузке страницы backend может еще не быть готов обрабатывать запросы
- **Решение:** Добавить retry механизм с экспоненциальной задержкой
- **Приоритет:** Высокий

#### Вариант 2: Проблема с построением URL
- **Симптомы:** Запрос может идти на неправильный URL из-за проблем с `buildUrl`
- **Решение:** Добавить логирование URL перед запросом
- **Приоритет:** Средний

#### Вариант 3: Проблема с AbortController
- **Симптомы:** `AbortController` может срабатывать раньше времени из-за race condition
- **Решение:** Убедиться, что `clearTimeout` вызывается корректно
- **Приоритет:** Низкий

#### Вариант 4: Проблема с CORS или сетевыми настройками
- **Симптомы:** Запрос блокируется браузером
- **Решение:** Проверить настройки CORS на backend
- **Приоритет:** Низкий (curl работает, значит backend доступен)

## Рекомендации по исправлению

### Вариант А: Добавить retry механизм (Рекомендуется)
```typescript
async function loadConnectionStatus(): Promise<void> {
  const maxRetries = 3;
  const retryDelay = 1000; // 1 секунда
  
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const statusResponse = await getConnectionStatus();
      // ... обработка успешного ответа
      return;
    } catch (error) {
      if (attempt < maxRetries - 1) {
        console.warn(`[App] Connection status load attempt ${attempt + 1} failed, retrying...`);
        await new Promise(resolve => setTimeout(resolve, retryDelay * (attempt + 1)));
      } else {
        // Последняя попытка не удалась
        console.error('[App] Failed to load connection status after all retries:', error);
        connection.setStatus('idle', { message: 'Ожидает подключения' });
      }
    }
  }
}
```

**Плюсы:**
- Решает проблему с ранней загрузкой страницы
- Не требует изменений в backend
- Улучшает UX при медленном старте backend

**Минусы:**
- Увеличивает время ожидания при реальных проблемах с подключением

### Вариант Б: Увеличить таймаут для этого конкретного запроса
```typescript
export async function getConnectionStatus(): Promise<ConnectionStatusResponse> {
  return apiGet<ConnectionStatusResponse>('/api/v1/connection/status', {
    timeoutMs: 30_000 // 30 секунд вместо 15
  });
}
```

**Плюсы:**
- Простое решение
- Дает больше времени для первого запроса

**Минусы:**
- Не решает проблему, если backend действительно не отвечает
- Увеличивает время ожидания ошибки

### Вариант В: Добавить логирование для диагностики
```typescript
async function loadConnectionStatus(): Promise<void> {
  try {
    console.info('[App] Loading connection status...');
    const url = buildUrl('/api/v1/connection/status');
    console.info('[App] Request URL:', url);
    const statusResponse = await getConnectionStatus();
    console.info('[App] Connection status loaded:', statusResponse);
    // ... обработка
  } catch (error) {
    console.error('[App] Failed to load connection status:', error);
    // ... обработка ошибки
  }
}
```

**Плюсы:**
- Помогает диагностировать проблему
- Не меняет поведение приложения

**Минусы:**
- Не решает проблему, только помогает найти причину

### Вариант Г: Комбинированный подход (Рекомендуется)
1. Добавить retry механизм с экспоненциальной задержкой
2. Добавить логирование URL и времени выполнения
3. Увеличить таймаут для первого запроса до 30 секунд

## Выводы

1. **Backend работает корректно** - endpoint отвечает быстро и правильно
2. **Проблема на стороне frontend** - запрос не доходит до backend или получает таймаут
3. **Наиболее вероятная причина** - запрос выполняется до полной готовности backend при первой загрузке
4. **Рекомендуемое решение** - добавить retry механизм с экспоненциальной задержкой

## Следующие шаги

1. Реализовать retry механизм в `loadConnectionStatus()`
2. Добавить логирование для диагностики
3. Протестировать на медленном старте backend
4. Если проблема сохранится - проверить построение URL и сетевые настройки
