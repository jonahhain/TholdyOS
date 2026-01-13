#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Documentation is available online
rm -rf /usr/share/doc

# Starship Shell Prompt
ghcurl "https://github.com/starship/starship/releases/latest/download/starship-$(uname -m)-unknown-linux-gnu.tar.gz" --retry 3 -o /tmp/starship.tar.gz
ghcurl "https://github.com/starship/starship/releases/latest/download/starship-$(uname -m)-unknown-linux-gnu.tar.gz.sha256" --retry 3 -o /tmp/starship.tar.gz.sha256

echo "$(cat /tmp/starship.tar.gz.sha256) /tmp/starship.tar.gz" | sha256sum --check
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >>/etc/bashrc

# Nerdfont symbols
# to fix motd and prompt atleast temporarily
ghcurl "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.zip" --retry 3 -o /tmp/nerdfontsymbols.zip
unzip /tmp/nerdfontsymbols.zip -d /tmp
mkdir -p /usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly/
mv /tmp/SymbolsNerdFont*.ttf /usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly/

# Bash Prexec v0.6.0
ghcurl https://raw.githubusercontent.com/rcaloras/bash-preexec/b73ed5f7f953207b958f15b1773721dded697ac3/bash-preexec.sh --retry 3 -Lo /usr/share/bash-prexec

# Caps
setcap 'cap_net_raw+ep' /usr/libexec/ksysguard/ksgrd_network_helper

# ######
# BASE IMAGE CHANGES
# ######

# Ctrl+Alt+T shortcut for Konsole
sed -i 's@\[Desktop Action new-window\]@\[Desktop Action new-window\]\nX-KDE-Shortcuts=Ctrl+Alt+T@g' /usr/share/applications/org.kde.konsole.desktop
cp /usr/share/applications/org.kde.konsole.desktop /usr/share/kglobalaccel/

rm -f /etc/profile.d/gnome-ssh-askpass.{csh,sh} # This shouldn't be pulled in

# Make Samba usershares work OOTB
mkdir -p /var/lib/samba/usershares
chown -R root:usershares /var/lib/samba/usershares
firewall-offline-cmd --service=samba --service=samba-client
setsebool -P samba_enable_home_dirs=1
setsebool -P samba_export_all_ro=1
setsebool -P samba_export_all_rw=1
sed -i '/^\[homes\]/,/^\[/{/^\[homes\]/d;/^\[/!d}' /etc/samba/smb.conf

echo "::endgroup::"
