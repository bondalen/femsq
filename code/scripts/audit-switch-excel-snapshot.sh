#!/usr/bin/env bash
# Переключение SMB-снимка Excel для ревизии test_26 (adt_key=14, ra_dir.key=15).
#
# Использование:
#   ./code/scripts/audit-switch-excel-snapshot.sh march|july
#
# Обновляет ags.ra_dir.dir и полный путь af_type=3 (аренда).

set -euo pipefail

SNAPSHOT="${1:-}"
PROPS="${FEMSQ_DB_PROPS:-$HOME/.femsq/database.properties}"
BASE="/mnt/nb-win-share/femsq/excel"

if [[ ! -f "$PROPS" ]]; then
  echo "Не найден $PROPS" >&2
  exit 1
fi

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

RENT_FILE="$DIR/(2026)_Аренда_рабочий.xlsx"
if [[ ! -f "$RENT_FILE" ]]; then
  echo "Файл не найден: $RENT_FILE" >&2
  exit 1
fi

read_prop() { grep "^$1=" "$PROPS" | head -1 | cut -d= -f2-; }
DB_HOST="$(read_prop host)"
DB_PORT="$(read_prop port)"
DB_NAME="$(read_prop database)"
DB_USER="$(read_prop username)"
DB_PASS="$(read_prop password)"

SQL="
SET NOCOUNT ON;
UPDATE ags.ra_dir SET dir = N'$DIR' WHERE [key] = 15;
UPDATE ags.ra_f
   SET af_name = N'$RENT_FILE'
 WHERE af_key = 314;
SELECT [key], dir FROM ags.ra_dir WHERE [key] = 15;
SELECT af_key, af_type, af_name FROM ags.ra_f WHERE af_key = 314;
"

sqlcmd -S "${DB_HOST},${DB_PORT}" -d "$DB_NAME" -U "$DB_USER" -P "$DB_PASS" -C -W -Q "$SQL"
echo "Снимок переключён: $SNAPSHOT → $DIR"
