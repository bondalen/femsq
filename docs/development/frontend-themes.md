# Глобальные темы FEMSQ UI (задача 0050)

**Назначение:** единая светлая/тёмная тема всего веб-приложения (`femsq-frontend-q`), включая HTML-лог ревизий `adt_results`.  
**Связанные задачи:** 0049 (содержание и плотность лога), 0048 (UAT/prod).  
**Chat-plan:** `docs/development/notes/chats/chat-plan/chat-plan-26-0707-ralp-reconcile.md` §9.3.5.

---

## Решения оператора (2026-07-13)

| # | Вопрос | Решение |
|---|--------|---------|
| 1 | Тема по умолчанию | **Kimbie Dark** |
| 2 | Переключатель | **Иконка** в `TopBar` (`dark_mode` / `light_mode`) |
| 3 | Акцент в Kimbie Dark | **Тёплый** (`#d19a66`, `#e5c07b`), не холодный синий |
| 4 | Порядок внедрения | **Сначала** экран «Ревизии» (демо оператору), затем остальные модули |

---

## Две темы

| ID | Название | Quasar Dark | Назначение |
|----|----------|-------------|------------|
| `kimbie-dark` | Kimbie Dark | `$q.dark.set(true)` + кастомные токены | По умолчанию; тёплый тёмный фон |
| `vs-light` | Светлая (Visual Studio) | `$q.dark.set(false)` | Светлый корпоративный UI |

**Хранение:** `localStorage` ключ **`femsq.theme`** (заменяет устаревший `femsq.auditLogTheme`).

**DOM:** `document.documentElement.dataset.femsqTheme = 'kimbie-dark' | 'vs-light'` — применяется **до** `app.mount()` (без flash).

---

## CSS-токены (единый источник)

Файл: `code/femsq-frontend-q/src/styles/femsq-theme-tokens.css`

| Токен | Kimbie Dark | VS Light |
|-------|-------------|----------|
| `--femsq-bg-page` | `#1a1409` | `#f3f3f3` |
| `--femsq-bg-surface` | `#221a0f` | `#ffffff` |
| `--femsq-bg-elevated` | `#2d2318` | `#e8e8e8` |
| `--femsq-text` | `#d3af86` | `#1e1e1e` |
| `--femsq-text-muted` | `#a68b5b` | `#6e6e6e` |
| `--femsq-border` | `rgba(211,175,134,0.25)` | `#d4d4d4` |
| `--femsq-primary` | `#d19a66` | `#0078d4` |
| `--femsq-primary-hover` | `#e5c07b` | `#005a9e` |

Лог `adt_results` (**`audit-log.css`**) использует те же переменные — **отдельный** переключатель темы в `AuditsView` **удаляется**.

---

## Архитектура

```
TopBar (иконка темы)
    → useFemsqTheme / stores/theme.ts
        → localStorage femsq.theme
        → html[data-femsq-theme]
        → $q.dark.set(...)
        → --femsq-* на всех экранах + .femsq-auditlog
```

**Реализация (целевые файлы):**

| Область | Файлы |
|---------|-------|
| Store / composable | `src/stores/theme.ts`, `src/theme/femsq-theme.ts` |
| Токены | `src/styles/femsq-theme-tokens.css` |
| Bootstrap | `src/main.ts` (Dark plugin, apply theme) |
| Оболочка | `AppLayout.vue`, `TopBar.vue`, `StatusBar.vue` |
| Ревизии (приоритет) | `AuditsView.vue`, `audit-log.css`, компоненты `components/audits/*` |
| Остальные экраны | Organizations, Reports, Investment chains, Test Grid, ConnectionModal |

---

## Фазы (оценка 8–11 рабочих дней)

| Фаза | Содержание | Статус |
|------|------------|--------|
| **B.1** | Токены, store, иконка в TopBar, AppLayout, StatusBar | ✅ |
| **B.2** | Ревизии + лог (demo оператору) | ✅ |
| **B.3** | Организации, отчёты, цепочки, Test Grid, ConnectionModal | ✅ |
| **B.4** | UAT обеих тем; закрытие U1; документация | ✅ 2026-07-13 |

**Sign-off оператора (2026-07-13):** ревизии, организации, отчёты, цепочки — в пределах нормы в обеих темах.

---

## Ограничения и остатки

- Inline `<font color=…>` в HTML лога (staging VBA-стиль) **не привязаны** к теме — читаемы, но могут выбиваться из палитры; вынос в CSS-классы — отдельный подпункт (не blocker 0050).
- Quasar Dark по умолчанию — холодный серый; Kimbie реализуется **поверх** через `--femsq-*`, не через стандартную палитру Quasar alone.

---

## Приёмка

- Переключение иконкой в TopBar на **любом** экране.
- После перезагрузки страницы тема сохраняется (`femsq.theme`).
- Экран «Ревизии»: лог визуально **в одной** палитре с карточками и формой.
- Чеклист UAT: каждый модуль × `kimbie-dark` × `vs-light`.

**lastUpdated:** 2026-07-13
