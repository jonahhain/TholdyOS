#!/usr/bin/bash

set -xeou pipefail

echo "::group:: Copy Files"

# Copy Files to Image
rsync -rvK /ctx/system_files/ad/ /

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/build_files/shared/utils/ghcurl /tmp/scripts/helpers/ghcurl
export PATH="/tmp/scripts/helpers:$PATH"

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

echo "::endgroup::"

# Changes specific to AD
/ctx/build_files/ad/00-ad.sh

# Validate all repos are disabled before committing
/ctx/build_files/shared/validate-repos.sh

# Tests specific to AD
/ctx/build_files/ad/10-tests-ad.sh
