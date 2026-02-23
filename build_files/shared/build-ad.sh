#!/usr/bin/bash

set -xeou pipefail

echo "::group:: Copy Files"

# Copy Files to Image
rsync -rvK /ctx/system_files/ad/ /

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/build_files/shared/utils/ghcurl /tmp/scripts/helpers/ghcurl
export PATH="/tmp/scripts/helpers:$PATH"

echo "::endgroup::"

# Install smartboard Packages and setup AD
/ctx/build_files/ad/00-ad.sh

# Validate all repos are disabled before committing
/ctx/build_files/shared/validate-repos.sh

# ad specific tests
/ctx/build_files/ad/10-tests-ad.sh
