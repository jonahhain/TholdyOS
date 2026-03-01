# TholdyOS

TholdyOS ist ein maßgeschneidertes Linux-Betriebssystem für den Einsatz am FMBG. Es basiert auf [Fedora Linux](https://fedoraproject.org/) mit dem [KDE Plasma](https://kde.org/plasma-desktop/) Desktop.

Das Projekt basiert auf [Aurora](https://github.com/ublue-os/aurora), einem Community-Projekt, welches Teil von [Universal Blue](https://universal-blue.org/) ist.

Die Domänenanbindung zu Testzwecken wird durch die Schulserverlösung [Linuxmuster.net](https://linuxmuster.net/) ermöglicht.

## Anmerkungen
Dieses Projekt ist derzeit noch in Arbeit. Es wurde nur zu Testzwecken entwickelt, um die Machbarkeit zu demonstrieren und ist ausdrücklich nicht für den produktiven Einsatz gedacht.

Dieses Repository enthält keine fertige Software, sondern eine Sammlung von Skripten und Konfigurationsdateien, die zusammen ein installierbares Betriebssystem-Abbild (Image) erzeugen.

## Besonderheiten
TholdyOS wird als containerbasiertes System mittels [bootc](https://bootc-dev.github.io/) bereitgestellt, was es von konventionellen Linux-Distributionen unterscheidet. Änderungen am System können nur durch die Bearbeitung der Build-Skripte und anschließendes Neubauen des Images vorgenommen werden, da dieses in weiten Teilen schreibgeschützt ist. Anschließend werden die Client-Systeme automatisch im Hintergrund aktualisiert. Falls ein Update Probleme macht, kann man außerdem jederzeit zur vorherigen Version zurückkehren. Somit finden Selbstheilungssysteme nur in Notfällen eine Verwendung und es muss nicht jedes Mal vom Netzwerk gestartet werden.

## Überblick

### Zwei Varianten

TholdyOS wird in zwei Varianten gebaut:

| Variante | Beschreibung | Installationsmedium |
|---|---|---|
| **tholdyos** | Für normale Systeme (z.B. Laptops) | ISO-Datei mit Installer |
| **tholdyos-ad** | Für Rechner, die sich in ein Active-Directory-Netzwerk einbinden sollen (z. B. PCs in Computerräumen oder Smartboards) | Fertiges Datenträger-Abbild ohne Installer |

Zusätzlich gibt es die **Smartboard**-Variante von `tholdyos-ad` mit anderer vorinstallierter Software.

## Aufbau des Repositorys

```
TholdyOS/
├── Containerfile        # Bauanleitung für das Container-Image
├── Justfile             # Kern des Build-Systems
│
├── build_files/         # Build-Skripte
│   ├── base/            # Skripte für das Basis-Image (alle Varianten)
│   ├── ad/              # Zusätzliche Skripte für die AD-Variante
│   └── shared/          # Gemeinsame Hilfsskripte
│
├── system_files/        # Dateien, die in das fertige System kopiert werden
│   ├── shared/          # Gemeinsame Dateien
│   └── ad/              # AD-spezifische Dateien
│
├── flatpaks/            # Listen vorinstallierter Flatpak-Anwendungen
│
├── deployment/          # Dateien für die Erzeugung von Installationsmedien
│
├── logos/               # Logos und sonstiges Branding
│
└── .github/workflows/   # Workflows für GitHub Actions
```

## Lizenz

Siehe [LICENSE](LICENSE). Diese wurde von Aurora übernommen.
