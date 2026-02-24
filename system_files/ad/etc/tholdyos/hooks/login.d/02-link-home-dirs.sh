#!/usr/bin/bash

set -euo pipefail

# Only run for domain users
id -Gn "$THOLDYOS_USER" 2>/dev/null | tr ' ' '\n' | grep -qx "domain users" || exit 0

HOME_DIR="/home/${THOLDYOS_USER}"
MEDIA_DIR="${HOME_DIR}/media"
XDG_DIRS=(Dokumente Musik Bilder Videos)

# Find the mounted home share
home_share=""
if [[ -d "$MEDIA_DIR" ]]; then
    for dir in "$MEDIA_DIR"/*/; do
        [[ -d "$dir" ]] || continue
        dir="${dir%/}"
        [[ "$(basename "$dir")" != "Shares" ]] || continue
        mountpoint -q "$dir" 2>/dev/null || continue
        home_share="$dir"
        break
    done
fi

# If the share is not mounted, clean up symlinks
if [[ -z "$home_share" ]]; then
    for xdg_dir in "${XDG_DIRS[@]}"; do
        link="${HOME_DIR}/${xdg_dir}"
        if [[ -L "$link" ]] && ! [[ -e "$link" ]]; then
            rm -f "$link"
            mkdir -p "$link"
            chown "${THOLDYOS_UID}:${THOLDYOS_GID}" "$link"
        fi
    done
    echo "Home share is not mounted"
    exit 0
fi

for xdg_dir in "${XDG_DIRS[@]}"; do
    target="${home_share}/${xdg_dir}"
    link="${HOME_DIR}/${xdg_dir}"

    # Create directory if it doesn't exist
    mkdir -p "$target"

    # Already symlinked correctly
    if [[ -L "$link" ]] && [[ "$(readlink "$link")" == "$target" ]]; then
        continue
    fi

    # If a real directory exists, migrate its contents to the share
    if [[ -d "$link" && ! -L "$link" ]]; then
        if [[ -n "$(ls -A "$link" 2>/dev/null)" ]]; then
            # Copy local files without overwriting existing ones
            cp -a --no-clobber "$link"/. "$target"/ 2>/dev/null || true
            echo "Migrated contents of $link to share"
        fi
        rm -rf "$link"
    fi

    # Remove any stale symlinks
    [[ ! -L "$link" ]] || rm -f "$link"

    ln -s "$target" "$link"
    chown -h "${THOLDYOS_UID}:${THOLDYOS_GID}" "$link"
done
