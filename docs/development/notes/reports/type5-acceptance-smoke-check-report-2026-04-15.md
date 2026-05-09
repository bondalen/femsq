# Type5 Acceptance Smoke-Check Report

## Context
- Date: 2026-04-15
- Environment: TEST
- Audit ID: 14
- Apply Exec Key: 1124
- Runner: Codex (with user confirmation)

## Baseline (before apply)
- ra_max: 51537
- ras_max: 37711
- rac_max: 3429
- racs_max: 2409

## Post-run smoke-check result
- rollback_status: `CHECK_REQUIRED` (для apply exec_key=1124)
- ra_delta: 54890
- ras_delta: 56363
- rac_delta: 1608
- racs_delta: 1608

## Technical artifacts (expected)
- Latest `ra_execution` rows checked: yes (baseline before new apply)
- Latest `ra_reconcile_marker` rows checked: yes
- Notes:
  - Baseline `ra_execution` (до нового прогона пользователя):
    - `1122 | adt=13 | COMPLETED | addRa=0`
    - `1121 | adt=13 | FAILED | addRa=0`
    - `1120 | adt=13 | FAILED | addRa=0`
    - `1119 | adt=13 | FAILED | addRa=0`
    - `1118 | adt=13 | COMPLETED | addRa=0`
    - `1117 | adt=13 | COMPLETED | addRa=1`
    - `1116 | adt=13 | COMPLETED | addRa=0`
    - `116  | adt=14 | COMPLETED | addRa=1`
    - `115  | adt=14 | COMPLETED | addRa=0`
    - `114  | adt=14 | COMPLETED | addRa=1`
    - `113  | adt=14 | COMPLETED | addRa=0`
    - `112  | adt=14 | COMPLETED | addRa=0`
  - Новый прогон пользователя (dry-run):
    - `1123 | adt=14 | COMPLETED | addRa=0`
  - Новый прогон пользователя (apply):
    - `1124 | adt=14 | COMPLETED | addRa=1`
  - Проверка логов `adt_results` для `adt=14`:
    - найдено `130` сообщений по шаблону `отказ валидации`,
    - найдено `74` сообщений `INVALID` (в т.ч. `INVALID_CANONICAL_KEY`),
    - типовой текст: `нет отправителя (og); нет стройки (cac)`.
  - Доменные max-ключи после dry-run не изменились:
    - `ra_max=51537`, `ras_max=37711`, `rac_max=3429`, `racs_max=2409`.
  - Доменные max-ключи после apply:
    - `ra_max=106427`, `ras_max=94074`, `rac_max=5037`, `racs_max=4017`,
    - rollback к baseline не подтверждён.
  - Маркеры reconcile для `exec_key=1124`:
    - `TYPE5_APPLY_RA=1`,
    - `TYPE5_APPLY_RC=1`.
  - Выполнено ручное восстановление baseline (manual rollback):
    - удалено: `ags.ra_summ=1578`, `ags.ra=1578`, `ags.ra_change_summ=16`, `ags.ra_change=16`,
    - `adt_AddRA` для `adt_key=14` восстановлен в `0`,
    - post-restore max-ключи: `ra=51537`, `ras=37711`, `rac=3429`, `racs=2409`,
    - `rollback_ok=true`.

## Final verdict
- Result: `FAIL` для apply-цикла (до rollback), затем baseline восстановлен вручную
- Decision:
  - PASS: proceed
  - FAIL: investigate rollback/baseline and rerun smoke-check
