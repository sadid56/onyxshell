import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../widgets"

Row {
    id: trayRow

    property var barWindow

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

            pillHeight: 34
            pillRadius: 17
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
                        var scriptPath = ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getScript("focus_tray_window.py");
                        Quickshell.execDetached(["python", scriptPath, modelData.id || "", modelData.title || "", modelData.icon || ""]);
                    }
                }
            }
        }
    }
}
