# Type5 Acceptance Smoke-Check Report (Template)

## Context
- Date:
- Environment: TEST
- Audit ID:
- Apply Exec Key:
- Runner:

## Baseline (before apply)
- ra_max:
- ras_max:
- rac_max:
- racs_max:

## Post-run smoke-check result
- rollback_status: `OK_ROLLBACK | CHECK_REQUIRED | BASELINE_NOT_SET`
- ra_delta:
- ras_delta:
- rac_delta:
- racs_delta:

## Technical artifacts (expected)
- Latest `ra_execution` rows checked: yes/no
- Latest `ra_reconcile_marker` rows checked: yes/no
- Notes:

## Final verdict
- Result: `PASS | FAIL`
- Decision:
  - PASS: proceed
  - FAIL: investigate rollback/baseline and rerun smoke-check
