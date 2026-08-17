import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../components/containers"
import "./components"
import "../controlcenter/widgets"

Popup {
    id: notifWindow

    popupWidth: 480
    popupHeight: notifWindow.height > 0 ? (notifWindow.height + topOverlap) : 1080
    topOverlap: 14
    flatBottom: true

    property var activeNotifs: []
    property int notifCount: activeNotifs.length

    property int volumeValue: 50
    property int brightnessValue: 50
    property string mediaStatus: "Stopped"
    property string mediaTitle: "No media playing"
    property string mediaArtist: ""
    property int mediaPosition: 0
    property int mediaLength: 0
    property bool powerMenuExpanded: false

    property bool wifiEnabled: true
    property bool isMuted: false
    property bool isMicMuted: false

    Process { id: wifiToggleProc }
    Process { id: muteToggleProc }
    Process { id: micToggleProc }
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
        }
    }

    Timer {
        id: refreshTimer
        interval: 1000
        running: notifWindow.active
        repeat: true
        onTriggered: {
            statsFetcher.running = false;
            statsFetcher.running = true;
        }
    }

    Process {
        id: statsFetcher
        command: ["sh", "-c", "echo \"VOL: $(wpctl get-volume @DEFAULT_AUDIO_SINK@)\"; echo \"MIC: $(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)\"; echo \"BRI: $(brightnessctl -m)\"; echo \"MED: $(playerctl metadata --format '{{status}}::{{title}}::{{artist}}::{{position}}::{{mpris:length}}' 2>/dev/null)\"; echo \"WIFI: $(nmcli radio wifi 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split('\n');
                var hasMedia = false;
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
                    } else if (line.indexOf("MED:") === 0) {
                        var medStr = line.substring(4).trim();
                        if (medStr !== "") {
                            var mParts = medStr.split('::');
                            notifWindow.mediaStatus = mParts[0] || "Unknown";
                            notifWindow.mediaTitle = mParts[1] || "No media playing";
                            notifWindow.mediaArtist = mParts[2] || "";
                            var posUs = parseInt(mParts[3]) || 0;
                            var lenUs = parseInt(mParts[4]) || 0;
                            notifWindow.mediaPosition = Math.round(posUs / 1000000);
                            notifWindow.mediaLength = Math.round(lenUs / 1000000);
                            hasMedia = true;
                        }
                    } else if (line.indexOf("WIFI:") === 0) {
                        var wStr = line.substring(5).trim();
                        notifWindow.wifiEnabled = (wStr.indexOf("enabled") !== -1);
                    }
                }
                if (!hasMedia) {
                    notifWindow.mediaStatus = "Stopped";
                    notifWindow.mediaTitle = "No media playing";
                    notifWindow.mediaArtist = "";
                    notifWindow.mediaPosition = 0;
                    notifWindow.mediaLength = 0;
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

    Process {
        id: mediaControl
        function runCmd(cmd) {
            command = ["playerctl", cmd];
            running = false;
            running = true;
            refreshTimer.restart();
        }
    }

    MediaControls {
        theme: notifWindow.theme
        mediaStatus: notifWindow.mediaStatus
        mediaTitle: notifWindow.mediaTitle
        mediaArtist: notifWindow.mediaArtist
        mediaPosition: notifWindow.mediaPosition
        mediaLength: notifWindow.mediaLength
        onControlAction: act => {
            mediaControl.runCmd(act);
        }
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

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: notifWindow.theme.getColor("surfaceVariant")
    }

    NotifSection {
        theme: notifWindow.theme
        activeNotifs: notifWindow.activeNotifs
    }

    QuickActions {
        theme: notifWindow.theme
        wifiEnabled: notifWindow.wifiEnabled
        isMuted: notifWindow.isMuted
        isMicMuted: notifWindow.isMicMuted
        wifiToggleProc: wifiToggleProc
        muteToggleProc: muteToggleProc
        micToggleProc: micToggleProc
        screenshotProc: screenshotProc
        hyprpickerProc: hyprpickerProc
        onWifiEnabledChanged: notifWindow.wifiEnabled = wifiEnabled
        onIsMutedChanged: notifWindow.isMuted = isMuted
        onIsMicMutedChanged: notifWindow.isMicMuted = isMicMuted
        onCloseRequested: notifWindow.active = false
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: notifWindow.theme.getColor("surfaceVariant")
    }

    PowerGrid {
        theme: notifWindow.theme
        expanded: notifWindow.powerMenuExpanded
        onClosed: {
            notifWindow.active = false;
        }
    }
}
