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
    property bool isSubMenu: false

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

    readonly property bool hasIcon: {
        if (isSeparator) return false;
        if (!itemModel) return false;
        if (hasToggle && itemModel.checkState === Qt.Checked) return true;
        var ic = itemModel.icon;
        if (ic === null || ic === undefined) return false;
        var str = String(ic).trim();
        if (str === "" || str === "null" || str === "undefined" || str === "[object Object]") return false;
        return true;
    }

    width: parent ? parent.width : 200
    height: isSeparator ? 9 : 38

    opacity: (!isItemEnabled && !isSeparator) ? 0.45 : 1.0

    Rectangle {
        id: highlightBg
        anchors.fill: parent
        radius: 12
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

    Item {
        id: iconContainer
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: entryDelegate.hasIcon ? 16 : 0
        height: 16
        visible: entryDelegate.hasIcon && !entryDelegate.isSeparator
        z: 2

        IconImage {
            anchors.centerIn: parent
            width: 14
            height: 14
            visible: entryDelegate.isCheckmark && entryDelegate.itemModel && entryDelegate.itemModel.checkState === Qt.Checked
            source: ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getIcon("actions/check.svg")
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
        anchors.left: entryDelegate.hasIcon ? iconContainer.right : parent.left
        anchors.leftMargin: entryDelegate.hasIcon ? 8 : 10
        anchors.right: chevronIcon.visible ? chevronIcon.left : parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: (entryDelegate.itemModel && entryDelegate.itemModel.text) ? entryDelegate.itemModel.text.replace(/&/g, "").trim() : ""
        variant: "labelMedium"
        colorRole: "onSurface"
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
        visible: !entryDelegate.isSeparator
        z: 2
    }

    IconImage {
        id: chevronIcon
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 10
        height: 10
        visible: !entryDelegate.isSeparator && entryDelegate.itemModel && Boolean(entryDelegate.itemModel.hasChildren)
        source: ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getIcon("actions/chevron-right.svg")
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: entryDelegate.theme ? entryDelegate.theme.getColor("onSurfaceVariant") : "#999999"
        }
        z: 2
    }

    MouseArea {
        id: itemMouse
        anchors.fill: parent
        enabled: entryDelegate.isItemEnabled && !entryDelegate.isSeparator
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 3
        onEntered: {
            if (entryDelegate.popupWindow) {
                if (entryDelegate.popupWindow.closeTimer) entryDelegate.popupWindow.closeTimer.stop();
                if (entryDelegate.popupWindow.subMenuCloseTimer) entryDelegate.popupWindow.subMenuCloseTimer.stop();
            }
            entryDelegate.hovered(entryDelegate.y, entryDelegate.height);

            if (entryDelegate.itemModel && entryDelegate.itemModel.hasChildren) {
                if (typeof entryDelegate.itemModel.sendOpened === "function") entryDelegate.itemModel.sendOpened();
                if (typeof entryDelegate.itemModel.updateLayout === "function") entryDelegate.itemModel.updateLayout();
                if (entryDelegate.popupWindow && typeof entryDelegate.popupWindow.openSubMenu === "function") {
                    var anchorPos = (entryDelegate.popupWindow.morphAnchorRef)
                        ? entryDelegate.mapToItem(entryDelegate.popupWindow.morphAnchorRef, 0, 0)
                        : entryDelegate.mapToItem(null, 0, 0);
                    entryDelegate.popupWindow.openSubMenu(entryDelegate.itemModel, anchorPos.y - 4);
                }
            } else if (!entryDelegate.isSubMenu) {
                if (entryDelegate.popupWindow) {
                    entryDelegate.popupWindow.activeSubMenuItem = null;
                }
            }
        }
        onExited: {
            entryDelegate.unhovered();
        }
        onClicked: {
            if (entryDelegate.itemModel && entryDelegate.itemModel.hasChildren) {
                if (typeof entryDelegate.itemModel.sendOpened === "function") entryDelegate.itemModel.sendOpened();
                if (typeof entryDelegate.itemModel.updateLayout === "function") entryDelegate.itemModel.updateLayout();
                if (entryDelegate.popupWindow && typeof entryDelegate.popupWindow.openSubMenu === "function") {
                    var anchorPos = (entryDelegate.popupWindow.morphAnchorRef)
                        ? entryDelegate.mapToItem(entryDelegate.popupWindow.morphAnchorRef, 0, 0)
                        : entryDelegate.mapToItem(null, 0, 0);
                    entryDelegate.popupWindow.openSubMenu(entryDelegate.itemModel, anchorPos.y - 4);
                }
                return;
            }
            if (entryDelegate.itemModel && typeof entryDelegate.itemModel.triggered === "function") {
                entryDelegate.itemModel.triggered();
            }
            if (entryDelegate.popupWindow) {
                entryDelegate.popupWindow.active = false;
            }
        }
    }
}
