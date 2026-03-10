#!/usr/bin/bash

set -xeou pipefail

echo "::group:: Copy Files"

# Copy Files to Image
rsync -rvK /ctx/system_files/ad/ /

echo "::endgroup::"
