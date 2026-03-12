#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Footgun, See: https://github.com/ublue-os/main/issues/598
rm -f /usr/bin/chsh /usr/bin/lchsh

# Documentation is available online
rm -rf /usr/share/doc/

# ######
# BASE IMAGE CHANGES
# ######

# Link Desktop entries to /etc/skel/Desktop
mkdir -p /etc/skel/Desktop
ln -sf /var/lib/flatpak/exports/share/applications/org.mozilla.firefox.desktop /etc/skel/Desktop/org.mozilla.firefox.desktop
ln -sf /usr/share/applications/libreoffice-writer.desktop /etc/skel/Desktop/libreoffice-writer.desktop
ln -sf /usr/share/applications/libreoffice-impress.desktop /etc/skel/Desktop/libreoffice-impress.desktop
ln -sf /usr/share/applications/libreoffice-calc.desktop /etc/skel/Desktop/libreoffice-calc.desktop
ln -sf /usr/share/applications/blender.desktop /etc/skel/Desktop/blender.desktop
ln -sf /usr/share/applications/org.musescore.MuseScore.desktop /etc/skel/Desktop/org.musescore.MuseScore.desktop
ln -sf /var/lib/flatpak/exports/share/applications/cc.arduino.IDE2.desktop /etc/skel/Desktop/cc.arduino.IDE2.desktop
ln -sf /usr/share/applications/audacity.desktop /etc/skel/Desktop/audacity.desktop
ln -sf /var/lib/flatpak/exports/share/applications/org.bluej.BlueJ.desktop /etc/skel/Desktop/org.bluej.BlueJ.desktop
ln -sf /usr/share/applications/org.kde.okular.desktop /etc/skel/Desktop/org.kde.okular.desktop

# Logos
mkdir -p /usr/share/icons/hicolor/scalable/{apps,places}
mkdir -p /usr/share/pixmaps
cp /ctx/logos/distributor-logo.png /usr/share/icons/hicolor/scalable
cp /ctx/logos/distributor-logo.png /usr/share/pixmaps/system-logo.png
cp /ctx/logos/distributor-logo.png /usr/share/pixmaps/system-logo-white.png

# Banner, keep the Fedora stuff for compatibility
cp /ctx/logos/fmbg-banner.png /usr/share/pixmaps/
ln -sr /usr/share/pixmaps/fmbg-banner.png /usr/share/pixmaps/fedora-logo.png

# ln -sr /usr/share/pixmaps/fmbg-banner.png /usr/share/pixmaps/fedora_whitelogo.png
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo.png /usr/share/pixmaps/fedora-logo-sprite.png
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo.png /usr/share/icons/hicolor/scalable/places/distributor-logo.png

# the themes read from relative directories
mkdir -p /usr/share/plasma/look-and-feel/io.github.jonahhain.fmbg.desktop/contents/splash/images/
cp /usr/share/pixmaps/fmbg-banner.png /usr/share/plasma/look-and-feel/io.github.jonahhain.fmbg.desktop/contents/splash/images/

# plymouth logos
mkdir -p /usr/share/plymouth/themes/spinner/
cp /ctx/logos/fmbg-banner-plymouth.png /usr/share/plymouth/themes/spinner/watermark.png
cp /usr/share/plymouth/themes/spinner/watermark.png /usr/share/plymouth/themes/spinner/kinoite-watermark.png

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
setsebool -P use_samba_home_dirs=1
sed -i '/^\[homes\]/,/^\[/{/^\[homes\]/d;/^\[/!d}' /etc/samba/smb.conf

echo "::endgroup::"
