ARG BASE_IMAGE_ORG="${BASE_IMAGE_ORG}:-quay.io/fedora-ostree-desktops"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}:-kinoite"
ARG BASE_IMAGE="${BASE_IMAGE_ORG}/${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}:-43"

FROM scratch AS ctx
COPY /build_files /build_files
COPY /deployment /deployment

COPY /flatpaks /flatpaks
COPY /logos /logos
COPY /system_files /system_files

## image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS base

ARG AKMODS_FLAVOR="coreos-stable"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION=""
ARG IMAGE_NAME="tholdyos"
ARG IMAGE_VENDOR="jonahhain"
ARG KERNEL=""
ARG SHA_HEAD_SHORT="dedbeef"
ARG UBLUE_IMAGE_TAG="stable"
ARG VERSION=""
ARG IMAGE_FLAVOR=""

# so ghcurl wrapper is available to all later RUNs
ENV PATH="/tmp/scripts/helpers:${PATH}"

# Copy files from common/from system_files
# Install Packages, miscellaneous things that need a network
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/var \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=secret,id=GITHUB_TOKEN \
    --mount=type=secret,id=DOMAIN_JOIN_KEYTAB \
    /ctx/build_files/shared/build.sh && \
    /ctx/build_files/base/01-packages.sh && \
    /ctx/build_files/base/02-install-kernel-akmods.sh && \
    /ctx/build_files/base/03-fetch.sh

# Everything that can be done offline after things are in place should be done here
RUN --network=none \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/run \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    /ctx/build_files/base/16-override-install.sh && \
    /ctx/build_files/base/17-cleanup.sh && \
    /ctx/build_files/base/18-image-info.sh && \
    /ctx/build_files/base/19-initramfs.sh && \
    /ctx/build_files/shared/validate-repos.sh && \
    /ctx/build_files/shared/clean-stage.sh && \
    /ctx/build_files/base/20-tests.sh

CMD ["/sbin/init"]

RUN bootc container lint
