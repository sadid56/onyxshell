import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../../components/ui" as UI

Item {
    id: dockItemRoot

    property var theme
    property var itemData
    property bool isRunning: false
    property bool isFocused: false
    property bool isHovered: false

    property int iconSize: (typeof root !== "undefined" && root && root.settingsService && root.settingsService.dockIconSize) ? root.settingsService.dockIconSize : 28
    property int itemSize: iconSize + 16

    width: itemSize
    height: itemSize
    z: 1

    Rectangle {
        id: iconContainer
        anchors.fill: parent
        radius: 12
        color: dockItemRoot.isFocused
            ? (dockItemRoot.theme ? Qt.alpha(dockItemRoot.theme.getColor("secondaryContainer"), 0.35) : "#46464d66")
            : "transparent"

        Item {
            anchors.centerIn: parent
            width: dockItemRoot.iconSize
            height: dockItemRoot.iconSize

            IconImage {
                anchors.fill: parent
                source: {
                    var ic = dockItemRoot.itemData ? (dockItemRoot.itemData.icon || "") : "";
                    if (!ic) return "";
                    if (ic.indexOf("/") === 0) return "file://" + ic;
                    if (ic.startsWith("file://") || ic.startsWith("image://") || ic.startsWith("qrc:/")) return ic;
                    return "image://icon/" + ic;
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            anchors.horizontalCenter: parent.horizontalCenter
            width: dockItemRoot.isFocused ? 14 : (dockItemRoot.isRunning ? 5 : 0)
            height: 3
            radius: 1.5
            color: dockItemRoot.theme
                ? (dockItemRoot.isFocused ? dockItemRoot.theme.getColor("primary") : dockItemRoot.theme.getColor("onSurfaceVariant"))
                : "#c5c5d8"
            opacity: (dockItemRoot.isRunning || dockItemRoot.isFocused) ? 1.0 : 0.0

            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }
    }
}
