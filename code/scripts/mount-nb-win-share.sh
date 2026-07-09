#!/usr/bin/env bash
# Монтирование SMB-шары nb-win для общих Excel-файлов ревизий.
#
# Учётные данные: ~/.smbcredentials у пользователя, который запускает скрипт
# (при sudo — у SUDO_USER, не в /root).
#
# Использование:
#   cp docs/development/examples/smbcredentials.example ~/.smbcredentials
#   nano ~/.smbcredentials && chmod 600 ~/.smbcredentials
#   ./code/scripts/mount-nb-win-share.sh
#   # или: sudo ./code/scripts/mount-nb-win-share.sh

set -euo pipefail

MOUNT_POINT="/mnt/nb-win-share"
SHARE="//10.7.0.3/wire-guard-share-nb-win"

if [[ -n "${SUDO_USER:-}" ]]; then
  REAL_USER="$SUDO_USER"
  REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
  REAL_USER="${USER:-$(whoami)}"
  REAL_HOME="$HOME"
fi

CRED="${FEMSQ_SMB_CREDENTIALS:-${REAL_HOME}/.smbcredentials}"
MOUNT_UID="$(id -u "$REAL_USER")"
MOUNT_GID="$(id -g "$REAL_USER")"

if [[ ! -f "$CRED" ]]; then
  echo "Не найден файл учётных данных: $CRED" >&2
  echo "Создайте: cp docs/development/examples/smbcredentials.example ~/.smbcredentials" >&2
  echo "Заполните password, затем: chmod 600 ~/.smbcredentials" >&2
  if [[ -n "${SUDO_USER:-}" ]]; then
    echo "(При sudo используется ~/.smbcredentials пользователя $REAL_USER, не /root)" >&2
  fi
  exit 1
fi

if grep -qE '^password=$' "$CRED" || grep -qE '^password=\s*$' "$CRED"; then
  echo "Заполните password в $CRED" >&2
  exit 1
fi

chmod 600 "$CRED" 2>/dev/null || true

if mountpoint -q "$MOUNT_POINT"; then
  echo "Уже смонтировано: $MOUNT_POINT"
  ls -la "$MOUNT_POINT/femsq/excel/" 2>/dev/null | head -10 || ls -la "$MOUNT_POINT"
  exit 0
fi

MOUNT_OPTS="credentials=${CRED},uid=${MOUNT_UID},gid=${MOUNT_GID},file_mode=0644,dir_mode=0755,vers=3.0"

do_mount() {
  mkdir -p "$MOUNT_POINT"
  mount -t cifs "$SHARE" "$MOUNT_POINT" -o "$MOUNT_OPTS"
}

if [[ "$(id -u)" -eq 0 ]]; then
  do_mount
else
  sudo mkdir -p "$MOUNT_POINT"
  sudo mount -t cifs "$SHARE" "$MOUNT_POINT" -o "$MOUNT_OPTS"
fi

echo "OK: $SHARE -> $MOUNT_POINT (uid=$MOUNT_UID, cred=$CRED)"
ls -la "$MOUNT_POINT/femsq/excel/" 2>/dev/null | head -10 || ls -la "$MOUNT_POINT"
