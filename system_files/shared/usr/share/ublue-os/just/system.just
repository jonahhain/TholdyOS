# vim: set ft=make :
########################
### aurora-system.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

# Run a one minute system benchmark
[group('System')]
benchmark:
    #!/usr/bin/env bash
    if ! type -P "stress-ng" &>/dev/null ; then
        if gum confirm "Stress does not seem to be on your path, do you wish to install it?" ; then
            set -eu
            brew install stress-ng
            brew link stress-ng
            set +eu
        else
            exit 0
        fi
    fi

    echo 'Running a 1 minute benchmark ...'
    trap popd EXIT
    pushd $(mktemp -d)
    stress-ng --matrix 0 -t 1m --times

# Configure docker,incus-admin,libvirt, container manager, serial permissions
[group('System')]
dx-group:
    #!/usr/bin/pkexec bash
    append_group() {
        local group_name="$1"
        if ! grep -q "^$group_name:" /etc/group; then
            echo "Appending $group_name to /etc/group"
            grep "^$group_name:" /usr/lib/group | sudo tee -a /etc/group > /dev/null
        fi
    }

    GROUPS_ADD=("docker" "incus-admin" "libvirt" "dialout")

    for GROUP_ADD in "${GROUPS_ADD[@]}" ; do
        append_group $GROUP_ADD
        usermod -aG $GROUP_ADD $USER
    done

    echo "Reboot system and log back in to use docker, libvirt, incus, and serial connections."

# Install system flatpaks for rebasers
[group('System')]
install-system-flatpaks $dx="dynamic":
    #!/usr/bin/env bash
    TARGET_FLATPAK_FILE="${TARGET_FLATPAK_FILE:-/etc/ublue-os/system-flatpaks.list}"
    TARGET_DEVMODE_FILE="${TARGET_DEVMODE_FILE:-/etc/ublue-os/system-flatpaks-dx.list}"
    case "$dx" in
        "0"|"1")
            ADD_DEVMODE="$dx"
            ;;
        "dynamic")
            if [[ $(jq '."image-flavor"' /usr/share/ublue-os/image-info.json) =~ dx ]] ; then
                ADD_DEVMODE=1
            fi
            ;;
        *)
            echo "Unsupported option"
            exit 1
            ;;
    esac

    flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo
    # Disable Fedora Flatpak remotes
       for remote in fedora fedora-testing; do
           if flatpak remote-list | grep -q "$remote"; then
               flatpak remote-delete "$remote"
           fi
       done
    xargs flatpak --system -y install --reinstall --or-update < $TARGET_FLATPAK_FILE
    if [ "$ADD_DEVMODE" == "1" ] ; then
        xargs flatpak --system -y install --reinstall --or-update < $TARGET_DEVMODE_FILE
    fi

# Configure grub bootmenu visibility
[group('System')]
configure-grub:
    @/usr/libexec/configure-grub.sh

alias switch-stream := rebase-helper
alias switch-streams := rebase-helper
alias rollback-helper := rebase-helper

# Rebase assistant
[group('System')]
rebase-helper:
    @/usr/bin/ublue-rollback-helper

# Configure Boot to Windows desktop entry
[group('System')]
configure-boot-to-windows:
    mkdir -p $HOME/.local/share/applications
    cp -r /usr/share/applications/boot-to-windows.desktop $HOME/.local/share/applications
    sed -i 's/Hidden=true/Hidden=false/' $HOME/.local/share/applications/boot-to-windows.desktop