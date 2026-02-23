#!/usr/bin/bash

set -euo pipefail

# Only run for domain users
id -Gn "$THOLDYOS_USER" 2>/dev/null | tr ' ' '\n' | grep -qx "domain users" || exit 0

# Use a temporary credential cache
KRB5CCNAME="FILE:$(mktemp /tmp/krb5cc_tholdyos_XXXXXX)"
export KRB5CCNAME

cleanup() { kdestroy 2>/dev/null; rm -f "${KRB5CCNAME#FILE:}"; }
trap cleanup EXIT

kinit -k "$(hostname -s | tr '[:lower:]' '[:upper:]')\$"

base_dn="dc=${DOMAIN//./,dc=}"
result=$(ldapsearch -Y GSSAPI -Q -LLL \
    -H "ldap://${DC_HOSTNAME}" \
    -b "$base_dn" \
    "(sAMAccountName=${THOLDYOS_USER})" \
    homeDirectory homeDrive 2>/dev/null) || true

home_dir=$(echo "$result" | sed -n 's/^homeDirectory: //p')
home_drive=$(echo "$result" | sed -n 's/^homeDrive: //p' | tr -d ':')

[[ -n "$home_dir" ]] || exit 0

# Convert UNC path to CIFS path
network_path="${home_dir//\\//}"

share_name="$THOLDYOS_USER"
[[ -z "$home_drive" ]] || share_name+=" (${home_drive}:)"

mountpoint="/home/${THOLDYOS_USER}/media/${share_name}"
mountpoint -q "$mountpoint" 2>/dev/null && exit 0

mkdir -p "$mountpoint"

mount_opts="file_mode=0700,dir_mode=0700,sec=krb5,nodev,nosuid,mfsymlinks,nobrl,vers=3.0"
mount_opts+=",user=${THOLDYOS_USER},domain=${REALM}"
mount_opts+=",uid=${THOLDYOS_UID},gid=${THOLDYOS_GID},cruid=${THOLDYOS_UID}"

if ! mount.cifs "$network_path" "$mountpoint" -o "$mount_opts"; then
    echo "Failed to mount ${network_path}" >&2
    rmdir "$mountpoint" 2>/dev/null || true
    exit 1
fi
