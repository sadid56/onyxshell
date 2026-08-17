import QtQuick
import Quickshell

QtObject {
    id: config

    readonly property string homeDir: Quickshell.env("HOME") || "/home"
    readonly property string quickshellDir: homeDir + "/.config/quickshell"
    readonly property string assetsDir: quickshellDir + "/assets"
    readonly property string scriptsDir: quickshellDir + "/scripts"

    readonly property string iconsDir: assetsDir + "/icons"
    readonly property string distrosDir: assetsDir + "/distros"
    readonly property string defaultWallpaper: assetsDir + "/images/default-wallpaper.png"

    readonly property string defaultAppIcon: iconsDir + "/default-app.svg"

    readonly property int cornerRadius: 16

    function getScript(scriptName) {
        return scriptsDir + "/" + scriptName;
    }

    function getIcon(iconName) {
        return "file://" + iconsDir + "/" + iconName;
    }

    function getDistroIcon(distroId) {
        return "file://" + distrosDir + "/" + distroId + ".svg";
    }
}
