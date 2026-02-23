ARG BASE_IMAGE_NAME="kinoite"
ARG FEDORA_MAJOR_VERSION="41"
ARG SOURCE_IMAGE="${BASE_IMAGE_NAME}-main"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"

FROM scratch AS ctx
COPY /build_files /build_files
COPY /deployment /deployment

COPY /flatpaks /flatpaks
COPY /logos /logos
COPY /system_files /system_files

# Overwrite files from common if necessary
COPY /system_files /system_files

## image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS base

ARG AKMODS_FLAVOR="coreos-stable"
ARG BASE_IMAGE_NAME="kinoite"
ARG FEDORA_MAJOR_VERSION="41"
ARG IMAGE_NAME="tholdyos"
ARG IMAGE_VENDOR="jonahhain"
ARG KERNEL="6.14.4-200.fc41.x86_64"
ARG SHA_HEAD_SHORT="dedbeef"
ARG UBLUE_IMAGE_TAG="stable"
ARG VERSION=""
ARG IMAGE_FLAVOR=""

# Build, cleanup, lint.
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=secret,id=GITHUB_TOKEN \
    --mount=type=secret,id=DOMAIN_JOIN_KEYTAB \
    /ctx/build_files/shared/build.sh

# Makes `/opt` writeable by default
# Needs to be here to make the main image build strict (no /opt there)
# This is for downstream images/stuff like k0s
RUN rm -rf /opt && ln -s /var/opt /opt

CMD ["/sbin/init"]

RUN bootc container lint
