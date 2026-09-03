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
    popupWidth: 540
    popupHeight: 630
    showCorners: true
    flatBottom: false
    contentRectX: Math.round((safeWidth - popupWidth) / 2)
    readonly property var activeNotifs: (typeof root !== "undefined" && root.activeNotifs) ? root.activeNotifs : ((typeof popupManager !== "undefined" && popupManager.activeNotifs) ? popupManager.activeNotifs : [])
    property int notifCount: activeNotifs.length
    property int volumeValue: 50
    property int micValue: 50
    property int brightnessValue: 50
    property int nightLightValue: 50
    property bool powerProfileExpanded: false
    property bool micExpanded: false
    property bool nightLightExpanded: false
    property bool nightLightEnabled: false
    property string currentProfile: "performance"
    property string uptimeStr: "Up 0m"
    property bool isMuted: false
    property int lastUnmutedVolume: 50
    property bool isMicMuted: false
    property bool wifiEnabled: true

    Process {
        id: muteToggleProc
        function toggleMute() {
            if (!notifWindow.isMuted) {
                if (notifWindow.volumeValue > 0) {
                    notifWindow.lastUnmutedVolume = notifWindow.volumeValue;
                }
                notifWindow.isMuted = true;
                notifWindow.volumeValue = 0;
                command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "1"];
            } else {
                notifWindow.isMuted = false;
                var targetVol = notifWindow.lastUnmutedVolume > 0 ? notifWindow.lastUnmutedVolume : 50;
                notifWindow.volumeValue = targetVol;
                command = ["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ " + (targetVol / 100).toFixed(2)];
            }
            running = false;
            Qt.callLater(() => running = true);
        }
    }

    Process {
        id: micMuteToggleProc
        function toggleMute() {
            notifWindow.isMicMuted = !notifWindow.isMicMuted;
            command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", notifWindow.isMicMuted ? "1" : "0"];
            running = false;
            Qt.callLater(() => running = true);
        }
    }

    function getNightLightScript() {
        if (typeof shellConfig !== "undefined" && shellConfig && typeof shellConfig.getScript === "function") {
            return shellConfig.getScript("nightlight.sh");
        }
        if (typeof root !== "undefined" && root.shellConfig && typeof root.shellConfig.getScript === "function") {
            return root.shellConfig.getScript("nightlight.sh");
        }
        return Quickshell.env("HOME") + "/.config/qs/scripts/nightlight.sh";
    }

    Process {
        id: nightLightToggleProc
        function toggleNightLight() {
            notifWindow.nightLightEnabled = !notifWindow.nightLightEnabled;
            var script = notifWindow.getNightLightScript();
            if (notifWindow.nightLightEnabled) {
                command = [script, "on", notifWindow.nightLightValue.toString()];
            } else {
                command = [script, "off"];
            }
            running = false;
            Qt.callLater(() => running = true);
        }
    }

    Process {
        id: nightLightSetter
        function setNightLight(val) {
            var script = notifWindow.getNightLightScript();
            command = [script, "set", val.toString()];
            running = false;
            Qt.callLater(() => running = true);
        }
    }

    Process { id: setProfileProc }
    NotifStatsFetcher {
        id: statsService
        notifWindow: notifWindow
    }
    onActiveChanged: {
        if (active) {
            statsService.fetch();
        } else {
            notifWindow.powerProfileExpanded = false;
        }
    }
    Process {
        id: volumeSetter
        function setVolume(val) {
            if (val > 0) {
                notifWindow.lastUnmutedVolume = val;
                notifWindow.isMuted = false;
                command = ["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ " + (val / 100).toFixed(2)];
            } else {
                notifWindow.isMuted = true;
                command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "1"];
            }
            running = false;
            Qt.callLater(() => running = true);
        }
    }
    Process {
        id: micSetter
        function setMic(val) {
            command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (val / 100).toFixed(2)];
            running = false;
            Qt.callLater(() => running = true);
        }
    }
    Process {
        id: brightnessSetter
        function setBrightness(val) {
            command = ["brightnessctl", "set", val + "%"];
            running = false;
            Qt.callLater(() => running = true);
        }
    }

    // 1. Top Uptime & Quick Tools Header
    PanelHeader {
        theme: notifWindow.theme
        uptimeStr: notifWindow.uptimeStr
        currentProfile: notifWindow.currentProfile
        powerProfileExpanded: notifWindow.powerProfileExpanded
        onTogglePowerProfile: {
            notifWindow.powerProfileExpanded = !notifWindow.powerProfileExpanded;
        }
        onCloseRequested: notifWindow.active = false
    }

    // 2. Power Profile Collapsible Selector
    PowerProfileMenu {
        theme: notifWindow.theme
        expanded: notifWindow.powerProfileExpanded
        currentProfile: notifWindow.currentProfile
        setProfileProc: setProfileProc
        onProfileSelected: profileId => notifWindow.currentProfile = profileId
    }

    // 3. macOS Style 2x2 Quick Actions Control Grid
    QuickActions {
        theme: notifWindow.theme
        isMuted: notifWindow.isMuted
        isMicMuted: notifWindow.isMicMuted
        micExpanded: notifWindow.micExpanded
        nightLightEnabled: notifWindow.nightLightEnabled
        nightLightValue: notifWindow.nightLightValue
        nightLightExpanded: notifWindow.nightLightExpanded
        muteToggleProc: muteToggleProc
        micMuteToggleProc: micMuteToggleProc
        nightLightToggleProc: nightLightToggleProc
        onIsMutedChanged: notifWindow.isMuted = isMuted
        onIsMicMutedChanged: notifWindow.isMicMuted = isMicMuted
        onNightLightEnabledChanged: notifWindow.nightLightEnabled = nightLightEnabled
        onToggleMicExpanded: notifWindow.micExpanded = !notifWindow.micExpanded
        onToggleNightLightExpanded: notifWindow.nightLightExpanded = !notifWindow.nightLightExpanded
    }

    // 4. Collapsible Night Light Slider
    UI.Slider {
        id: bottomNightLightSlider
        Layout.fillWidth: true
        Layout.preferredHeight: notifWindow.nightLightExpanded ? 32 : 0
        implicitHeight: notifWindow.nightLightExpanded ? 32 : 0
        visible: notifWindow.nightLightExpanded || opacity > 0.0
        opacity: notifWindow.nightLightExpanded ? 1.0 : 0.0
        clip: !notifWindow.nightLightExpanded || opacity < 0.99
        theme: notifWindow.theme
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/moon.svg")
        value: notifWindow.nightLightValue
        onMoved: val => {
            notifWindow.nightLightValue = val;
            if (!notifWindow.nightLightEnabled) {
                notifWindow.nightLightEnabled = true;
            }
            if (nightLightSetter) nightLightSetter.setNightLight(val);
        }
        Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    // 5. Collapsible Mic Slider
    UI.Slider {
        id: bottomMicSlider
        Layout.fillWidth: true
        Layout.preferredHeight: notifWindow.micExpanded ? 32 : 0
        implicitHeight: notifWindow.micExpanded ? 32 : 0
        visible: notifWindow.micExpanded || opacity > 0.0
        opacity: notifWindow.micExpanded ? 1.0 : 0.0
        clip: !notifWindow.micExpanded || opacity < 0.99
        theme: notifWindow.theme
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getMicIcon(notifWindow.micValue === 0)
        value: notifWindow.micValue
        onMoved: val => {
            notifWindow.micValue = val;
            if (micSetter) micSetter.setMic(val);
        }
        Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    // 6. macOS Style Display & Sound Sliders
    QuickSliders {
        theme: notifWindow.theme
        volumeValue: notifWindow.volumeValue
        brightnessValue: notifWindow.brightnessValue
        volumeSetter: volumeSetter
        brightnessSetter: brightnessSetter
        onVolumeMoved: val => notifWindow.volumeValue = val
        onBrightnessMoved: val => notifWindow.brightnessValue = val
    }

    // 7. Subtle Divider
    UI.Divider {
        theme: notifWindow.theme
        horizontal: true
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 2
    }

    // 8. macOS Style Notifications Section
    NotifSection {
        theme: notifWindow.theme
    }
}
