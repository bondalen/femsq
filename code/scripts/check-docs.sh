#!/usr/bin/env bash
# Проверка документации FEMSQ (docs-sync блок 4).
# Спецификация: docs/project-documentation-rules.md → «Проверка check-docs».
#
# Использование:
#   ./code/scripts/check-docs.sh
#   CHECK_DOCS_MODE=strict ./code/scripts/check-docs.sh
#   CHECK_DOCS_ROOT=/path ./code/scripts/check-docs.sh
#
# Режим по умолчанию: warn (ошибки печатаются, exit 0).
# После блока 13 docs-sync: strict (ошибки → exit 1).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CHECK_DOCS_MODE="${CHECK_DOCS_MODE:-warn}"

exec python3 "$SCRIPT_DIR/check_docs.py" "$@"
