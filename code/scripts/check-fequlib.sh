#!/usr/bin/env bash
# Проверка локального клона feQuLib перед сборкой FEMSQ.
# FEMSQ зависит от fequlib через file:../../../feQuLib — устаревший клон
# даёт ошибку сборки frontend («FemsqTree is not exported» и аналоги).
#
# Использование: ./code/scripts/check-fequlib.sh
# Пропуск (только по явной просьбе): FEQULIB_SKIP_SYNC=1

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ "${FEQULIB_SKIP_SYNC:-}" = "1" ]; then
  echo -e "${YELLOW}⚠ Пропуск проверки feQuLib (FEQULIB_SKIP_SYNC=1)${NC}"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEMSQ_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FEQULIB_DIR="${FEQULIB_DIR:-$(cd "$FEMSQ_ROOT/../feQuLib" && pwd)}"

echo -e "${GREEN}=== FEMSQ: проверка локального feQuLib ===${NC}"
echo "Путь: $FEQULIB_DIR"

if [ ! -d "$FEQULIB_DIR/.git" ]; then
  echo -e "${RED}ERROR: клон feQuLib не найден ($FEQULIB_DIR).${NC}"
  echo "Ожидается соседний репозиторий: https://github.com/bondalen/fequlib.git"
  echo "Не копировать FemsqTree в FEMSQ — синхронизировать клон."
  exit 1
fi

INDEX_TS="$FEQULIB_DIR/src/index.ts"
TREE_VUE="$FEQULIB_DIR/src/components/tree/FemsqTree.vue"

if [ ! -f "$TREE_VUE" ]; then
  echo -e "${RED}ERROR: нет $TREE_VUE${NC}"
  echo "Локальный feQuLib не содержит FemsqTree. Выполнить git pull в $FEQULIB_DIR."
  exit 1
fi

if ! grep -q "export { default as FemsqTree }" "$INDEX_TS"; then
  echo -e "${RED}ERROR: FemsqTree не экспортируется из $INDEX_TS${NC}"
  echo "Синхронизировать feQuLib с origin/main, не патчить экспорт в FEMSQ."
  exit 1
fi

cd "$FEQULIB_DIR"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
HEAD="$(git rev-parse HEAD)"

if ! git fetch origin >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠ git fetch origin не удался — удалённая сверка пропущена.${NC}"
  echo "Локально: ветка $BRANCH, HEAD ${HEAD:0:7}, FemsqTree на месте."
  echo -e "${GREEN}✓ Локальный feQuLib пригоден для сборки (без сверки с GitHub)${NC}"
  exit 0
fi

REMOTE_REF="origin/$BRANCH"
if ! git rev-parse --verify "$REMOTE_REF" >/dev/null 2>&1; then
  REMOTE_REF="origin/main"
fi
REMOTE="$(git rev-parse "$REMOTE_REF")"
BEHIND="$(git rev-list --count HEAD.."$REMOTE_REF")"
AHEAD="$(git rev-list --count "$REMOTE_REF"..HEAD)"

echo "Ветка: $BRANCH  HEAD: ${HEAD:0:7}  $REMOTE_REF: ${REMOTE:0:7}"

if [ "$BEHIND" -gt 0 ]; then
  echo -e "${RED}ERROR: feQuLib отстаёт от $REMOTE_REF на $BEHIND коммит(ов).${NC}"
  echo "Перед сборкой FEMSQ: cd $FEQULIB_DIR && git pull"
  echo "Не воссоздавать компоненты библиотеки в FEMSQ."
  exit 1
fi

if [ "$AHEAD" -gt 0 ]; then
  echo -e "${YELLOW}⚠ Локальный feQuLib опережает $REMOTE_REF на $AHEAD коммит(ов).${NC}"
fi

echo -e "${GREEN}✓ feQuLib синхронизирован с GitHub, FemsqTree экспортируется${NC}"
