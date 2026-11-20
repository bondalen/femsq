#!/usr/bin/env bash
# Сборка пакета кандидата R1.x в dist/<YY-MMDD-R1.x>/
# По умолчанию: thin+fat JAR 0.1.0.380 (PASS §1). Не выкладывает на прод.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$CODE_ROOT/.." && pwd)"

VERSION="${CANDIDATE_VERSION:-0.1.0.380-SNAPSHOT}"
VERSION_SHORT="${VERSION%-SNAPSHOT}"
PKG_NAME="${CANDIDATE_PKG_NAME:-26-1119-R1.0}"
PKG_DIR="${CANDIDATE_OUT:-$REPO_ROOT/dist/$PKG_NAME}"

FAT="$CODE_ROOT/femsq-backend/femsq-web/target/femsq-web-${VERSION_SHORT}-SNAPSHOT.jar"
THIN="$CODE_ROOT/femsq-backend/femsq-web/target/femsq-web-${VERSION_SHORT}-SNAPSHOT-thin.jar"
SQLSRC="$REPO_ROOT/docs/development/notes/sql/26-1119-ra-change-au/MSSQL2012"
OPDOC="$REPO_ROOT/docs/deployment/r1.0-candidate-operator.md"

if [[ ! -f "$FAT" || ! -f "$THIN" ]]; then
  echo "ERROR: нет JAR $VERSION. Сначала ./code/scripts/build-thin-jar.sh или CANDIDATE_VERSION=..." >&2
  exit 1
fi

echo "=== pack-candidate-r1x: $PKG_NAME ($VERSION) → $PKG_DIR ==="
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR"/{lib,scripts,sql/MSSQL2012,logs,temp,reports}

cp -a "$THIN" "$PKG_DIR/"
"$SCRIPT_DIR/extract-libs-from-fatjar.sh" "$FAT" "$PKG_DIR"
cp -a "$SQLSRC"/*.sql "$PKG_DIR/sql/MSSQL2012/"
[[ -f "$SQLSRC/../README.md" ]] && cp -a "$SQLSRC/../README.md" "$PKG_DIR/sql/README.md"
[[ -f "$OPDOC" ]] && cp -a "$OPDOC" "$PKG_DIR/OPERATOR.md"
cp -a "$SCRIPT_DIR/start-candidate.sh" "$SCRIPT_DIR/stop-candidate.sh" "$PKG_DIR/scripts/"
chmod +x "$PKG_DIR/scripts/"*.sh

# Подставить имя thin JAR в start-скрипт пакета
sed -i "s/femsq-web-0\\.1\\.0\\.380-SNAPSHOT-thin\\.jar/femsq-web-${VERSION_SHORT}-SNAPSHOT-thin.jar/g" \
  "$PKG_DIR/scripts/start-candidate.sh"

cat > "$PKG_DIR/VERSION" <<EOF
package=$PKG_NAME
app_version=$VERSION
thin_jar=femsq-web-${VERSION_SHORT}-SNAPSHOT-thin.jar
packed_at=$(date -Is)
gate=PASS §1 DEV 2026-11-19 (FishEye_prod_noM6)
EOF

(
  cd "$PKG_DIR"
  find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
)

echo "OK: $(du -sh "$PKG_DIR" | cut -f1), lib=$(ls -1 "$PKG_DIR/lib"/*.jar | wc -l) jars, checksums=$(wc -l < "$PKG_DIR/SHA256SUMS")"
echo "Инструкция: docs/deployment/r1.0-candidate-operator.md"
