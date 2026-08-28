import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

RowLayout {
    id: headerRoot
    Layout.fillWidth: true
    spacing: 10

    property var theme
    property string uptimeStr: "Up 0m"
    property string currentProfile: "performance"
    property bool powerProfileExpanded: false

    property var hyprpickerProc
    property var screenshotProc

    signal togglePowerProfile()
    signal closeRequested()

    Rectangle {
        height: 34
        implicitWidth: uptimeRow.implicitWidth + 20
        radius: 10
        color: headerRoot.theme ? headerRoot.theme.getColor("surfaceVariant") + "40" : "#282932"
        border.width: 1
        border.color: headerRoot.theme ? headerRoot.theme.getColor("outlineVariant") + "20" : "#ffffff15"

        RowLayout {
            id: uptimeRow
            anchors.centerIn: parent
            spacing: 6

            IconImage {
                width: 15
                height: 15
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/clock.svg")
                Layout.alignment: Qt.AlignVCenter
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: headerRoot.theme ? headerRoot.theme.getColor("primary") : "#ffb3b4"
                }
            }

            UI.Typography {
                theme: headerRoot.theme
                text: headerRoot.uptimeStr
                variant: "labelMedium"
                font.bold: true
                colorRole: "onSurface"
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Item { Layout.fillWidth: true }

    Rectangle {
        id: pillToolbar
        height: 34
        implicitWidth: toolbarRow.implicitWidth + 8
        radius: 10
        color: headerRoot.theme ? headerRoot.theme.getColor("surfaceVariant") + "40" : "#282932"
        border.width: 1
        border.color: headerRoot.theme ? headerRoot.theme.getColor("outlineVariant") + "25" : "#ffffff15"

        RowLayout {
            id: toolbarRow
            anchors.centerIn: parent
            spacing: 2

            Rectangle {
                width: 32
                height: 28
                radius: 7
                color: eyedropperMouse.containsMouse
                    ? (headerRoot.theme ? headerRoot.theme.getColor("surfaceVariant") : "#3a3944")
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
                        if (headerRoot.hyprpickerProc) {
                            headerRoot.hyprpickerProc.running = false;
                            headerRoot.hyprpickerProc.running = true;
                        }
                    }
                }
            }

            Rectangle {
                width: 1
                height: 14
                color: headerRoot.theme ? headerRoot.theme.getColor("outlineVariant") + "30" : "#ffffff20"
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                width: 32
                height: 28
                radius: 7
                color: cropMouse.containsMouse
                    ? (headerRoot.theme ? headerRoot.theme.getColor("surfaceVariant") : "#3a3944")
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
                        if (headerRoot.screenshotProc) {
                            headerRoot.screenshotProc.running = false;
                            headerRoot.screenshotProc.running = true;
                        }
                    }
                }
            }

            Rectangle {
                width: 1
                height: 14
                color: headerRoot.theme ? headerRoot.theme.getColor("outlineVariant") + "30" : "#ffffff20"
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                width: 32
                height: 28
                radius: 7
                color: headerRoot.powerProfileExpanded
                    ? (headerRoot.theme ? headerRoot.theme.getColor("primaryContainer") : "#4f3737")
                    : (powerMouse.containsMouse
                        ? (headerRoot.theme ? headerRoot.theme.getColor("surfaceVariant") : "#3a3944")
                        : "transparent")

                Behavior on color { ColorAnimation { duration: 120 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 15
                    icon: {
                        if (headerRoot.currentProfile === "performance") return "system/zap.svg";
                        if (headerRoot.currentProfile === "power-saver") return "system/leaf-two.svg";
                        return "system/memory.svg";
                    }
                    color: headerRoot.powerProfileExpanded
                        ? (headerRoot.theme ? headerRoot.theme.getColor("onPrimaryContainer") : "#ffb3b4")
                        : (powerMouse.containsMouse
                            ? (headerRoot.theme ? headerRoot.theme.getColor("primary") : "#ffb3b4")
                            : (headerRoot.theme ? headerRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8"))
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: headerRoot.togglePowerProfile()
                }
            }

            Rectangle {
                width: 1
                height: 14
                color: headerRoot.theme ? headerRoot.theme.getColor("outlineVariant") + "30" : "#ffffff20"
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                width: 32
                height: 28
                radius: 7
                color: settingsMouse.containsMouse
                    ? (headerRoot.theme ? headerRoot.theme.getColor("surfaceVariant") : "#3a3944")
                    : "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }

                UI.Icon {
                    anchors.centerIn: parent
                    size: 15
                    icon: "categories/category-settings.svg"
                    color: settingsMouse.containsMouse
                        ? (headerRoot.theme ? headerRoot.theme.getColor("primary") : "#ffb3b4")
                        : (headerRoot.theme ? headerRoot.theme.getColor("onSurfaceVariant") : "#c5c5d8")
                }

                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        headerRoot.closeRequested();
                        if (typeof root !== "undefined" && root.popupManager) {
                            root.popupManager.toggleLoaderActive(root.popupManager.settingsLoader);
                        } else if (typeof popupManager !== "undefined") {
                            popupManager.toggleLoaderActive(popupManager.settingsLoader);
                        }
                    }
                }
            }
        }
    }
}
