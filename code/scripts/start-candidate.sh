#!/usr/bin/env bash
# Запуск ТОЛЬКО экземпляра-кандидата из каталога пакета.
# Не трогает действующий JAR 156 (другой каталог / порт / PID-файл).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PKG_DIR"

THIN_JAR="${THIN_JAR:-femsq-web-0.1.0.380-SNAPSHOT-thin.jar}"
LIB_DIR="${LIB_DIR:-$PKG_DIR/lib}"
PID_FILE="${PID_FILE:-$PKG_DIR/logs/candidate.pid}"
# На проде 156 обычно занимает 8080 — кандидат по умолчанию 8081.
SERVER_PORT="${SERVER_PORT:-8081}"
JAVA_BIN="${JAVA_BIN:-java}"

if [[ ! -f "$THIN_JAR" ]]; then
  echo "ERROR: thin JAR не найден: $PKG_DIR/$THIN_JAR" >&2
  exit 1
fi
if [[ ! -d "$LIB_DIR" ]] || ! ls "$LIB_DIR"/*.jar >/dev/null 2>&1; then
  echo "ERROR: lib/ пуст или отсутствует: $LIB_DIR" >&2
  exit 1
fi

mkdir -p "$PKG_DIR/logs" "$PKG_DIR/temp" "$PKG_DIR/reports"

if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${old_pid:-}" ]] && kill -0 "$old_pid" 2>/dev/null; then
    echo "ERROR: кандидат уже запущен (PID $old_pid). Сначала: scripts/stop-candidate.sh" >&2
    exit 1
  fi
  rm -f "$PID_FILE"
fi

TS="$(date +%y-%m%d-%H%M)"
LOG_FILE="$PKG_DIR/logs/candidate_${TS}.log"

echo "PKG_DIR=$PKG_DIR"
echo "THIN_JAR=$THIN_JAR"
echo "SERVER_PORT=$SERVER_PORT"
echo "LOG_FILE=$LOG_FILE"
echo "FEMSQ_CONFIG_PATH=${FEMSQ_CONFIG_PATH:-<default ~/.femsq/database.properties>}"

nohup "$JAVA_BIN" \
  -Dloader.path="lib/" \
  -cp "$THIN_JAR:$LIB_DIR/*" \
  org.springframework.boot.loader.launch.JarLauncher \
  --server.port="$SERVER_PORT" \
  >"$LOG_FILE" 2>&1 &

echo $! >"$PID_FILE"
echo "STARTED PID=$(cat "$PID_FILE")"
echo "Проверка: curl -sS http://127.0.0.1:${SERVER_PORT}/api/v1/app/version"
