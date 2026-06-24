#!/bin/bash
# =============================================================================
# build_flash_package.sh
# Сборка флеш-пакета spMstrg_2606 для продуктива (SQL Server 2012).
# Результат: open/ + archive/*.zip + MANIFEST.sha256
#
# Использование:
#   ./build_flash_package.sh
#   DEPLOY_ARCHIVE_PASSWORD='секрет' ./build_flash_package.sh --zip-password
#
# Документация: docs/deployment/sql-flash-drive-packaging.md
# Автор: Александр | Дата: 2026-06-16
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../.." && pwd)"
DEPLOY_ID="$(basename "$SCRIPT_DIR")"
PACKAGE_NAME="spMstrg_2606_MSSQL2012"
BUILD_DATE="$(date +%Y%m%d)"
ZIP_NAME="${PACKAGE_NAME}_${BUILD_DATE}.zip"
USE_ZIP_PASSWORD=false

for arg in "$@"; do
    case "$arg" in
        --zip-password) USE_ZIP_PASSWORD=true ;;
    esac
done

OPEN="$SCRIPT_DIR/open"
ARCHIVE="$SCRIPT_DIR/archive"
VENV="$SCRIPT_DIR/.venv_build"

log() { echo "==> $*"; }

# --- Python venv (fpdf2, pyzipper) ---
if [[ ! -x "$VENV/bin/python" ]]; then
    log "Создание venv $VENV"
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install -q fpdf2 pyzipper
fi

# --- Очистка open/ (артефакт, не в git) ---
log "Подготовка open/"
rm -rf "$OPEN"
mkdir -p "$OPEN/01_MSSQL2012" "$OPEN/02_acceptance" "$OPEN/03_docs" "$OPEN/04_prod_log"
mkdir -p "$ARCHIVE"

# --- 01_MSSQL2012 ---
log "Копирование MSSQL2012/"
cp -a "$TASK_DIR/MSSQL2012/." "$OPEN/01_MSSQL2012/"

# --- 02_acceptance ---
log "Копирование acceptance-скриптов"
cp "$TASK_DIR/07_VERIFY_spMstrg_2606_chain5.sql" "$OPEN/02_acceptance/"
cp "$TASK_DIR/07_VERIFY_spFn2_schema.sql" "$OPEN/02_acceptance/"

# --- 03_docs ---
log "Документация и PDF чеклиста"
cp "$REPO_ROOT/docs/deployment/db-upgrade-spMstrg-2606.md" "$OPEN/03_docs/"
"$VENV/bin/python" "$SCRIPT_DIR/generate_checklist_pdf.py" \
    "$OPEN/03_docs/db-upgrade-spMstrg-2606-deploy-day-checklist.pdf"
cat > "$OPEN/03_docs/DEV_ACCEPTANCE_SUMMARY.txt" << EOF
Dev-приёмка spMstrg_2606 (цепь 5) — эталоны
Сборка флешки: $DEPLOY_ID ($BUILD_DATE)

@MounthEndDate='2022-12-31' (основной эталон prod):
  RS1 = 14447, RS4 = 916
  07k RS1 keyDiff = 0
  07f F.3 = 0

@MounthEndDate='2022-11-30' (доп. прогон 2026-06-16):
  RS1 = 14447, RS4 = 905
  07k PASS, 07i/07j PASS

Лог: acceptance_dev_chain5_20221130_20260616_174351.log
EOF

# --- 04_prod_log ---
log "Шаблоны prod_log"
cp -a "$SCRIPT_DIR/templates/04_prod_log/." "$OPEN/04_prod_log/"

# --- README_DEPLOY ---
# README_DEPLOY.txt в корне deploy (в git)

# --- MANIFEST ---
log "MANIFEST.sha256"
(
    cd "$OPEN"
    find . -type f | sort | while read -r f; do
        sha256sum "${f#./}"
    done
) > "$SCRIPT_DIR/MANIFEST.sha256"

# --- ZIP ---
log "Архив archive/$ZIP_NAME"
rm -f "$ARCHIVE/$ZIP_NAME" "$ARCHIVE/$ZIP_NAME.sha256"

if $USE_ZIP_PASSWORD; then
    if [[ -z "${DEPLOY_ARCHIVE_PASSWORD:-}" ]]; then
        echo "ERROR: задайте DEPLOY_ARCHIVE_PASSWORD для --zip-password" >&2
        exit 1
    fi
    "$VENV/bin/python" - "$OPEN" "$ARCHIVE/$ZIP_NAME" << 'PY'
import sys
from pathlib import Path
import pyzipper

open_dir = Path(sys.argv[1])
zip_path = Path(sys.argv[2])
password = __import__("os").environ["DEPLOY_ARCHIVE_PASSWORD"].encode("utf-8")

with pyzipper.AESZipFile(
    zip_path, "w",
    compression=pyzipper.ZIP_DEFLATED,
    encryption=pyzipper.WZ_AES,
) as zf:
    zf.setpassword(password)
    for f in sorted(open_dir.rglob("*")):
        if f.is_file():
            zf.write(f, f.relative_to(open_dir.parent))
PY
else
    "$VENV/bin/python" - "$OPEN" "$ARCHIVE/$ZIP_NAME" << 'PY'
import sys
import zipfile
from pathlib import Path

open_dir = Path(sys.argv[1])
zip_path = Path(sys.argv[2])
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
    for f in sorted(open_dir.rglob("*")):
        if f.is_file():
            zf.write(f, f.relative_to(open_dir.parent))
PY
    log "Архив без пароля (для пароля: DEPLOY_ARCHIVE_PASSWORD=... $0 --zip-password)"
fi

(
    cd "$ARCHIVE"
    sha256sum "$ZIP_NAME" > "$ZIP_NAME.sha256"
)

log "Готово."
log "  open/     — скопировать на флешку вместе с archive/"
log "  MANIFEST  — $SCRIPT_DIR/MANIFEST.sha256"
log "  ZIP       — $ARCHIVE/$ZIP_NAME"
echo ""
echo "Скопируйте на флешку каталог: $SCRIPT_DIR"
