#!/usr/bin/bash

set -xeou pipefail

echo "::group:: Copy Files"

# Copy Files to Image
rsync -rvK /ctx/system_files/ad/ /

echo "::endgroup::"

# Generate flatpak preinstall list
if [[ "${IMAGE_NAME}" =~ smartboard ]]; then
    FLATPAK_LIST="/etc/ublue-os/system-flatpaks-smartboard.list"
else
    FLATPAK_LIST="/etc/ublue-os/system-flatpaks.list"
fi
mkdir -p /etc/flatpak/preinstall.d
while IFS= read -r app; do
    [[ -z "$app" || "$app" == \#* ]] && continue
    cat <<EOF
[Flatpak Preinstall $app]
Branch=stable

EOF
done < "$FLATPAK_LIST" > /etc/flatpak/preinstall.d/tholdyos.preinstall
