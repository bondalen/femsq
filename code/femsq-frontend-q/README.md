# FEMSQ Frontend (Quasar Edition)

Frontend приложение для системы работы с контрагентами и объектами при капитальном строительстве.

## Технологии

- **Vue 3** - прогрессивный JavaScript фреймворк
- **Quasar Framework** - Vue.js UI фреймворк
- **TypeScript** - типизированный JavaScript
- **Vite** - быстрый сборщик и dev-сервер
- **Pinia** - state management
- **Vitest** - unit и component тестирование
- **Playwright** - e2e тестирование

## Установка

```bash
npm install
```

## Разработка

```bash
# Запуск dev-сервера
npm run dev

# Проверка типов
npm run type-check

# Сборка для production
npm run build

# Предпросмотр production сборки
npm run preview
```

## Тестирование

### Unit и Component тесты (Vitest)

```bash
# Запуск всех тестов
npm run test

# Запуск unit тестов
npm run test:unit

# Запуск с покрытием
npm run test -- --coverage
```

### E2E тесты (Playwright)

```bash
# Запуск e2e тестов
npm run test:e2e

# Запуск e2e тестов с UI
npm run test:e2e:ui

# Установка браузеров Playwright (при первой установке)
npx playwright install
```

## Структура проекта

```
femsq-frontend-q/
├── src/                    # Исходный код приложения
│   ├── api/               # API клиент
│   ├── components/        # Vue компоненты
│   │   ├── layout/       # Компоненты layout (AppLayout, TopBar, StatusBar)
│   │   └── setup/        # Компоненты настройки (ConnectionModal)
│   ├── stores/           # Pinia stores
│   ├── views/            # Страницы/views
│   │   └── organizations/ # Экран организаций
│   └── styles/           # Стили
├── tests/                 # Тесты
│   ├── unit/             # Unit тесты
│   ├── component/        # Component тесты
│   └── e2e/              # E2E тесты (Playwright)
├── public/               # Статические файлы
├── playwright.config.ts  # Конфигурация Playwright
├── vitest.config.ts      # Конфигурация Vitest
└── vite.config.ts        # Конфигурация Vite
```

## Конфигурация

### Переменные окружения

Создайте файл `.env.local` для локальной разработки:

```env
VITE_API_BASE_URL=http://localhost:8080
PLAYWRIGHT_BASE_URL=http://localhost:5175
```

### Playwright

Конфигурация находится в `playwright.config.ts`. По умолчанию:
- Base URL: `http://localhost:5175`
- Браузер: Chromium
- Автоматический запуск dev-сервера перед тестами

## Документация

- [Структурный план разработки](../../docs/development/notes/chats/chat-plan/chat-plan-25-1111.md)
- [UX-описание компонентов](../../docs/development/notes/UI/)
