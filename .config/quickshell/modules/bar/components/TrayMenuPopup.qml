import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.DBusMenu
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

    property alias closeTimer: closeTimer

    function formatAppTitle(item) {
        if (!item) return "Application";
        var t = (item.title && item.title.trim() !== "") ? item.title : (item.id || "Application");
        t = t.replace(/_status_icon_\d+/i, "").replace(/_status_icon/i, "").replace(/_tray_\d+/i, "").replace(/_tray/i, "").replace(/[-_]/g, " ");
        t = t.split(" ").filter(Boolean).map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
        return t || "Application";
    }

    readonly property int safeWidth: trayMenuWindow.width > 0 ? trayMenuWindow.width : 1920
    readonly property int expandedWidth: 230
    readonly property int collapsedWidth: 34
    readonly property int expandedHeight: Math.min(500, (menuListView ? menuListView.contentHeight : 200) + 56)

    Timer {
        id: closeTimer
        interval: 180
        repeat: false
        onTriggered: trayMenuWindow.active = false
    }

    Timer {
        id: openGuard
        interval: 150
        repeat: false
    }

    QsMenuOpener {
        id: menuOpener
        menu: trayMenuWindow.activeTrayItem ? trayMenuWindow.activeTrayItem.menu : null
    }

    function focusTrayApp(trayItem) {
        if (!trayItem) return;
        var scriptPath = ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getScript("focus_tray_window.py");
        Quickshell.execDetached(["python", scriptPath, trayItem.id || "", trayItem.title || "", trayItem.icon || ""]);
    }

    onActiveChanged: {
        if (active) {
            openGuard.restart();
            closeTimer.stop();
        }
    }

    Shortcut { sequence: "Escape"; enabled: trayMenuWindow.active; onActivated: trayMenuWindow.active = false }

    MouseArea {
        anchors.fill: parent
        enabled: trayMenuWindow.active
        hoverEnabled: true
        onClicked: trayMenuWindow.active = false
        onEntered: {
            if (trayMenuWindow.active && !openGuard.running) {
                trayMenuWindow.closeTimer.restart();
            }
        }
    }

    Item {
        id: morphAnchor
        x: targetX > 0 ? Math.max(trayMenuWindow.expandedWidth + 10, Math.min(targetX, safeWidth - 10)) : (safeWidth - 10)
        y: 6
        width: 1
        height: 1

        Rectangle {
            id: morphContainer
            anchors.right: parent.left
            anchors.top: parent.top
            width: trayMenuWindow.active ? trayMenuWindow.expandedWidth : trayMenuWindow.collapsedWidth
            height: trayMenuWindow.active ? trayMenuWindow.expandedHeight : 34
            radius: trayMenuWindow.active ? 14 : 17
            color: trayMenuWindow.theme ? trayMenuWindow.theme.getColor("surface") : "#1e1e2e"
            clip: true
            opacity: (trayMenuWindow.active || width > (trayMenuWindow.collapsedWidth + 2)) ? 1.0 : 0.0

            Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
            Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

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
                onEntered: trayMenuWindow.closeTimer.stop()
                onPositionChanged: trayMenuWindow.closeTimer.stop()
            }

            Column {
                id: contentColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 8
                spacing: 6
                opacity: trayMenuWindow.active ? 1.0 : 0.0
                visible: opacity > 0.001

                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

                Item {
                    width: parent.width
                    height: 22

                    RowLayout {
                        anchors.fill: parent
                        spacing: 6

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
                    spacing: 2
                    pillMargin: 0
                    pillRadius: 8
                    showBottomFade: false
                    pillColor: trayMenuWindow.theme ? trayMenuWindow.theme.getColor("surfaceVariant") : "#302f38"
                    model: menuOpener.children

                    delegate: TrayMenuItemDelegate {
                        width: menuListView.width
                        theme: trayMenuWindow.theme
                        itemModel: modelData
                        popupWindow: trayMenuWindow
                        menuOpener: menuOpener
                        onHovered: (yPos, itemH) => {
                            menuListView.currentIndex = index;
                            menuListView.hoverItem(index, yPos, itemH);
                        }
                        onUnhovered: menuListView.unhoverItem(index)
                    }
                }
            }
        }
    }
}
