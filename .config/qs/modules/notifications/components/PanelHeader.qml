import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../../../components/ui" as UI

RowLayout {
    id: headerRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 38
    spacing: 10

    property var theme
    property string uptimeStr: "Up 0m"
    property string currentProfile: "performance"
    property bool powerProfileExpanded: false

    signal togglePowerProfile()
    signal closeRequested()

    // macOS Style Uptime Badge
    Rectangle {
        Layout.preferredHeight: 34
        implicitWidth: uptimeRow.implicitWidth + 24
        radius: 17
        color: headerRoot.theme ? Qt.alpha(headerRoot.theme.getColor("surfaceVariant"), 0.55) : "#302626"
        border.width: 1
        border.color: headerRoot.theme ? Qt.alpha(headerRoot.theme.getColor("outlineVariant"), 0.3) : "#453838"

        Row {
            id: uptimeRow
            anchors.centerIn: parent
            spacing: 7

            UI.Icon {
                size: 14
                icon: "system/power.svg"
                color: headerRoot.theme ? headerRoot.theme.getColor("primary") : "#ffb3b4"
                anchors.verticalCenter: parent.verticalCenter
            }

            UI.Typography {
                theme: headerRoot.theme
                text: headerRoot.uptimeStr
                variant: "labelMedium"
                font.bold: true
                colorRole: "onSurface"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Item { Layout.fillWidth: true }

    // macOS Style Segmented Tools Capsule
    Rectangle {
        Layout.preferredHeight: 34
        implicitWidth: toolsRow.width + 12
        radius: 17
        color: headerRoot.theme ? Qt.alpha(headerRoot.theme.getColor("surfaceVariant"), 0.55) : "#302626"
        border.width: 1
        border.color: headerRoot.theme ? Qt.alpha(headerRoot.theme.getColor("outlineVariant"), 0.3) : "#453838"

        Row {
            id: toolsRow
            anchors.centerIn: parent
            spacing: 4

            // 1. Eyedropper Color Picker
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: eyedropperMouse.containsMouse
                    ? (headerRoot.theme ? Qt.alpha(headerRoot.theme.getColor("primary"), 0.18) : "#453838")
                    : "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 15
                    icon: "actions/eyedropper-filled.svg"
                    color: eyedropperMouse.containsMouse
                        ? (headerRoot.theme ? headerRoot.theme.getColor("primary") : "#ffb3b4")
                        : (headerRoot.theme ? headerRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
                }

                MouseArea {
                    id: eyedropperMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        headerRoot.closeRequested();
                        Quickshell.execDetached(["hyprpicker", "-a"]);
                    }
                }
            }

            // 2. Screenshot Region Crop
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: cropMouse.containsMouse
                    ? (headerRoot.theme ? Qt.alpha(headerRoot.theme.getColor("primary"), 0.18) : "#453838")
                    : "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 15
                    icon: "actions/crop.svg"
                    color: cropMouse.containsMouse
                        ? (headerRoot.theme ? headerRoot.theme.getColor("primary") : "#ffb3b4")
                        : (headerRoot.theme ? headerRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
                }

                MouseArea {
                    id: cropMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        headerRoot.closeRequested();
                        Quickshell.execDetached(["hyprshot", "-m", "region", "-o", (Quickshell.env("HOME") || "") + "/Pictures/Screenshots"]);
                    }
                }
            }

            // 3. Power Profile Toggle
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: headerRoot.powerProfileExpanded
                    ? (headerRoot.theme ? headerRoot.theme.getColor("primary") : "#ffb3b4")
                    : (perfMouse.containsMouse
                        ? (headerRoot.theme ? Qt.alpha(headerRoot.theme.getColor("primary"), 0.18) : "#453838")
                        : "transparent")

                Behavior on color { ColorAnimation { duration: 120 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 15
                    icon: {
                        if (headerRoot.currentProfile === "performance") return "system/zap.svg";
                        if (headerRoot.currentProfile === "balanced") return "system/memory.svg";
                        return "system/leaf-two.svg";
                    }
                    color: headerRoot.powerProfileExpanded
                        ? (headerRoot.theme ? headerRoot.theme.getColor("onPrimary") : "#000000")
                        : (perfMouse.containsMouse
                            ? (headerRoot.theme ? headerRoot.theme.getColor("primary") : "#ffb3b4")
                            : (headerRoot.theme ? headerRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8"))
                }

                MouseArea {
                    id: perfMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: headerRoot.togglePowerProfile()
                }
            }
        }
    }
}
