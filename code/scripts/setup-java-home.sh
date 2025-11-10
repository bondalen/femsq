#!/usr/bin/env bash
# Настройка переменной JAVA_HOME для окружения FEMSQ
# Использует текущую установку Java (команда `java`) и вычисляет корневую директорию JDK.

set -euo pipefail

JAVA_BIN_SYMLINK="$(command -v java || true)"
if [[ -z "${JAVA_BIN_SYMLINK}" ]]; then
  echo "[ERROR] Команда 'java' не найдена. Установите JDK и повторите попытку." >&2
  exit 1
fi

JAVA_BIN_PATH="$(readlink -f "${JAVA_BIN_SYMLINK}")"
JAVA_HOME_CANDIDATE="$(dirname "${JAVA_BIN_PATH}")"
JAVA_HOME_CANDIDATE="$(dirname "${JAVA_HOME_CANDIDATE}")"

if [[ ! -d "${JAVA_HOME_CANDIDATE}/bin" ]]; then
  echo "[ERROR] Не удалось определить корень JDK по пути: ${JAVA_HOME_CANDIDATE}" >&2
  exit 1
fi

export JAVA_HOME="${JAVA_HOME_CANDIDATE}"

case ":${PATH}:" in
  *":${JAVA_HOME}/bin:"*) ;;
  *) export PATH="${JAVA_HOME}/bin:${PATH}" ;;
 esac

echo "JAVA_HOME=${JAVA_HOME}"