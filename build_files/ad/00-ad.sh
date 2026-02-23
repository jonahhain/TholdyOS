#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# Load secure COPR helpers
# shellcheck source=build_files/shared/copr-helpers.sh
source /ctx/build_files/shared/copr-helpers.sh

# NOTE:
# Packages are split into FEDORA_PACKAGES and COPR_PACKAGES to prevent
# malicious COPRs from injecting fake versions of Fedora packages.
# Fedora packages are installed first in bulk (safe).
# COPR packages are installed individually with isolated enablement.

# AD Packages from Fedora repos
FEDORA_PACKAGES=(
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

# AD packages to exclude
EXCLUDED_PACKAGES=()

if [[ "${IMAGE_NAME}" =~ smartboard ]]; then
    # Additional packages for smartboard
    FEDORA_PACKAGES+=()

    # Packages to exclude for smartboard
    EXCLUDED_PACKAGES+=(
        pycharm-professional
    )

    # SDDM autologin config for smartboard
    install -dm0755 /etc/sddm.conf.d
    tee /etc/sddm.conf.d/autologin.conf <<'EOF'
[Autologin]
User=station
Session=plasma.desktop
EOF
fi

if [[ "${#FEDORA_PACKAGES[@]}" -gt 0 ]]; then
    echo "Installing ${#FEDORA_PACKAGES[@]} additional packages from Fedora repos..."
    dnf5 -y install "${FEDORA_PACKAGES[@]}"
fi

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf5 -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

# Set permissions for custom sudoers file
chmod 440 /etc/sudoers.d/50-tholdyos-ad

# Enable AD-specific services
systemctl enable tholdyos-locale-setup.service
systemctl enable tholdyos-resizefs.service
systemctl enable tholdyos-domain-setup.service
systemctl enable tholdyos-boot.service
systemctl enable tholdyos-shutdown.service
systemctl enable oddjobd.service

# Inject domain join keytab from build secret
echo "Injecting domain join keytab from build secret..."
mkdir -p /etc/tholdyos
base64 -d /run/secrets/DOMAIN_JOIN_KEYTAB > /etc/tholdyos/domain-join.keytab
chmod 600 /etc/tholdyos/domain-join.keytab

# NOTE: With isolated COPR installation, most repos are never enabled globally.
# We only need to clean up repos that were enabled during the build process.
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-cisco-openh264.repo

# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# Disable RPM Fusion repos
for i in /etc/yum.repos.d/rpmfusion-*.repo; do
    if [[ -f "$i" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "$i"
    fi
done

echo "::endgroup::"
