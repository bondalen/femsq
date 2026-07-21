#!/usr/bin/env bash
# Переключение снимка Excel type=6 (AgFee) для ревизии test_26 (adt_key=14, ra_dir=15, af_key=313).
#
# Использование:
#   ./code/scripts/audit-switch-agfee-snapshot.sh march|july
#
# Предпочитает /mnt/d/wire-guard-share-nb-win (nb-win); иначе /mnt/nb-win-share.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SNAPSHOT="${1:-}"

resolve_base() {
  local d="/mnt/d/wire-guard-share-nb-win/femsq/excel"
  local n="/mnt/nb-win-share/femsq/excel"
  if [[ -d "$d" ]]; then
    echo "$d"
  elif [[ -d "$n" ]]; then
    echo "$n"
  else
    echo "Не найдена шара excel ($d или $n)" >&2
    exit 1
  fi
}

BASE="$(resolve_base)"
case "$SNAPSHOT" in
  march|2026_03)
    DIR="$BASE/2026_03"
    ;;
  july|2026-07)
    DIR="$BASE/2026-07"
    ;;
  *)
    echo "Укажите снимок: march | july" >&2
    exit 1
    ;;
esac

AGFEE_FILE="$DIR/2026 Свод инф-ции по Актам.xlsx"
if [[ ! -f "$AGFEE_FILE" ]]; then
  echo "Файл не найден: $AGFEE_FILE" >&2
  exit 1
fi

# escape single quotes for T-SQL N'...'
esc() { printf "%s" "$1" | sed "s/'/''/g"; }
DIR_SQL="$(esc "$DIR")"
FILE_SQL="$(esc "$AGFEE_FILE")"

node "$ROOT/code/scripts/femsq-sql.js" "
SET NOCOUNT ON;
UPDATE ags.ra_dir SET dir = N'$DIR_SQL' WHERE [key] = 15;
UPDATE ags.ra_f
   SET af_name = N'$FILE_SQL', af_dir = 15, af_execute = 1, af_source = 1
 WHERE af_key = 313;
SELECT [key], dir FROM ags.ra_dir WHERE [key] = 15;
SELECT af_key, af_type, af_execute, af_source, af_name FROM ags.ra_f WHERE af_key = 313;
"

echo "AgFee снимок: $SNAPSHOT → $AGFEE_FILE"
