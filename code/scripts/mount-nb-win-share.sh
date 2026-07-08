#!/usr/bin/env bash
# Монтирование SMB-шары nb-win для общих Excel-файлов ревизий.
# Использование:
#   1. Заполните password в ~/.smbcredentials (chmod 600)
#   2. ./code/scripts/mount-nb-win-share.sh

set -euo pipefail

CRED="${HOME}/.smbcredentials"
MOUNT_POINT="/mnt/nb-win-share"
SHARE="//10.7.0.3/wire-guard-share-nb-win"

if [[ ! -f "$CRED" ]]; then
  echo "Создайте $CRED с полями username, password, domain" >&2
  exit 1
fi

if grep -q '^password=$' "$CRED" || grep -q '^password=\s*$' "$CRED"; then
  echo "Заполните password в $CRED (nano $CRED)" >&2
  exit 1
fi

chmod 600 "$CRED"

if mountpoint -q "$MOUNT_POINT"; then
  echo "Уже смонтировано: $MOUNT_POINT"
  ls -la "$MOUNT_POINT"
  exit 0
fi

sudo mount -t cifs "$SHARE" "$MOUNT_POINT" \
  -o "credentials=${CRED},uid=$(id -u),gid=$(id -g),file_mode=0644,dir_mode=0755,vers=3.0"

echo "OK: $SHARE -> $MOUNT_POINT"
ls -la "$MOUNT_POINT"
