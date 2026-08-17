import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UIButtons

RowLayout {
    id: quickActionsRoot
    Layout.fillWidth: true
    spacing: 10

    property var theme
    property bool wifiEnabled: true
    property bool isMuted: false
    property bool isMicMuted: false
    property var wifiToggleProc
    property var muteToggleProc
    property var micToggleProc
    property var screenshotProc
    property var hyprpickerProc

    signal closeRequested()

    UIButtons.Button {
        Layout.fillWidth: true
        height: 48
        theme: quickActionsRoot.theme
        icon: quickActionsRoot.wifiEnabled ? "󰤨" : "󰤮"
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
        height: 48
        theme: quickActionsRoot.theme
        icon: quickActionsRoot.isMicMuted ? "󰍭" : "󰍬"
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

    UIButtons.Button {
        Layout.fillWidth: true
        height: 48
        theme: quickActionsRoot.theme
        icon: quickActionsRoot.isMuted ? "󰖁" : "󰕾"
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
        height: 48
        theme: quickActionsRoot.theme
        icon: "󰹑"
        onClicked: {
            quickActionsRoot.closeRequested();
            if (quickActionsRoot.screenshotProc) {
                quickActionsRoot.screenshotProc.running = false;
                quickActionsRoot.screenshotProc.running = true;
            }
        }
    }

    UIButtons.Button {
        Layout.fillWidth: true
        height: 48
        theme: quickActionsRoot.theme
        icon: "󰈋"
        onClicked: {
            quickActionsRoot.closeRequested();
            if (quickActionsRoot.hyprpickerProc) {
                quickActionsRoot.hyprpickerProc.running = false;
                quickActionsRoot.hyprpickerProc.running = true;
            }
        }
    }
}
