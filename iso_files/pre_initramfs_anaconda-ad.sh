#!/usr/bin/env bash

set -eoux pipefail

dnf install -y anaconda-dracut libblockdev-btrfs libblockdev-lvm libblockdev-dm

tee /etc/dracut.conf.d/ublue-anaconda.conf <<'EOF'
# Add Anaconda dracut modules
add_dracutmodules+=" anaconda "
EOF
