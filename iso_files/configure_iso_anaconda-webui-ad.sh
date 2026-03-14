#!/usr/bin/env bash

set -eoux pipefail

IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
IMAGE_TAG="$(jq -c -r '."image-tag"' <<<"$IMAGE_INFO")"
IMAGE_REF="$(jq -c -r '."image-ref"' <<<"$IMAGE_INFO")"
IMAGE_NAME="$(jq -c -r '."image-name"' <<<"$IMAGE_INFO")"
IMAGE_REF="${IMAGE_REF##*://}"
sbkey='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der'

# Configure Live Environment

glib-compile-schemas /usr/share/glib-2.0/schemas

systemctl disable rpm-ostree-countme.service
systemctl disable bootloader-update.service
systemctl disable rpm-ostreed-automatic.timer
systemctl disable uupd.timer
systemctl disable tholdyos-boot.service
systemctl disable tholdyos-shutdown.service
systemctl disable ublue-system-setup.service
systemctl disable tholdyos-domain-setup.service
systemctl --global disable podman-auto-update.timer

# HACK for https://bugzilla.redhat.com/show_bug.cgi?id=2433186
rpm --erase --nodeps --justdb generic-logos
dnf download fedora-logos
rpm -i --justdb fedora-logos*.rpm
rm -f fedora-logos*.rpm

# Install Anaconda (text mode only, no webui needed)
dnf install -y anaconda-tui

rpm --erase --nodeps --justdb fedora-logos

# Anaconda Profile Detection

# TholdyOS AD
tee /etc/anaconda/profile.d/tholdyos.conf <<'EOF'
# Anaconda configuration file for TholdyOS AD

[Profile]
# Define the profile.
profile_id = tholdyos

[Profile Detection]
# Match os-release values
os_id = tholdyos

[Network]
default_on_boot = FIRST_WIRED_WITH_LINK

[Bootloader]
efi_dir = fedora
menu_auto_hide = True

[Storage]
default_scheme = BTRFS
btrfs_compression = zstd:1
default_partitioning =
    /     (min 1 GiB, max 70 GiB)
    /home (min 500 MiB, free 50 GiB)
    /var  (btrfs)
EOF

# Configure
. /etc/os-release
echo "TholdyOS release $VERSION_ID ($VERSION_CODENAME)" >/etc/system-release

# Build the automated kickstart
KICKSTART="/usr/share/anaconda/automated.ks"

cat > "$KICKSTART" <<KSEOF
# TholdyOS AD Automated Installation

# Localization
lang de_DE.UTF-8
keyboard --vckeymap=de --xlayouts='de'
timezone Europe/Berlin --utc

# Network
network --bootproto=dhcp --onboot=yes --activate

# Partitioning
zerombr
clearpart --all --drives=sda --initlabel --disklabel=gpt
autopart

# Users
rootpw --lock
KSEOF

# User entries
cat >> "$KICKSTART" <<'KSEOF'
user --name=local-admin --groups=wheel --password=$6$IkRLyAcOeRh62F4/$V8hvWX0ZgS/xpnFSgEWN8E64F8p3bAtEvTtG.lQdZqjYc5E56RkhM./qeCNFmkzbXKOJ0nRci/tFAa2B52bap1 --iscrypted
KSEOF

if [[ "$IMAGE_NAME" =~ smartboard ]]; then
    echo "user --name=station" >> "$KICKSTART"
fi

# Image and post-install directives
cat >> "$KICKSTART" <<KSEOF

# Image
ostreecontainer --url=$IMAGE_REF:$IMAGE_TAG --transport=containers-storage --no-signature-verification

# Set graphical.target as default
xconfig --startxonboot

# Reboot after installation
reboot

# Post-install scripts
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%include /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks
%include /usr/share/anaconda/post-scripts/install-flatpaks.ks
%include /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
KSEOF

# Signed Images
tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail

# Temporary workaround for ostree-booted check
if [ ! -f /run/ostree-booted ]; then
    touch /run/ostree-booted
    CLEANUP_OSTREE_BOOTED=1
fi

bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $IMAGE_REF:$IMAGE_TAG

if [ -n "\$CLEANUP_OSTREE_BOOTED" ]; then
    rm -f /run/ostree-booted
fi
%end
EOF

# Disable Fedora Flatpak
tee /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks <<'EOF'
%post --erroronfail
systemctl disable flatpak-add-fedora-repos.service
%end
EOF

# Install Flatpaks
tee /usr/share/anaconda/post-scripts/install-flatpaks.ks <<'EOF'
%post --erroronfail --nochroot
deployment="$(ostree rev-parse --repo=/mnt/sysimage/ostree/repo ostree/0/1/0)"
target="/mnt/sysimage/ostree/deploy/default/deploy/$deployment.0/var/lib/"
mkdir -p "$target"
rsync -aAXUHKP /var/lib/flatpak "$target"
%end
EOF

# cleanup our leftovers
rm -rf /flatpak-list

# Fetch the Secureboot Public Key
curl --retry 15 -Lo /etc/sb_pubkey.der "$sbkey"

# Enroll Secureboot Key
tee /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks <<'EOF'
%post --erroronfail --nochroot
set -oue pipefail

readonly ENROLLMENT_PASSWORD="universalblue"
readonly SECUREBOOT_KEY="/etc/sb_pubkey.der"

if [[ ! -d "/sys/firmware/efi" ]]; then
    echo "EFI mode not detected. Skipping key enrollment."
    exit 0
fi

if [[ ! -f "$SECUREBOOT_KEY" ]]; then
    echo "Secure boot key not provided: $SECUREBOOT_KEY"
    exit 0
fi

mokutil --timeout -1 || :
echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "$SECUREBOOT_KEY" || :
%end
EOF
