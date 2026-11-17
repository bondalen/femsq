#!/usr/bin/env bash
# Проверка документации FEMSQ (docs-sync блок 4).
# Спецификация: docs/project-documentation-rules.md → «Проверка check-docs».
#
# Использование:
#   ./code/scripts/check-docs.sh
#   CHECK_DOCS_MODE=strict ./code/scripts/check-docs.sh
#   CHECK_DOCS_ROOT=/path ./code/scripts/check-docs.sh
#
# Режим по умолчанию: strict (ошибки → exit 1; блок 13 docs-sync).
# Предупреждения не блокируют. Для отладки: CHECK_DOCS_MODE=warn.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CHECK_DOCS_MODE="${CHECK_DOCS_MODE:-strict}"

exec python3 "$SCRIPT_DIR/check_docs.py" "$@"
