# Фикстуры check-docs (docs-sync 4.2)

По одному испорченному дереву на правило. Запуск:

```bash
./code/scripts/check-docs-selftest.sh
```

| Каталог | Правило |
|---------|---------|
| `bad-json/` | Невалидный JSON → ERROR |
| `bad-status/` | Статус вне словаря → ERROR |
| `dup-log-ids/` | Повторяющиеся id логов → ERROR |
| `rest-controller/` | `@RestController` вне исключений → ERROR |
| `valid-json/` | Минимально валидный срез → OK / только WARN |
