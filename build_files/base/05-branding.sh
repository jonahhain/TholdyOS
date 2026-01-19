#!/bin/bash

echo "::group:: ===$(basename "$0")==="

# Branding for Images

# sets default/pinned applications on the taskmanager applet on the panel, there is no nice way to do this
# https://bugs.kde.org/show_bug.cgi?id=511560
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>applications:org.kde.konsole.desktop,preferred:\/\/filemanager,preferred:\/\/browser<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml

# Generate Logos from source SVGs
mkdir -p /usr/share/icons/hicolor/scalable/{apps,places}
mkdir -p /usr/share/pixmaps
cp /ctx/logos/distributor-logo.png /usr/share/icons/hicolor/scalable

cp /ctx/logos/fmbg-banner.png /usr/share/pixmaps/
ln -sr /usr/share/pixmaps/fmbg-banner.png /usr/share/pixmaps/fedora-logo.png

# Banner, keep the Fedora stuff for compatibility
cp /ctx/logos/fmbg-banner.png /usr/share/pixmaps/fedora-logo.png
# magick -background none /ctx/logos/fmbg-banner.png -quality 90 -resize $((400-10*2))x100 -gravity center -extent 400x100 /usr/share/pixmaps/fedora-logo.png
# magick -background none /ctx/logos/fmbg-banner.png -quality 90 -resize $((128-3*2))x32 -gravity center -extent 128x32 /usr/share/pixmaps/fedora-logo-small.png
# magick -background none /ctx/logos/fmbg-banner.png -quality 90 -resize $((200-5*2))x50 -gravity center -extent 200x100 /usr/share/pixmaps/fedora_logo_med.png

# "A" Logo
# magick -background none /ctx/logos/distributor-logo.png -quality 90 -resize 256x256! /usr/share/pixmaps/system-logo.png
# magick -background none /ctx/logos/distributor-logo.png -quality 90 -resize 128x128! /usr/share/pixmaps/fedora-logo-sprite.png
# magick -background none /ctx/logos/distributor-logo.png -quality 90 -resize 256x256! /usr/share/pixmaps/system-logo-white.png
cp /ctx/logos/distributor-logo.png /usr/share/pixmaps/system-logo.png
cp /ctx/logos/distributor-logo.png /usr/share/pixmaps/system-logo-white.png

# ln -sr /usr/share/pixmaps/fmbg-banner.png /usr/share/pixmaps/fedora_whitelogo.png
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo.png /usr/share/pixmaps/fedora-logo-sprite.png
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo.png /usr/share/icons/hicolor/scalable/places/distributor-logo.png

# the themes read from relative directories
mkdir -p /usr/share/plasma/look-and-feel/io.github.jonahhain.fmbg.desktop/contents/splash/images/
cp /usr/share/pixmaps/fmbg-banner.png /usr/share/plasma/look-and-feel/io.github.jonahhain.fmbg.desktop/contents/splash/images/

# ln -sr /usr/share/icons/hicolor/scalable/places/fmbg-banner.png /usr/share/sddm/themes/01-fmbg/default-logo.png

# generate plymouth logos
mkdir -p /usr/share/plymouth/themes/spinner/
# magick -background none /usr/share/pixmaps/aurora-banner.svg -quality 90 -resize $((128-3*2))x32 -gravity center -extent 128x32 /usr/share/plymouth/themes/spinner/watermark.png
cp /ctx/logos/fmbg-banner-plymouth.png /usr/share/plymouth/themes/spinner/watermark.png
cp /usr/share/plymouth/themes/spinner/watermark.png /usr/share/plymouth/themes/spinner/kinoite-watermark.png

echo "::endgroup::"
