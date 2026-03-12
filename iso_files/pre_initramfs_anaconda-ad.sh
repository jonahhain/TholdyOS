#!/usr/bin/env bash

set -eoux pipefail

dnf install -y anaconda-dracut libblockdev-btrfs libblockdev-lvm libblockdev-dm
