#!/usr/bin/bash

set -euo pipefail

while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    umount "$target" || true
done < <(findmnt -t cifs -rn -o TARGET)
