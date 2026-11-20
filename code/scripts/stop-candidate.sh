#!/usr/bin/env bash
# Остановка ТОЛЬКО кандидата по PID-файлу пакета.
# Запрещено: pkill/killall по femsq-web / JarLauncher (погасит и 156).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PID_FILE="${PID_FILE:-$PKG_DIR/logs/candidate.pid}"
SERVER_PORT="${SERVER_PORT:-8081}"

if [[ ! -f "$PID_FILE" ]]; then
  echo "PID-файл нет: $PID_FILE — кандидат не запущен этим пакетом (или уже остановлен)."
  exit 0
fi

pid="$(cat "$PID_FILE" 2>/dev/null || true)"
if [[ -z "${pid:-}" ]]; then
  echo "Пустой PID-файл — удаляю."
  rm -f "$PID_FILE"
  exit 0
fi

if ! kill -0 "$pid" 2>/dev/null; then
  echo "Процесс PID $pid уже не жив — чищу PID-файл."
  rm -f "$PID_FILE"
  exit 0
fi

# Защита: убедиться, что это наш JarLauncher на нашем порту (если cmdline доступен).
cmd="$(ps -p "$pid" -o args= 2>/dev/null || true)"
if [[ -n "$cmd" ]]; then
  if [[ "$cmd" != *"JarLauncher"* ]]; then
    echo "ERROR: PID $pid не похож на FEMSQ JarLauncher: $cmd" >&2
    echo "Остановка отменена. Проверьте вручную." >&2
    exit 1
  fi
  if [[ "$cmd" != *"--server.port=${SERVER_PORT}"* && "$cmd" != *"server.port=${SERVER_PORT}"* ]]; then
    echo "WARN: в cmdline нет --server.port=${SERVER_PORT}; всё же останавливаю PID из файла пакета."
  fi
fi

echo "Stopping candidate PID=$pid (port hint $SERVER_PORT)..."
kill "$pid"
for i in $(seq 1 30); do
  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PID_FILE"
    echo "STOPPED"
    exit 0
  fi
  sleep 1
done

echo "WARN: не завершился за 30с — kill -9"
kill -9 "$pid" 2>/dev/null || true
rm -f "$PID_FILE"
echo "STOPPED (forced)"
