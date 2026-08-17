import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UIButtons

RowLayout {
    id: quickActionsRoot
    Layout.fillWidth: true
    spacing: 8

    property var theme
    property bool wifiEnabled: true
    property bool bluetoothEnabled: true
    property bool isMuted: false
    property bool isMicMuted: false

    property var wifiToggleProc
    property var bluetoothToggleProc
    property var muteToggleProc
    property var micToggleProc

    UIButtons.Button {
        Layout.fillWidth: true
        height: 44
        theme: quickActionsRoot.theme
        iconSize: 20
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getWifiIcon(100, quickActionsRoot.wifiEnabled, quickActionsRoot.wifiEnabled)
        active: quickActionsRoot.wifiEnabled
        onClicked: {
            quickActionsRoot.wifiEnabled = !quickActionsRoot.wifiEnabled;
            if (quickActionsRoot.wifiToggleProc) {
                quickActionsRoot.wifiToggleProc.command = ["nmcli", "radio", "wifi", quickActionsRoot.wifiEnabled ? "on" : "off"];
                quickActionsRoot.wifiToggleProc.running = false;
                quickActionsRoot.wifiToggleProc.running = true;
            }
        }
    }

    UIButtons.Button {
        Layout.fillWidth: true
        height: 44
        theme: quickActionsRoot.theme
        iconSize: 20
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getBluetoothIcon(quickActionsRoot.bluetoothEnabled)
        active: quickActionsRoot.bluetoothEnabled
        onClicked: {
            quickActionsRoot.bluetoothEnabled = !quickActionsRoot.bluetoothEnabled;
            if (quickActionsRoot.bluetoothToggleProc) {
                quickActionsRoot.bluetoothToggleProc.command = ["sh", "-c", quickActionsRoot.bluetoothEnabled ? "rfkill unblock bluetooth && (bluetoothctl power on 2>/dev/null || true)" : "rfkill block bluetooth"];
                quickActionsRoot.bluetoothToggleProc.running = false;
                quickActionsRoot.bluetoothToggleProc.running = true;
            }
        }
    }

    UIButtons.Button {
        Layout.fillWidth: true
        height: 44
        theme: quickActionsRoot.theme
        iconSize: 20
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getSpeakerIcon(quickActionsRoot.isMuted)
        active: !quickActionsRoot.isMuted
        onClicked: {
            quickActionsRoot.isMuted = !quickActionsRoot.isMuted;
            if (quickActionsRoot.muteToggleProc) {
                quickActionsRoot.muteToggleProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
                quickActionsRoot.muteToggleProc.running = false;
                quickActionsRoot.muteToggleProc.running = true;
            }
        }
    }

    UIButtons.Button {
        Layout.fillWidth: true
        height: 44
        theme: quickActionsRoot.theme
        iconSize: 20
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getMicIcon(quickActionsRoot.isMicMuted)
        active: !quickActionsRoot.isMicMuted
        onClicked: {
            quickActionsRoot.isMicMuted = !quickActionsRoot.isMicMuted;
            if (quickActionsRoot.micToggleProc) {
                quickActionsRoot.micToggleProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"];
                quickActionsRoot.micToggleProc.running = false;
                quickActionsRoot.micToggleProc.running = true;
            }
        }
    }
}
