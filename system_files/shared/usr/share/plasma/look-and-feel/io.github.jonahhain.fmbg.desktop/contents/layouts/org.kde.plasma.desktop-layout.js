loadTemplate("org.kde.plasma.desktop.defaultPanel")

const allPanels = panels();

for (let i = 0; i < allPanels.length; ++i) {
    const panel = allPanels[i];
    const widgets = panel.widgets();

    for (let j = 0; j < widgets.length; ++j) {
        const widget = widgets[j];

        if (widget.type === "org.kde.plasma.icontasks") {
            widget.currentConfigGroup = ["General"];

            widget.writeConfig("launchers", [
                "applications:org.kde.konsole.desktop",
                "preferred://filemanager",
                "preferred://browser"
            ]);
            widget.reloadConfig();
        }
    }
}
