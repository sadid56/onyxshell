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
    property bool powerProfileExpanded: false
    property bool micExpanded: false
    property string currentProfile: "performance"
    property string uptimeStr: "Up 0m"
    property bool wifiEnabled: true
    property bool isMuted: false
    property int lastUnmutedVolume: 50
    property bool isMicMuted: false
    Process { id: wifiToggleProc }
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
        wifiEnabled: notifWindow.wifiEnabled
        isMuted: notifWindow.isMuted
        isMicMuted: notifWindow.isMicMuted
        micExpanded: notifWindow.micExpanded
        wifiToggleProc: wifiToggleProc
        muteToggleProc: muteToggleProc
        onWifiEnabledChanged: notifWindow.wifiEnabled = wifiEnabled
        onIsMutedChanged: notifWindow.isMuted = isMuted
        onToggleMicExpanded: notifWindow.micExpanded = !notifWindow.micExpanded
    }

    // 4. Collapsible Mic Slider
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

    // 5. macOS Style Display & Sound Sliders
    QuickSliders {
        theme: notifWindow.theme
        volumeValue: notifWindow.volumeValue
        brightnessValue: notifWindow.brightnessValue
        volumeSetter: volumeSetter
        brightnessSetter: brightnessSetter
        onVolumeMoved: val => notifWindow.volumeValue = val
        onBrightnessMoved: val => notifWindow.brightnessValue = val
    }

    // 6. Subtle Divider
    UI.Divider {
        theme: notifWindow.theme
        horizontal: true
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 2
    }

    // 7. macOS Style Notifications Section
    NotifSection {
        theme: notifWindow.theme
    }
}
