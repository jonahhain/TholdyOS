#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

IMPORTANT_PACKAGES_AD=(
    adcli
    cifs-utils
    cloud-utils-growpart
    cyrus-sasl-gssapi
    krb5-workstation
    oddjob
    oddjob-mkhomedir
    openldap-clients
    pam_krb5
    realmd
    samba-client
    sssd
    sssd-ad
    sssd-tools
    sssd-ipa
    sssd-krb5
)

if [[ "${IMAGE_NAME}" =~ smartboard ]]; then
    IMPORTANT_PACKAGES_AD+=()
fi

for package in "${IMPORTANT_PACKAGES_AD[@]}"; do
        rpm -q "${package}" >/dev/null || { echo "Missing package: ${package}... Exiting"; exit 1 ; }
    done

IMPORTANT_UNITS=(
    "tholdyos-locale-setup.service"
    "tholdyos-resizefs.service"
    "tholdyos-domain-setup.service"
    "tholdyos-boot.service"
    "tholdyos-shutdown.service"
    "oddjobd.service"
)

for unit in "${IMPORTANT_UNITS[@]}"; do
    if ! systemctl is-enabled "$unit" 2>/dev/null | grep -q "^enabled$"; then
        echo "${unit} is not enabled"
        exit 1
    fi
done

if ! [[ -f /etc/tholdyos/domain-join.keytab ]]; then
    echo "DOMAIN_JOIN_KEYTAB not found"
    exit 1
fi

# Verify sudoers file has correct permissions
SUDOERS_PERMS=$(stat -c '%a' /etc/sudoers.d/50-tholdyos-ad)
if [[ "$SUDOERS_PERMS" != "440" ]]; then
    echo "sudoers file has wrong permissions: ${SUDOERS_PERMS} (expected 440)"
    exit 1
fi

echo "::endgroup::"
