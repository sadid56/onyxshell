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

    property bool bluetoothExpanded: false
    property bool micExpanded: false

    property var wifiToggleProc
    property var muteToggleProc

    signal toggleBluetoothExpanded()
    signal toggleMicExpanded()

    UIButtons.Button {
        Layout.fillWidth: true
        height: 44
        theme: quickActionsRoot.theme
        iconSize: 20
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getWifiIcon(100, quickActionsRoot.wifiEnabled, quickActionsRoot.wifiEnabled)
        active: true
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
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getNotificationIcon(
            (typeof root !== "undefined" && root.dndEnabled),
            false
        )
        active: true
        onClicked: {
            if (typeof root !== "undefined") {
                root.dndEnabled = !root.dndEnabled;
            }
        }
    }

    UIButtons.Button {
        Layout.fillWidth: true
        height: 44
        theme: quickActionsRoot.theme
        iconSize: 20
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getSpeakerIcon(quickActionsRoot.isMuted)
        active: true
        onClicked: {
            if (quickActionsRoot.muteToggleProc && typeof quickActionsRoot.muteToggleProc.toggleMute === "function") {
                quickActionsRoot.muteToggleProc.toggleMute();
            } else {
                quickActionsRoot.isMuted = !quickActionsRoot.isMuted;
            }
        }
    }

    UIButtons.Button {
        Layout.fillWidth: true
        height: 44
        theme: quickActionsRoot.theme
        iconSize: 20
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getMicIcon(quickActionsRoot.isMicMuted)
        active: true
        onClicked: {
            quickActionsRoot.toggleMicExpanded();
        }
    }
}
