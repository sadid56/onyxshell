import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.DBusMenu
import Quickshell.Hyprland
import "../widgets"
import "../../../components/ui" as UI

PanelWindow {
    id: trayMenuWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    visible: active || morphContainer.opacity > 0.01 || morphContainer.width > (collapsedWidth + 2)

    property var theme
    property real targetX: -1
    property var activeTrayItem: null

    property var activeSubMenuItem: null
    property real subMenuTargetY: 0

    Timer {
        id: subMenuCloseTimer
        interval: 350
        repeat: false
        onTriggered: activeSubMenuItem = null
    }

    readonly property alias subMenuCloseTimer: subMenuCloseTimer

    function openSubMenu(item, yCoord) {
        closeTimer.stop();
        subMenuCloseTimer.stop();
        activeSubMenuItem = item;
        subMenuTargetY = yCoord;
    }

    function closeSubMenu() {
        subMenuCloseTimer.restart();
    }

    property alias menuOpener: menuOpener
    property alias closeTimer: closeTimer
    property alias morphAnchorRef: morphAnchor

    function formatAppTitle(item) {
        if (!item) return "Application";
        var t = (item.title && item.title.trim() !== "") ? item.title : (item.id || "Application");
        t = t.replace(/_status_icon_\d+/i, "").replace(/_status_icon/i, "").replace(/_tray_\d+/i, "").replace(/_tray/i, "").replace(/[-_]/g, " ");
        t = t.split(" ").filter(Boolean).map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
        return t || "Application";
    }

    readonly property int safeWidth: trayMenuWindow.width > 0 ? trayMenuWindow.width : 1920
    readonly property int expandedWidth: 244
    readonly property int collapsedWidth: 34
    readonly property int subMenuWidth: 224
    readonly property int expandedHeight: Math.min(500, (menuListView ? menuListView.contentHeight : 200) + 64)

    Timer {
        id: closeTimer
        interval: 35
        repeat: false
        onTriggered: {
            trayMenuWindow.active = false;
            activeSubMenuItem = null;
        }
    }

    Timer {
        id: openGuard
        interval: 20
        repeat: false
    }

    QsMenuOpener {
        id: menuOpener
        menu: trayMenuWindow.activeTrayItem ? trayMenuWindow.activeTrayItem.menu : null
    }

    QsMenuOpener {
        id: subMenuOpener
        menu: trayMenuWindow.activeSubMenuItem
    }

    function focusTrayApp(trayItem) {
        if (!trayItem) return;
        var target = trayItem.id || trayItem.title || "";
        if (target) {
            var clean = target.split(".").pop().replace(/-desktop/g, "");
            Hyprland.dispatch("focuswindow " + clean);
        }
    }

    onActiveChanged: {
        if (active) {
            openGuard.restart();
            closeTimer.stop();
            subMenuCloseTimer.stop();
        } else {
            activeSubMenuItem = null;
        }
    }

    Shortcut { sequence: "Escape"; enabled: trayMenuWindow.active; onActivated: trayMenuWindow.active = false }

    MouseArea {
        id: backdropMouseArea
        anchors.fill: parent
        enabled: trayMenuWindow.active
        hoverEnabled: true
        onClicked: {
            trayMenuWindow.active = false;
            activeSubMenuItem = null;
        }
        onEntered: {
            if (trayMenuWindow.active && !openGuard.running) {
                trayMenuWindow.closeTimer.restart();
                trayMenuWindow.subMenuCloseTimer.restart();
            }
        }
    }

    Item {
        id: morphAnchor
        x: targetX > 0
            ? Math.max(trayMenuWindow.expandedWidth + 10, Math.min(targetX, safeWidth - trayMenuWindow.subMenuWidth - 12))
            : (safeWidth - trayMenuWindow.subMenuWidth - 12)
        y: 6
        width: 1
        height: 1

        Rectangle {
            id: morphContainer
            anchors.right: parent.left
            anchors.top: parent.top
            width: trayMenuWindow.active ? trayMenuWindow.expandedWidth : trayMenuWindow.collapsedWidth
            height: trayMenuWindow.active ? trayMenuWindow.expandedHeight : 34
            radius: trayMenuWindow.active ? 16 : 17
            color: trayMenuWindow.theme ? trayMenuWindow.theme.getColor("surface") : "#1e1e2e"
            clip: true
            opacity: (trayMenuWindow.active || width > (trayMenuWindow.collapsedWidth + 2)) ? 1.0 : 0.0

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
            Behavior on radius { NumberAnimation { duration: 160; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: trayMenuWindow.active
                shadowColor: "#60000000"
                shadowBlur: 1.0
                shadowVerticalOffset: 8
            }

            MouseArea {
                id: contentMouseArea
                anchors.fill: parent
                hoverEnabled: true
                z: -1
                onEntered: {
                    trayMenuWindow.closeTimer.stop();
                }
                onPositionChanged: {
                    trayMenuWindow.closeTimer.stop();
                }
            }

            Column {
                id: contentColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6
                opacity: trayMenuWindow.active ? 1.0 : 0.0
                visible: opacity > 0.001

                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

                Item {
                    width: parent.width
                    height: 24

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 8

                        IconImage {
                            width: 16
                            height: 16
                            Layout.alignment: Qt.AlignVCenter
                            source: {
                                if (!trayMenuWindow.activeTrayItem) return "";
                                var ic = trayMenuWindow.activeTrayItem.icon || "";
                                if (!ic) return "";
                                if (ic.startsWith("/") || ic.startsWith("file://") || ic.startsWith("image://") || ic.startsWith("qrc:/")) return ic;
                                return "image://icon/" + ic;
                            }
                        }

                        UI.Typography {
                            theme: trayMenuWindow.theme
                            text: trayMenuWindow.formatAppTitle(trayMenuWindow.activeTrayItem)
                            variant: "labelLarge"
                            font.bold: true
                            colorRole: "onSurface"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: trayMenuWindow.theme ? trayMenuWindow.theme.getColor("outlineVariant") : "#ffffff"
                    opacity: 0.25
                }

                UI.AnimatedListView {
                    id: menuListView
                    width: parent.width
                    height: contentHeight
                    implicitHeight: contentHeight
                    spacing: 3
                    defaultItemHeight: 38
                    showPillOnlyOnHover: true
                    pillMargin: 2
                    pillRadius: 12
                    showBottomFade: false
                    pillColor: trayMenuWindow.theme ? trayMenuWindow.theme.getColor("surfaceVariant") : "#302f38"
                    model: menuOpener.children

                    delegate: TrayMenuItemDelegate {
                        width: menuListView.width
                        theme: trayMenuWindow.theme
                        itemModel: modelData
                        popupWindow: trayMenuWindow
                        menuOpener: menuOpener
                        isSubMenu: false
                        onHovered: (yPos, itemH) => {
                            menuListView.currentIndex = index;
                            menuListView.hoverItem(index, yPos, itemH);
                        }
                        onUnhovered: menuListView.unhoverItem(index)
                    }
                }
            }
        }

        Corner {
            id: subMenuTopCorner
            cornerRadius: 14
            anchors.bottom: subMenuContainer.top
            anchors.left: morphContainer.right
            anchors.leftMargin: -0.5
            alignBottom: true
            alignRight: false
            color: trayMenuWindow.theme ? trayMenuWindow.theme.getColor("surface") : "#1e1e2e"
            visible: subMenuContainer.visible && subMenuContainer.width > 20 && subMenuContainer.y > 4
            z: 2
        }

        Corner {
            id: subMenuBottomCorner
            cornerRadius: 14
            anchors.top: subMenuContainer.bottom
            anchors.left: morphContainer.right
            anchors.leftMargin: -0.5
            alignBottom: false
            alignRight: false
            color: trayMenuWindow.theme ? trayMenuWindow.theme.getColor("surface") : "#1e1e2e"
            visible: subMenuContainer.visible && subMenuContainer.width > 20 && (subMenuContainer.y + subMenuContainer.height < morphContainer.height - 4)
            z: 2
        }

        Rectangle {
            id: subMenuContainer
            anchors.left: morphContainer.right
            anchors.leftMargin: -0.5
            y: Math.max(0, Math.min(morphContainer.height - height, trayMenuWindow.subMenuTargetY))
            width: (trayMenuWindow.active && Boolean(trayMenuWindow.activeSubMenuItem)) ? trayMenuWindow.subMenuWidth : 0
            height: (trayMenuWindow.active && Boolean(trayMenuWindow.activeSubMenuItem)) ? Math.min(420, Math.max(40, (subMenuList ? subMenuList.contentHeight : 0) + 20)) : 0
            radius: 16
            color: trayMenuWindow.theme ? trayMenuWindow.theme.getColor("surface") : "#1e1e2e"
            clip: true
            opacity: width > 10 ? 1.0 : 0.0
            visible: opacity > 0.01
            z: 1

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: trayMenuWindow.active && subMenuContainer.opacity > 0.5
                shadowColor: "#60000000"
                shadowBlur: 1.0
                shadowVerticalOffset: 8
            }

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.radius
                color: parent.color
                z: 0
            }

            MouseArea {
                id: subMenuMouseArea
                anchors.fill: parent
                hoverEnabled: true
                z: -1
                onEntered: {
                    trayMenuWindow.closeTimer.stop();
                    trayMenuWindow.subMenuCloseTimer.stop();
                }
                onPositionChanged: {
                    trayMenuWindow.closeTimer.stop();
                    trayMenuWindow.subMenuCloseTimer.stop();
                }
            }

            UI.AnimatedListView {
                id: subMenuList
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                height: contentHeight
                spacing: 3
                defaultItemHeight: 38
                showPillOnlyOnHover: true
                pillMargin: 2
                pillRadius: 12
                showBottomFade: false
                pillColor: trayMenuWindow.theme ? trayMenuWindow.theme.getColor("surfaceVariant") : "#302f38"
                model: subMenuOpener.children

                delegate: TrayMenuItemDelegate {
                    width: subMenuList.width
                    theme: trayMenuWindow.theme
                    itemModel: modelData
                    popupWindow: trayMenuWindow
                    menuOpener: subMenuOpener
                    isSubMenu: true
                    onHovered: (yPos, itemH) => {
                        subMenuList.currentIndex = index;
                        subMenuList.hoverItem(index, yPos, itemH);
                    }
                    onUnhovered: subMenuList.unhoverItem(index)
                }
            }
        }
    }
}
