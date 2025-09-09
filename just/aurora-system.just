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
    source /usr/lib/ujust/ujust.sh
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

# Configure Aurora-CLI Terminal Experience with Brew
[group('System')]
aurora-cli:
    @/usr/libexec/ublue-bling

# Install fonts from brew
[group('System')]
install-fonts:
    #!/usr/bin/bash
    echo "Installing extra fonts..."
    brew bundle --file /usr/share/ublue-os/homebrew/aurora-fonts.Brewfile

# Install Kubernetes CLI dev tools
[group('System')]
install-k8s-dev-tools:
    #!/usr/bin/bash
    echo "Adding Kubernetes command line tools..."
    brew bundle --file /usr/share/ublue-os/homebrew/kubernetes.Brewfile

# Ptyxis terminal transparency
[group('System')]
ptyxis-transparency opacity="0.95":
    #!/usr/bin/env bash
    set -euxo pipefail
    if [[ -n "$(echo "{{ opacity }}" | grep -v '^[.0-9]*$')" ]]; then
        printf "Value must be numeric: %s.\n" "{{ opacity }}"
    elif [[ $(echo "0<{{ opacity }} && 1>={{ opacity }}" | bc -q) -eq 1 ]]; then
        raw="$(gsettings get org.gnome.Ptyxis profile-uuids)"
        uuids="$(sed -En 's|[^0-9a-z]*||g; s|([0-9a-z]{32})|\1\n|gp' <<<${raw})"
        for i in ${uuids}; do
            location="org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${i}/"
            gsettings set "${location}" opacity "{{ opacity }}"; done
        printf "Ptyxis opacity is now %s.\n" "{{ opacity }}"
    else
        printf "Value must be greater than 0 and less than or equal to 1: %s.\n" "{{ opacity }}"
    fi

# Install system flatpaks for rebasers
[group('System')]
install-system-flatpaks:
    #!/usr/bin/env bash
    TARGET_FLATPAK_FILE="${TARGET_FLATPAK_FILE:-/etc/ublue-os/system-flatpaks.list}"
    flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo
    # Disable Fedora Flatpak remotes
       for remote in fedora fedora-testing; do
           if flatpak remote-list | grep -q "$remote"; then
               flatpak remote-delete "$remote"
           fi
       done
    xargs flatpak --system -y install --reinstall --or-update < $TARGET_FLATPAK_FILE

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

# Toggle tailscale
[group('System')]
toggle-tailscale:
    #!/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    source /usr/lib/os-release

    TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"

    if [ "$TAILSCALED_STATUS" == "enabled" ] || [ "$TAILSCALED_STATUS" == "disabled" ]; then
        TAILSCALED="Installed"
    else
        TAILSCALED="Not Found"
        echo "${b}${red}Unable to enable or disable Tailscale.${n}"
        echo "The tailscaled service must be present and either enabled or disabled to run this script."
        echo "tailscaled service status: $TAILSCALED_STATUS"
    fi


    if [ "$TAILSCALED" == "Installed" ]; then
        echo "Enable or disable Tailscale?"
        TS_OPTION=$(Choose Enable Disable)

        if [ "$TS_OPTION" = "Enable" ]; then
            systemctl enable --now tailscaled
            TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"
            if [ "$TAILSCALED_STATUS" == "enabled" ]; then
                echo "${b}${green}Tailscale is enabled.${n}"
                echo "If this is your first time using Tailscale, setup is necessary."
                echo "Refer to Tailscale's documentation at https://tailscale.com/kb/1346/start."
            fi
        elif [ "$TS_OPTION" = "Disable" ]; then
            systemctl disable --now tailscaled
            TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"
            if [ "$TAILSCALED_STATUS" == "disabled" ]; then
                echo "${b}${red}Tailscale is disabled.${n}"
            fi
        fi
    fi

# Automatically download Bluefin's monthly dinosaur wallpapers
[group('System')]
toggle-dinosaurs hemisphere="north":
    #!/bin/bash
    source /usr/lib/ujust/ujust.sh

    if [[ "{{ hemisphere }}" != "north" && "{{ hemisphere }}" != "south" ]]; then
        echo "Error: Invalid hemisphere '{{ hemisphere }}'. Must be 'north' or 'south'."
        exit 1
    fi

    DINOSAUR_STATUS="$(systemctl --user is-enabled bluefin-wallpaper@{{ hemisphere }}.service 2>/dev/null || echo 'disabled')"

    echo "Bluefin dinosaur wallpapers ({{ hemisphere }}ern hemisphere) are currently: $DINOSAUR_STATUS"

    if [ "$DINOSAUR_STATUS" == "enabled" ]; then
        echo "Disable Bluefin dinosaur wallpapers?"
        OPTION=$(Choose Disable Cancel)
        if [ "$OPTION" = "Disable" ]; then
            systemctl --user disable --now bluefin-wallpaper@{{ hemisphere }}.service
            echo "${b}${red}Bluefin dinosaur wallpapers ({{ hemisphere }}ern hemisphere) disabled.${n}"
            echo "Wallpaper files remain in ~/.local/share/wallpapers/Bluefin/"
        fi
    else
        echo "Enable Bluefin dinosaur wallpapers for the {{ hemisphere }}ern hemisphere?"
        OPTION=$(Choose Enable Cancel)
        if [ "$OPTION" = "Enable" ]; then
            mkdir -p ~/.local/share/wallpapers/Bluefin
            systemctl --user enable --now bluefin-wallpaper@{{ hemisphere }}.service

            sleep 1
            if systemctl --user is-active --quiet bluefin-wallpaper@{{ hemisphere }}.service; then
                echo "${b}${green}Bluefin dinosaur wallpapers ({{ hemisphere }}ern hemisphere) enabled!${n}"
                echo "Wallpapers will be downloaded to ~/.local/share/wallpapers/Bluefin/"
                echo "The wallpaper will update automatically each month."
                filename="$HOME/.local/share/wallpapers/Bluefin/{{ hemisphere }}.avif"

                qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
                    var allDesktops = desktops();
                    for (var i = 0; i < allDesktops.length; i++) {
                        var d = allDesktops[i];
                        d.wallpaperPlugin = \"com.github.zzag.dynamic\";
                        d.currentConfigGroup = Array(\"Wallpaper\", \"com.github.zzag.dynamic\", \"General\");
                        d.writeConfig(\"Image\", \"file:///${filename}\");
                    }
                "
            else
                echo "${b}${red}Failed to start bluefin-wallpaper service.${n}"
                echo "Check the service status with:"
                echo "  systemctl --user status bluefin-wallpaper@{{ hemisphere }}.service"
            fi
        fi
    fi

# Configure Boot to Windows desktop entry
[group('System')]
configure-boot-to-windows:
    mkdir -p $HOME/.local/share/applications
    cp -r /usr/share/applications/boot-to-windows.desktop $HOME/.local/share/applications
    sed -i 's/Hidden=true/Hidden=false/' $HOME/.local/share/applications/boot-to-windows.desktop

# Toggle IWD
[group('System')]
toggle-iwd:
    #!/usr/bin/bash
    echo -e "This script manages enabling or disabling iwd as a replacement for wpa_supplicant for Wi-Fi networking."
    echo -e "Enabling this can improve throughput, mesh networking, and reduce latency increases when scanning for networks"
    echo -e "Disabling this can improve corporate or eduroam network compatibility"
    echo -e ""
    echo -e "WARNING: Changing this will remove all saved wifi networks"
    get_current_status() {
      if [[ -f "/etc/NetworkManager/conf.d/iwd.conf" ]]; then
        echo "Enabled"
      else
        echo "Disabled"
      fi
    }
    remove_saved_networks() {
      nmcli -t -f NAME connection show | while read -r line; do sudo nmcli connection delete "$line"; done
    }
    enable_iwd() {
      sudo mkdir -p "/etc/NetworkManager/conf.d/"
      sudo rm -f "/etc/NetworkManager/conf.d/iwd.conf"
      printf "[device]\nwifi.backend=iwd" | sudo tee /etc/NetworkManager/conf.d/iwd.conf > /dev/null
      remove_saved_networks
      echo -e "iwd enabled. Reboot required to apply changes."
    }
    disable_iwd() {
      sudo rm -f "/etc/NetworkManager/conf.d/iwd.conf"
      remove_saved_networks
      echo -e "iwd disabled. Reboot required to apply changes."
    }
    # Display current status
    current_status=$(get_current_status)
    echo -e "\nCurrent iwd status: $current_status\n"
    # Prompt user for action
    CHOICE=$(gum choose "Enable iwd" "Disable iwd" "Exit without changes")
    case "$CHOICE" in
      "Enable iwd")
        enable_iwd
        ;;
      "Disable iwd")
        disable_iwd
        ;;
      "Exit without changes")
        echo "No changes made."
        ;;
      *)
        echo "Invalid choice. Exiting without changes."
        ;;
    esac
