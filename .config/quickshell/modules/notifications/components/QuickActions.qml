import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../../../components/ui" as UI

GridLayout {
    id: quickActionsRoot
    Layout.fillWidth: true
    columns: 2
    rowSpacing: 8
    columnSpacing: 8

    property var theme
    property bool wifiEnabled: true
    property bool bluetoothEnabled: true
    property bool isMuted: false
    property bool isMicMuted: false
    property bool micExpanded: false

    property var wifiToggleProc
    property var muteToggleProc

    signal toggleMicExpanded()

    // 1. Wi-Fi Module Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: 14
        color: wifiMouse.containsMouse
            ? (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("surfaceVariant"), 0.85) : "#3a3030")
            : (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("surfaceVariant"), 0.50) : "#2d2424")
        border.width: 1
        border.color: quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("outlineVariant"), 0.3) : "#453838"

        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            // Circular Toggle Icon
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: quickActionsRoot.wifiEnabled
                    ? (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("primary") : "#ffb3b4")
                    : (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("outlineVariant"), 0.4) : "#403535")

                Behavior on color { ColorAnimation { duration: 160 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 18
                    icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getWifiIcon(100, quickActionsRoot.wifiEnabled, quickActionsRoot.wifiEnabled)
                    color: quickActionsRoot.wifiEnabled
                        ? (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("onPrimary") : "#000000")
                        : (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                UI.Typography {
                    theme: quickActionsRoot.theme
                    text: "Wi-Fi"
                    variant: "labelMedium"
                    font.bold: true
                    colorRole: "onSurface"
                    elide: Text.ElideRight
                }

                UI.Typography {
                    theme: quickActionsRoot.theme
                    text: quickActionsRoot.wifiEnabled ? "Connected" : "Off"
                    variant: "bodySmall"
                    font.pixelSize: 11
                    colorRole: "onSurfaceVariant"
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: wifiMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                quickActionsRoot.wifiEnabled = !quickActionsRoot.wifiEnabled;
                if (quickActionsRoot.wifiToggleProc) {
                    quickActionsRoot.wifiToggleProc.command = ["nmcli", "radio", "wifi", quickActionsRoot.wifiEnabled ? "on" : "off"];
                    quickActionsRoot.wifiToggleProc.running = false;
                    quickActionsRoot.wifiToggleProc.running = true;
                }
            }
        }
    }

    // 2. Do Not Disturb (Focus) Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: 14
        readonly property bool isDnd: (typeof root !== "undefined" && root.dndEnabled)
        color: dndMouse.containsMouse
            ? (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("surfaceVariant"), 0.85) : "#3a3030")
            : (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("surfaceVariant"), 0.50) : "#2d2424")
        border.width: 1
        border.color: quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("outlineVariant"), 0.3) : "#453838"

        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: parent.parent.isDnd
                    ? (quickActionsRoot.theme ? (quickActionsRoot.theme.getColor("tertiary") || "#ffb875") : "#ffb875")
                    : (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("outlineVariant"), 0.4) : "#403535")

                Behavior on color { ColorAnimation { duration: 160 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 18
                    icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getNotificationIcon(parent.parent.isDnd, false)
                    color: parent.parent.isDnd
                        ? "#000000"
                        : (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                UI.Typography {
                    theme: quickActionsRoot.theme
                    text: "Focus"
                    variant: "labelMedium"
                    font.bold: true
                    colorRole: "onSurface"
                    elide: Text.ElideRight
                }

                UI.Typography {
                    theme: quickActionsRoot.theme
                    text: parent.parent.isDnd ? "Do Not Disturb" : "Off"
                    variant: "bodySmall"
                    font.pixelSize: 11
                    colorRole: "onSurfaceVariant"
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: dndMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (typeof root !== "undefined") {
                    root.dndEnabled = !root.dndEnabled;
                }
            }
        }
    }

    // 3. Sound / Output Mute Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: 14
        color: muteMouse.containsMouse
            ? (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("surfaceVariant"), 0.85) : "#3a3030")
            : (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("surfaceVariant"), 0.50) : "#2d2424")
        border.width: 1
        border.color: quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("outlineVariant"), 0.3) : "#453838"

        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: !quickActionsRoot.isMuted
                    ? (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("primary") : "#ffb3b4")
                    : (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("outlineVariant"), 0.4) : "#403535")

                Behavior on color { ColorAnimation { duration: 160 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 18
                    icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getSpeakerIcon(quickActionsRoot.isMuted)
                    color: !quickActionsRoot.isMuted
                        ? (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("onPrimary") : "#000000")
                        : (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                UI.Typography {
                    theme: quickActionsRoot.theme
                    text: "Sound"
                    variant: "labelMedium"
                    font.bold: true
                    colorRole: "onSurface"
                    elide: Text.ElideRight
                }

                UI.Typography {
                    theme: quickActionsRoot.theme
                    text: quickActionsRoot.isMuted ? "Muted" : "Active"
                    variant: "bodySmall"
                    font.pixelSize: 11
                    colorRole: "onSurfaceVariant"
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: muteMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (quickActionsRoot.muteToggleProc && typeof quickActionsRoot.muteToggleProc.toggleMute === "function") {
                    quickActionsRoot.muteToggleProc.toggleMute();
                } else {
                    quickActionsRoot.isMuted = !quickActionsRoot.isMuted;
                }
            }
        }
    }

    // 4. Microphone Input Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: 14
        color: micMouse.containsMouse
            ? (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("surfaceVariant"), 0.85) : "#3a3030")
            : (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("surfaceVariant"), 0.50) : "#2d2424")
        border.width: 1
        border.color: quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("outlineVariant"), 0.3) : "#453838"

        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: !quickActionsRoot.isMicMuted
                    ? (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("primary") : "#ffb3b4")
                    : (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("outlineVariant"), 0.4) : "#403535")

                Behavior on color { ColorAnimation { duration: 160 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 18
                    icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getMicIcon(quickActionsRoot.isMicMuted)
                    color: !quickActionsRoot.isMicMuted
                        ? (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("onPrimary") : "#000000")
                        : (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                UI.Typography {
                    theme: quickActionsRoot.theme
                    text: "Microphone"
                    variant: "labelMedium"
                    font.bold: true
                    colorRole: "onSurface"
                    elide: Text.ElideRight
                }

                UI.Typography {
                    theme: quickActionsRoot.theme
                    text: quickActionsRoot.isMicMuted ? "Muted" : "Active"
                    variant: "bodySmall"
                    font.pixelSize: 11
                    colorRole: "onSurfaceVariant"
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: micMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                quickActionsRoot.toggleMicExpanded();
            }
        }
    }
}
