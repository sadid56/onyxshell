import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: config

    readonly property string homeDir: Quickshell.env("HOME") || "/home"
    readonly property string quickshellDir: homeDir + "/.config/quickshell"
    readonly property string assetsDir: quickshellDir + "/assets"
    readonly property string scriptsDir: quickshellDir + "/scripts"

    readonly property string iconsDir: assetsDir + "/icons"
    readonly property string distrosDir: assetsDir + "/distros"
    readonly property string defaultWallpaper: assetsDir + "/images/default-wallpaper.png"

    readonly property string defaultAppIcon: iconsDir + "/system/default-app.svg"

    readonly property int cornerRadius: parseInt(Quickshell.env("ROUNDED")) || 16

    property string currentDistro: "linux"

    property var distroDetectProc: Process {
        command: ["sh", "-c", "source /etc/os-release 2>/dev/null && echo $ID"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var d = data.trim().toLowerCase();
                if (d !== "") {
                    config.currentDistro = d;
                }
            }
        }
    }

    function getScript(scriptName) {
        return scriptsDir + "/" + scriptName;
    }

    function getIcon(iconPath) {
        if (!iconPath) return "";
        return "file://" + iconsDir + "/" + iconPath;
    }

    function getDistroIcon(distroId) {
        var id = (distroId || currentDistro || "arch").toLowerCase();
        return "file://" + distrosDir + "/" + id + ".svg";
    }

    function getBatteryIcon(percentage, isCharging) {
        if (isCharging) return getIcon("battery/battery-charge.svg");
        if (percentage >= 95) return getIcon("battery/battery-full.svg");
        if (percentage >= 85) return getIcon("battery/battery-9.svg");
        if (percentage >= 75) return getIcon("battery/battery-8.svg");
        if (percentage >= 65) return getIcon("battery/battery-7.svg");
        if (percentage >= 55) return getIcon("battery/battery-6.svg");
        if (percentage >= 45) return getIcon("battery/battery-5.svg");
        if (percentage >= 35) return getIcon("battery/battery-4.svg");
        if (percentage >= 25) return getIcon("battery/battery-3.svg");
        if (percentage >= 15) return getIcon("battery/battery-2.svg");
        if (percentage >= 8)  return getIcon("battery/battery-1.svg");
        return getIcon("battery/battery-0.svg");
    }

    function getWifiIcon(signal, isConnected, isEnabled) {
        if (isEnabled === false) return getIcon("wifi/wifi-off.svg");
        if (isConnected === false || signal < 0) return getIcon("wifi/wifi-warning.svg");
        if (signal >= 75) return getIcon("wifi/wifi-1.svg");
        if (signal >= 50) return getIcon("wifi/wifi-2.svg");
        if (signal >= 25) return getIcon("wifi/wifi-3.svg");
        return getIcon("wifi/wifi-4.svg");
    }

    function getNotificationIcon(isDnd, hasNotifs) {
        if (isDnd) return getIcon("notifications/bell-off.svg");
        if (hasNotifs) return getIcon("notifications/bell-dot.svg");
        return getIcon("notifications/bell.svg");
    }

    function getCpuIcon() {
        return getIcon("system/cpu.svg");
    }

    function getMemoryIcon() {
        return getIcon("system/memory.svg");
    }

    function getSwapIcon() {
        return getIcon("system/swap.svg");
    }

    function getBluetoothIcon(enabled) {
        if (!enabled) return getIcon("bluetooth/bluetooth-disabled.svg");
        return getIcon("bluetooth/bluetooth.svg");
    }

    function getSpeakerIcon(isMuted) {
        if (isMuted) return getIcon("audio/speaker-off.svg");
        return getIcon("audio/speaker.svg");
    }

    function getMicIcon(isMuted) {
        if (isMuted) return getIcon("audio/mic-off.svg");
        return getIcon("audio/mic.svg");
    }
}
