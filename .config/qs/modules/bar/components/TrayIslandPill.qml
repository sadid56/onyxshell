import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import "../widgets"

Row {
    id: trayRow

    property var barWindow
    property int pillHeight: barWindow ? Math.max(20, barWindow.barHeight - 6) : 34

    anchors.top: parent.top
    anchors.topMargin: 6
    anchors.right: barWindow ? barWindow.netPillRef.left : parent.right
    anchors.rightMargin: 8
    spacing: 8
    layoutDirection: Qt.RightToLeft

    Repeater {
        model: SystemTray.items.values

        delegate: BarPill {
            id: singleTrayPill

            pillHeight: trayRow.pillHeight
            pillRadius: Math.floor(trayRow.pillHeight / 2)
            pillColor: barWindow ? barWindow.barSurfaceColor : "#1e1e2e"
            contentPadding: 14
            contentWidth: 20
            active: true

            Item {
                anchors.centerIn: parent
                width: 20
                height: 20

                IconImage {
                    anchors.fill: parent
                    source: {
                        var ic = modelData.icon || "";
                        if (!ic) return "";
                        if (ic.startsWith("/") || ic.startsWith("file://") || ic.startsWith("image://") || ic.startsWith("qrc:/")) return ic;
                        return "image://icon/" + ic;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        var pillPos = singleTrayPill.mapToItem(null, 0, 0);
                        var pillRight = pillPos.x + singleTrayPill.width;
                        if (typeof root !== "undefined") root.showTrayMenu(modelData, pillRight);
                    }
                    onExited: {
                        if (typeof root !== "undefined") root.hideTrayMenu();
                    }
                    onClicked: {
                        modelData.activate();
                        var target = modelData.id || modelData.title || "";
                        if (target) {
                            var clean = target.split(".").pop().replace(/-desktop/g, "");
                            Hyprland.dispatch("focuswindow " + clean);
                        }
                    }
                }
            }
        }
    }
}
