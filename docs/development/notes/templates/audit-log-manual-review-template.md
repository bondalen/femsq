---
title: "Audit log manual review (шаблон проверки)"
created: "2026-03-26"
lastUpdated: "2026-03-26"
version: "1.0.0"
---

## Контекст

- **auditId (adt_key)**: `<number>`
- **exec_key**: `<number>`
- **addRa**: `<true|false>`
- **проверяющий**: `<name>`
- **дата/время**: `<YYYY-MM-DD HH:MM>`

## Ожидаемая структура (каркас)

Отметьте наличие:

- [ ] `AUDIT_START` (название ревизии, директория)
- [ ] `FILE_START/FILE_END` для каждого файла
- [ ] `SHEET_FOUND/SHEET_MISSING` (если применимо)
- [ ] `STAGING_*` блоки + `STAGING_STATS`
- [ ] `RECONCILE_START/RECONCILE_END` + counters
- [ ] итоговая строка (duration/статус)

## Вложенность/читаемость

- [ ] видна вложенность “ревизия → файл → лист → staging/reconcile”
- [ ] WARN/ERROR визуально выделены и понятны
- [ ] понятна точка остановки при ошибке

## Фрагмент `adt_results` (вставьте сюда)

```
<paste>
```

## Замечания пользователей

- **что “не так”**: `<text>`
- **что хочется как в Access**: `<text>`

## Решения/следующие шаги

- `<bullet>`

