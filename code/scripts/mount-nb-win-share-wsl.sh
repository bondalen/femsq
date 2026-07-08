#!/usr/bin/env bash
# Bind-mount Windows-шары на nb-win (WSL) в тот же путь, что на Fedora (/mnt/nb-win-share).
# Запускать в терминале WSL на nb-win после старта системы.
#
# Windows: D:\wire-guard-share-nb-win  (SMB: wire-guard-share-nb-win)
# Fedora:   CIFS //10.7.0.3/wire-guard-share-nb-win -> /mnt/nb-win-share
#
# Использование: ./code/scripts/mount-nb-win-share-wsl.sh

set -euo pipefail

WIN_SHARE="/mnt/d/wire-guard-share-nb-win"
MOUNT_POINT="/mnt/nb-win-share"

if [[ ! -d "$WIN_SHARE" ]]; then
  echo "Не найдена Windows-папка: $WIN_SHARE" >&2
  echo "Проверьте, что диск D: доступен в WSL (drvfs)." >&2
  exit 1
fi

sudo mkdir -p "$MOUNT_POINT"

if mountpoint -q "$MOUNT_POINT"; then
  echo "Уже смонтировано: $MOUNT_POINT"
  ls -la "$MOUNT_POINT/femsq/excel/" 2>/dev/null | head -5 || ls -la "$MOUNT_POINT"
  exit 0
fi

sudo mount --bind "$WIN_SHARE" "$MOUNT_POINT"

echo "OK: $WIN_SHARE -> $MOUNT_POINT"
ls -la "$MOUNT_POINT/femsq/excel/" 2>/dev/null | head -10
