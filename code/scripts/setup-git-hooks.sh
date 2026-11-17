#!/usr/bin/env bash
# Подключает .githooks через core.hooksPath (docs-sync блок 4.4).
# Не меняет другие git config. Запуск из корня репозитория или любого места.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_DIR="$ROOT/.githooks"

if [ ! -d "$HOOKS_DIR" ]; then
  echo "ERROR: нет $HOOKS_DIR — создайте хуки перед setup."
  exit 1
fi

cd "$ROOT"
git config core.hooksPath .githooks
echo "OK: core.hooksPath=.githooks"
echo "Проверка: git config --get core.hooksPath → $(git config --get core.hooksPath)"
echo "Режим check-docs в pre-commit: CHECK_DOCS_MODE=strict (блок 13 docs-sync)."
