import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.DBusMenu
import "../../../components/ui" as UI

Item {
    id: entryDelegate

    property var theme
    property var itemModel
    property var popupWindow
    property var menuOpener

    signal hovered(real yPos, real itemHeight)
    signal unhovered()

    readonly property bool isItemEnabled: itemModel ? (itemModel.enabled !== false) : false
    readonly property bool isSeparator: itemModel ? Boolean(itemModel.isSeparator) : false

    readonly property bool isCheckmark: {
        if (!itemModel) return false;
        var t = itemModel.toggleType;
        return t === 1 || t === "checkmark" || (typeof DBusMenuItem !== "undefined" && t === DBusMenuItem.Checkmark);
    }

    readonly property bool isRadio: {
        if (!itemModel) return false;
        var t = itemModel.toggleType;
        return t === 2 || t === "radio" || (typeof DBusMenuItem !== "undefined" && t === DBusMenuItem.Radio);
    }

    readonly property bool hasToggle: isCheckmark || isRadio

    width: parent ? parent.width : 200
    height: isSeparator ? 9 : 32

    opacity: (!isItemEnabled && !isSeparator) ? 0.45 : 1.0

    Rectangle {
        id: highlightBg
        anchors.fill: parent
        radius: 8
        color: entryDelegate.theme ? entryDelegate.theme.getColor("surfaceVariant") : "#302f38"
        opacity: (!entryDelegate.isSeparator && itemMouse.containsMouse) ? 1.0 : 0.0
        z: 0

        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }
    }

    Rectangle {
        visible: entryDelegate.isSeparator
        anchors.centerIn: parent
        width: parent.width - 12
        height: 1
        color: entryDelegate.theme ? entryDelegate.theme.getColor("outlineVariant") : "#ffffff"
        opacity: 0.25
        z: 1
    }

    RowLayout {
        visible: !entryDelegate.isSeparator
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8
        z: 2

        Item {
            width: 16
            height: 16
            visible: !entryDelegate.isSeparator && (entryDelegate.hasToggle || (entryDelegate.itemModel && entryDelegate.itemModel.icon && entryDelegate.itemModel.icon !== ""))

            IconImage {
                anchors.centerIn: parent
                width: 14
                height: 14
                visible: entryDelegate.isCheckmark && entryDelegate.itemModel && entryDelegate.itemModel.checkState === Qt.Checked
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/check.svg")
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: entryDelegate.theme ? entryDelegate.theme.getColor("primary") : "#ffb3b4"
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 6
                height: 6
                radius: 3
                visible: entryDelegate.isRadio && entryDelegate.itemModel && entryDelegate.itemModel.checkState === Qt.Checked
                color: entryDelegate.theme ? entryDelegate.theme.getColor("primary") : "#ffb3b4"
            }

            IconImage {
                anchors.centerIn: parent
                width: 14
                height: 14
                visible: !entryDelegate.hasToggle && entryDelegate.itemModel && Boolean(entryDelegate.itemModel.icon)
                source: {
                    if (!entryDelegate.itemModel || !entryDelegate.itemModel.icon) return "";
                    var ic = entryDelegate.itemModel.icon;
                    if (ic.startsWith("/") || ic.startsWith("file://") || ic.startsWith("image://") || ic.startsWith("qrc:/")) return ic;
                    return "image://icon/" + ic;
                }
            }
        }

        UI.Typography {
            theme: entryDelegate.theme
            Layout.fillWidth: true
            text: (entryDelegate.itemModel && entryDelegate.itemModel.text) ? entryDelegate.itemModel.text.replace(/&/g, "") : ""
            variant: "labelMedium"
            colorRole: "onSurface"
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
        }

        IconImage {
            width: 10
            height: 10
            visible: entryDelegate.itemModel ? Boolean(entryDelegate.itemModel.hasChildren) : false
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/chevron-right.svg")
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: entryDelegate.theme ? entryDelegate.theme.getColor("onSurfaceVariant") : "#999999"
            }
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: itemMouse
        anchors.fill: parent
        enabled: entryDelegate.isItemEnabled && !entryDelegate.isSeparator
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 3
        onEntered: {
            if (entryDelegate.popupWindow && entryDelegate.popupWindow.closeTimer) {
                entryDelegate.popupWindow.closeTimer.stop();
            }
            entryDelegate.hovered(entryDelegate.y, entryDelegate.height);
        }
        onExited: {
            entryDelegate.unhovered();
        }
        onClicked: {
            if (entryDelegate.itemModel && typeof entryDelegate.itemModel.triggered === "function") {
                entryDelegate.itemModel.triggered();
            }
            if (entryDelegate.popupWindow) {
                entryDelegate.popupWindow.active = false;
            }
        }
    }
}
