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
    property bool isMuted: false
    property bool isMicMuted: false
    property bool micExpanded: false
    property bool nightLightEnabled: false
    property int nightLightValue: 50
    property bool nightLightExpanded: false

    property var muteToggleProc
    property var micMuteToggleProc
    property var nightLightToggleProc

    signal toggleMicExpanded()
    signal toggleMicMute()
    signal toggleNightLightExpanded()
    signal toggleNightLight()

    // 1. Sound / Output Mute Card (Top-Left)
    Rectangle {
        id: soundCard
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
                Layout.alignment: Qt.AlignVCenter
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
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                UI.Typography {
                    Layout.fillWidth: true
                    theme: quickActionsRoot.theme
                    text: "Sound"
                    variant: "labelMedium"
                    font.bold: true
                    colorRole: "onSurface"
                    elide: Text.ElideRight
                }

                UI.Typography {
                    Layout.fillWidth: true
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

    // 2. Do Not Disturb (Focus) Card (Top-Right)
    Rectangle {
        id: dndCard
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
                Layout.alignment: Qt.AlignVCenter
                radius: 18
                color: dndCard.isDnd
                    ? (quickActionsRoot.theme ? (quickActionsRoot.theme.getColor("tertiary") || "#ffb875") : "#ffb875")
                    : (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("outlineVariant"), 0.4) : "#403535")

                Behavior on color { ColorAnimation { duration: 160 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 18
                    icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getNotificationIcon(dndCard.isDnd, false)
                    color: dndCard.isDnd
                        ? "#000000"
                        : (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                UI.Typography {
                    Layout.fillWidth: true
                    theme: quickActionsRoot.theme
                    text: "Focus"
                    variant: "labelMedium"
                    font.bold: true
                    colorRole: "onSurface"
                    elide: Text.ElideRight
                }

                UI.Typography {
                    Layout.fillWidth: true
                    theme: quickActionsRoot.theme
                    text: dndCard.isDnd ? "Do Not Disturb" : "Off"
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

    // 3. Night Light Card (Bottom-Left)
    Rectangle {
        id: nightLightCard
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: 14
        color: nightLightMouse.containsMouse
            ? (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("surfaceVariant"), 0.85) : "#3a3030")
            : (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("surfaceVariant"), 0.50) : "#2d2424")
        border.width: 1
        border.color: quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("outlineVariant"), 0.3) : "#453838"

        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // Left Night Light Icon Circle
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignVCenter
                radius: 18
                color: quickActionsRoot.nightLightEnabled
                    ? (quickActionsRoot.theme ? (quickActionsRoot.theme.getColor("tertiary") || "#ffb875") : "#ffb875")
                    : (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("outlineVariant"), 0.4) : "#403535")

                Behavior on color { ColorAnimation { duration: 160 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 18
                    icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/moon.svg")
                    color: quickActionsRoot.nightLightEnabled
                        ? "#000000"
                        : (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
                }
            }

            // Title and Subtitle Text Column
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                UI.Typography {
                    Layout.fillWidth: true
                    theme: quickActionsRoot.theme
                    text: "Night Light"
                    variant: "labelMedium"
                    font.bold: true
                    colorRole: "onSurface"
                    elide: Text.ElideRight
                }

                UI.Typography {
                    Layout.fillWidth: true
                    theme: quickActionsRoot.theme
                    text: quickActionsRoot.nightLightEnabled ? "Active" : "Off"
                    variant: "bodySmall"
                    font.pixelSize: 11
                    colorRole: "onSurfaceVariant"
                    elide: Text.ElideRight
                }
            }

            // Right Arrow / Chevron Button to expand/collapse night light slider
            Rectangle {
                id: nightLightArrowBtn
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Layout.alignment: Qt.AlignVCenter
                radius: 13
                color: nightLightArrowMouse.containsMouse
                    ? (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("onSurface"), 0.14) : "rgba(255,255,255,0.14)")
                    : (quickActionsRoot.nightLightExpanded
                        ? (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("tertiary") || quickActionsRoot.theme.getColor("primary"), 0.15) : "rgba(255,255,255,0.1)")
                        : "transparent")

                Behavior on color { ColorAnimation { duration: 120 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 14
                    icon: "actions/chevron-right.svg"
                    rotation: quickActionsRoot.nightLightExpanded ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    color: quickActionsRoot.nightLightExpanded
                        ? (quickActionsRoot.theme ? (quickActionsRoot.theme.getColor("tertiary") || "#ffb875") : "#ffb875")
                        : (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
                }

                MouseArea {
                    id: nightLightArrowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        quickActionsRoot.toggleNightLightExpanded();
                    }
                }
            }
        }

        // Main Card MouseArea for toggle on/off
        MouseArea {
            id: nightLightMouse
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: 38
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (quickActionsRoot.nightLightToggleProc && typeof quickActionsRoot.nightLightToggleProc.toggleNightLight === "function") {
                    quickActionsRoot.nightLightToggleProc.toggleNightLight();
                } else {
                    quickActionsRoot.nightLightEnabled = !quickActionsRoot.nightLightEnabled;
                    quickActionsRoot.toggleNightLight();
                }
            }
        }
    }

    // 4. Microphone Input Card (Bottom-Right)
    Rectangle {
        id: micCard
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
            spacing: 8

            // Left Mic Icon Circle
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignVCenter
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

            // Title and Subtitle Text Column
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                UI.Typography {
                    Layout.fillWidth: true
                    theme: quickActionsRoot.theme
                    text: "Microphone"
                    variant: "labelMedium"
                    font.bold: true
                    colorRole: "onSurface"
                    elide: Text.ElideRight
                }

                UI.Typography {
                    Layout.fillWidth: true
                    theme: quickActionsRoot.theme
                    text: quickActionsRoot.isMicMuted ? "Muted" : "Active"
                    variant: "bodySmall"
                    font.pixelSize: 11
                    colorRole: "onSurfaceVariant"
                    elide: Text.ElideRight
                }
            }

            // Right Arrow / Chevron Button to expand/collapse slider
            Rectangle {
                id: micArrowBtn
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Layout.alignment: Qt.AlignVCenter
                radius: 13
                color: micArrowMouse.containsMouse
                    ? (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("onSurface"), 0.14) : "rgba(255,255,255,0.14)")
                    : (quickActionsRoot.micExpanded
                        ? (quickActionsRoot.theme ? Qt.alpha(quickActionsRoot.theme.getColor("primary"), 0.15) : "rgba(255,255,255,0.1)")
                        : "transparent")

                Behavior on color { ColorAnimation { duration: 120 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 14
                    icon: "actions/chevron-right.svg"
                    rotation: quickActionsRoot.micExpanded ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    color: quickActionsRoot.micExpanded
                        ? (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("primary") : "#ffb3b4")
                        : (quickActionsRoot.theme ? quickActionsRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
                }

                MouseArea {
                    id: micArrowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        quickActionsRoot.toggleMicExpanded();
                    }
                }
            }
        }

        // Main Card MouseArea for mute/unmute
        MouseArea {
            id: micMouse
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: 38
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (quickActionsRoot.micMuteToggleProc && typeof quickActionsRoot.micMuteToggleProc.toggleMute === "function") {
                    quickActionsRoot.micMuteToggleProc.toggleMute();
                } else {
                    quickActionsRoot.isMicMuted = !quickActionsRoot.isMicMuted;
                    quickActionsRoot.toggleMicMute();
                }
            }
        }
    }
}
