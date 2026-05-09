# Type5 Pre-Prod / Prod Release Bundle (No-code prep)

**Дата фиксации:** 2026-04-15  
**Целевая версия:** `0.1.0.109-SNAPSHOT`  
**Базовый коммит:** `014aa68`

## 1) Источник артефакта

- Fat JAR:
  - `code/femsq-backend/femsq-web/target/femsq-web-0.1.0.109-SNAPSHOT.jar`
  - SHA-256: `3edf061cf0d03f841ac734a12ba98b6e3ec5c7c2c7a96c45d27d2789772e82db`
  - Size: `79,430,558` bytes

## 2) Состав release bundle

### A. Для проверки на машине разработки (browser pre-prod check)

- `femsq-web-0.1.0.109-SNAPSHOT.jar`
- `docs/deployment/jar-lifecycle.md`
- `code/scripts/README-TESTING.md`
- `docs/sql-scripts/type5-acceptance-postrun-smoke-check.sql`
- `docs/development/notes/templates/type5-acceptance-smoke-check-report-template.md`
- `docs/sql-scripts/type5-reconcile-marker-cleanup-policy.sql`

### B. Для продуктивной машины (пилот в ограниченном scope)

- `femsq-web-0.1.0.109-SNAPSHOT.jar`
- Инструкции запуска/обновления:
  - `docs/deployment/jar-lifecycle.md`
  - `docs/deployment/windows-deployment-guide.md`
- Регламент post-apply контроля:
  - `docs/sql-scripts/type5-acceptance-postrun-smoke-check.sql`
  - `docs/development/notes/templates/type5-acceptance-smoke-check-report-template.md`
- Регламент marker-cleanup (TEST only, не для PROD):
  - `docs/sql-scripts/type5-reconcile-marker-cleanup-policy.sql`

## 3) Стартовый режим ревизий для внедрения

- По умолчанию запуск пилота в режиме dry-run: `adt_AddRA=0`.
- Переход к apply (`adt_AddRA=1`) только после успешного pre-prod browser smoke.
- После каждого apply-run обязателен smoke-check с критерием PASS:
  - `rollback_status=OK_ROLLBACK`.

## 4) Быстрые команды контроля перед стартом

```bash
# Проверка health
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8080/actuator/health

# Проверка GraphQL
curl -s -X POST http://127.0.0.1:8080/graphql -H "Content-Type: application/json" -d '{"query":"{ __typename }"}'
```

## 5) Ограничение текущего окна

- Допустимый scope: функционал предыдущего развёртывания + загрузка Excel/reconcile только для type 5.
- Вне scope: расширения type 2/3/6 и любые новые доменные сценарии.
