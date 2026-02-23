#!/usr/bin/bash

set -euo pipefail

SHARE_MOUNT_BASE="/home/${THOLDYOS_USER}/media"

[[ -d "$SHARE_MOUNT_BASE" ]] || exit 0

for dir in "$SHARE_MOUNT_BASE"/*/; do
    [[ -d "$dir" ]] || continue
    dir="${dir%/}"

    if mountpoint -q "$dir" 2>/dev/null; then
        umount "$dir" || true
    fi

    if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir")" ]]; then
        rmdir "$dir" 2>/dev/null || true
    fi
done

rmdir "$SHARE_MOUNT_BASE" 2>/dev/null || true
