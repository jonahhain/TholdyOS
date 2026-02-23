#!/usr/bin/bash

set -euo pipefail

# Only run for domain users or the "station" user
is_domain_user=false
id -Gn "$THOLDYOS_USER" 2>/dev/null | tr ' ' '\n' | grep -qx "domain users" && is_domain_user=true

if ! $is_domain_user && [[ "$THOLDYOS_USER" != "station" ]]; then
    exit 0
fi

mountpoint="/home/${THOLDYOS_USER}/media/Shares"
mountpoint -q "$mountpoint" 2>/dev/null && exit 0

mkdir -p "$mountpoint"

if $is_domain_user; then
    mount_opts="file_mode=0700,dir_mode=0700,sec=krb5,nodev,nosuid,mfsymlinks,nobrl,vers=3.0"
    mount_opts+=",user=${THOLDYOS_USER},domain=${REALM}"
    mount_opts+=",uid=${THOLDYOS_UID},gid=${THOLDYOS_GID},cruid=${THOLDYOS_UID}"
else
    mount_opts="guest,file_mode=0700,dir_mode=0700,nodev,nosuid,mfsymlinks,nobrl,vers=3.0"
    mount_opts+=",uid=${THOLDYOS_UID},gid=${THOLDYOS_GID}"
fi

if ! mount.cifs "//${DC_HOSTNAME}/default-school/share" "$mountpoint" -o "$mount_opts"; then
    echo "Failed to mount share drive" >&2
    rmdir "$mountpoint" 2>/dev/null || true
fi
