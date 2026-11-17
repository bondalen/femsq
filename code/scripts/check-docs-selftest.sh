#!/usr/bin/env bash
# Самопроверка check-docs на фикстурах (docs-sync 4.2).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIX="$SCRIPT_DIR/check-docs-fixtures"
CHECK="$SCRIPT_DIR/check-docs.sh"
fail=0

run_expect_error() {
  local name="$1"
  local root="$2"
  local needle="$3"
  echo "--- fixture: $name (expect ERROR containing: $needle) ---"
  out="$(CHECK_DOCS_ROOT="$root" CHECK_DOCS_MODE=strict "$CHECK" 2>&1 || true)"
  echo "$out" | tail -20
  if echo "$out" | grep -q "ERROR:.*$needle"; then
    echo "OK $name"
  else
    echo "FAIL $name — не найдено ERROR:.*$needle"
    fail=1
  fi
}

run_expect_ok() {
  local name="$1"
  local root="$2"
  echo "--- fixture: $name (expect no ERROR) ---"
  out="$(CHECK_DOCS_ROOT="$root" CHECK_DOCS_MODE=strict "$CHECK" 2>&1 || true)"
  echo "$out" | tail -15
  if echo "$out" | grep -q '^  ERROR:'; then
    echo "FAIL $name — есть ERROR"
    fail=1
  else
    echo "OK $name"
  fi
}

run_expect_error bad-json "$FIX/bad-json" "Невалидный JSON"
run_expect_error bad-status "$FIX/bad-status" "статус вне словаря"
run_expect_error dup-log-ids "$FIX/dup-log-ids" "Повторяющийся id лога"
run_expect_error rest-controller "$FIX/rest-controller" "EvilRestController"
run_expect_ok valid-json "$FIX/valid-json"

if [ "$fail" -ne 0 ]; then
  echo "SELFTEST FAILED"
  exit 1
fi
echo "SELFTEST PASSED"
