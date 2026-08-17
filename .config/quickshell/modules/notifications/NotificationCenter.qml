import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../components/containers"
import "../../components/ui" as UI
import "./components"

Popup {
    id: notifWindow

    popupWidth: 480
    popupHeight: notifWindow.height > 0 ? (notifWindow.height + topOverlap) : 1080
    flatBottom: true
    slideFromRight: true

    property var activeNotifs: (typeof root !== "undefined" && root.activeNotifs) ? root.activeNotifs : []
    property int notifCount: activeNotifs.length

    property int volumeValue: 50
    property int brightnessValue: 50
    property bool powerMenuExpanded: false
    property bool powerProfileExpanded: false

    property string currentProfile: "performance"
    property string uptimeStr: "Up 0m"
    property bool wifiEnabled: true
    property bool bluetoothEnabled: true
    property bool isMuted: false
    property bool isMicMuted: false

    Process { id: wifiToggleProc }
    Process { id: bluetoothToggleProc }
    Process { id: muteToggleProc }
    Process { id: micToggleProc }
    Process { id: setProfileProc }
    Process {
        id: hyprpickerProc
        command: ["hyprpicker", "-a"]
    }
    Process {
        id: screenshotProc
        command: ["hyprshot", "-m", "region", "-o", shellConfig.homeDir + "/Pictures/Screenshots"]
    }

    onActiveChanged: {
        if (active) {
            statsFetcher.running = false;
            statsFetcher.running = true;
        } else {
            notifWindow.powerMenuExpanded = false;
            notifWindow.powerProfileExpanded = false;
        }
    }

    Timer {
        id: refreshTimer
        interval: 2000
        running: notifWindow.active
        repeat: true
        onTriggered: {
            statsFetcher.running = false;
            statsFetcher.running = true;
        }
    }

    Process {
        id: statsFetcher
        command: ["sh", "-c", "echo \"VOL: $(wpctl get-volume @DEFAULT_AUDIO_SINK@)\"; echo \"MIC: $(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)\"; echo \"BRI: $(brightnessctl -m)\"; echo \"WIFI: $(nmcli radio wifi 2>/dev/null)\"; echo \"BT: $(rfkill list bluetooth | grep 'Soft blocked')\"; echo \"PPD: $(powerprofilesctl get 2>/dev/null)\"; echo \"UP: $(uptime -p 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split('\n');
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.indexOf("VOL:") === 0) {
                        var vStr = line.substring(4).trim();
                        var match = vStr.match(/Volume:\s+([0-9.]+)/);
                        if (match) {
                            notifWindow.volumeValue = Math.round(parseFloat(match[1]) * 100);
                        }
                        notifWindow.isMuted = vStr.indexOf("[MUTED]") !== -1;
                    } else if (line.indexOf("MIC:") === 0) {
                        var mStr = line.substring(4).trim();
                        notifWindow.isMicMuted = mStr.indexOf("[MUTED]") !== -1;
                    } else if (line.indexOf("BRI:") === 0) {
                        var bStr = line.substring(4).trim();
                        var parts = bStr.split(',');
                        if (parts.length >= 4) {
                            var percentStr = parts[3].replace('%', '');
                            var val = parseInt(percentStr);
                            if (!isNaN(val)) {
                                notifWindow.brightnessValue = val;
                            }
                        }
                    } else if (line.indexOf("WIFI:") === 0) {
                        var wStr = line.substring(5).trim();
                        notifWindow.wifiEnabled = (wStr.indexOf("enabled") !== -1);
                    } else if (line.indexOf("BT:") === 0) {
                        var btStr = line.substring(3).trim();
                        notifWindow.bluetoothEnabled = (btStr.indexOf("no") !== -1);
                    } else if (line.indexOf("PPD:") === 0) {
                        var ppd = line.substring(4).trim();
                        if (ppd !== "") {
                            notifWindow.currentProfile = ppd;
                        }
                    } else if (line.indexOf("UP:") === 0) {
                        var up = line.substring(3).trim();
                        if (up !== "") {
                            var str = up.replace(/^up\s+/i, "").trim();
                            str = str.replace(/,\s*/g, " ");
                            str = str.replace(/\bhours?\b/gi, "h");
                            str = str.replace(/\bminutes?\b/gi, "m");
                            str = str.replace(/\bdays?\b/gi, "d");
                            str = str.replace(/(\d+)\s+([hmd])/gi, "$1$2");
                            notifWindow.uptimeStr = "Up " + str.trim();
                        }
                    }
                }
            }
        }
    }

    Process {
        id: volumeSetter
        function startProc() {
            volumeSetter.running = true;
        }
        function setVolume(val) {
            command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (val / 100).toFixed(2)];
            running = false;
            Qt.callLater(startProc);
        }
    }

    Process {
        id: brightnessSetter
        function startProc() {
            brightnessSetter.running = true;
        }
        function setBrightness(val) {
            command = ["brightnessctl", "set", val + "%"];
            running = false;
            Qt.callLater(startProc);
        }
    }

    PanelHeader {
        theme: notifWindow.theme
        uptimeStr: notifWindow.uptimeStr
        currentProfile: notifWindow.currentProfile
        powerProfileExpanded: notifWindow.powerProfileExpanded
        powerMenuExpanded: notifWindow.powerMenuExpanded
        hyprpickerProc: hyprpickerProc
        screenshotProc: screenshotProc
        onTogglePowerProfile: {
            notifWindow.powerProfileExpanded = !notifWindow.powerProfileExpanded;
            if (notifWindow.powerProfileExpanded) notifWindow.powerMenuExpanded = false;
        }
        onTogglePowerMenu: {
            notifWindow.powerMenuExpanded = !notifWindow.powerMenuExpanded;
            if (notifWindow.powerMenuExpanded) notifWindow.powerProfileExpanded = false;
        }
        onCloseRequested: notifWindow.active = false
    }

    PowerProfileMenu {
        theme: notifWindow.theme
        expanded: notifWindow.powerProfileExpanded
        currentProfile: notifWindow.currentProfile
        setProfileProc: setProfileProc
        onProfileSelected: profileId => {
            notifWindow.currentProfile = profileId;
        }
    }

    PowerMenu {
        theme: notifWindow.theme
        expanded: notifWindow.powerMenuExpanded
        onClosed: notifWindow.active = false
    }

    QuickSliders {
        theme: notifWindow.theme
        volumeValue: notifWindow.volumeValue
        brightnessValue: notifWindow.brightnessValue
        volumeSetter: volumeSetter
        brightnessSetter: brightnessSetter
        onVolumeValueChanged: notifWindow.volumeValue = volumeValue
        onBrightnessValueChanged: notifWindow.brightnessValue = brightnessValue
    }

    UI.Divider {
        theme: notifWindow.theme
        horizontal: true
        Layout.fillWidth: true
        Layout.topMargin: 2
        Layout.bottomMargin: 2
    }

    NotifSection {
        theme: notifWindow.theme
        activeNotifs: notifWindow.activeNotifs
    }

    UI.Divider {
        theme: notifWindow.theme
        horizontal: true
        Layout.fillWidth: true
        Layout.topMargin: 2
        Layout.bottomMargin: 2
    }

    QuickActions {
        theme: notifWindow.theme
        wifiEnabled: notifWindow.wifiEnabled
        bluetoothEnabled: notifWindow.bluetoothEnabled
        isMuted: notifWindow.isMuted
        isMicMuted: notifWindow.isMicMuted
        wifiToggleProc: wifiToggleProc
        bluetoothToggleProc: bluetoothToggleProc
        muteToggleProc: muteToggleProc
        micToggleProc: micToggleProc
        onWifiEnabledChanged: notifWindow.wifiEnabled = wifiEnabled
        onBluetoothEnabledChanged: notifWindow.bluetoothEnabled = bluetoothEnabled
        onIsMutedChanged: notifWindow.isMuted = isMuted
        onIsMicMutedChanged: notifWindow.isMicMuted = isMicMuted
    }
}
