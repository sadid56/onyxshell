import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../../components/ui" as UI

Item {
    id: stripRoot

    property var theme
    property int currentWsId: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id : 1
    property var populatedWorkspaces: []
    property var allClients: []
    property int dragOverWs: -1

    signal switchWorkspace(int wsId)
    signal moveWindowToWorkspace(string address, int wsId)

    readonly property int highestUsedWs: {
        var focusedId = (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id : 1;
        var maxId = Math.max(3, focusedId);
        if (populatedWorkspaces && populatedWorkspaces.length > 0) {
            for (var k = 0; k < populatedWorkspaces.length; k++) {
                if (populatedWorkspaces[k] > maxId && populatedWorkspaces[k] <= 10) maxId = populatedWorkspaces[k];
            }
        }
        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            var list = Hyprland.workspaces.values;
            for (var i = 0; i < list.length; i++) {
                var ws = list[i];
                if (ws && ws.id > 0 && ws.id <= 10) {
                    if (ws.toplevels && ws.toplevels.values && ws.toplevels.values.length > 0) {
                        if (ws.id > maxId) maxId = ws.id;
                    }
                }
            }
        }
        return Math.min(10, maxId);
    }

    readonly property var activeWsList: {
        var list = [];
        for (var i = 1; i <= highestUsedWs; i++) {
            list.push(i);
        }
        return list;
    }

    readonly property real cardW: Math.min(205, Math.max(140, Math.floor((1780 - (activeWsList.length * 12)) / Math.max(1, activeWsList.length))))
    readonly property real cardH: Math.floor(cardW * 0.57)

    function findWorkspaceAt(gx, gy) {
        for (var i = 0; i < wsRepeater.count; i++) {
            var item = wsRepeater.itemAt(i);
            if (item) {
                var p = item.mapFromItem(null, gx, gy);
                if (p.x >= -30 && p.x <= item.width + 30 && p.y >= -30 && p.y <= item.height + 40) {
                    return item.targetWs;
                }
            }
        }
        return -1;
    }

    function updateDragHover(gx, gy) {
        dragOverWs = findWorkspaceAt(gx, gy);
    }

    function clearDragHover() {
        dragOverWs = -1;
    }

    implicitWidth: wsRow.implicitWidth + 24
    implicitHeight: cardH + 16
    height: cardH + 16

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            id: wsRepeater
            model: stripRoot.activeWsList
            delegate: Rectangle {
                id: wsThumbCard
                readonly property int targetWs: modelData
                readonly property bool isCurrent: targetWs === stripRoot.currentWsId
                readonly property bool isDragTarget: stripRoot.dragOverWs === targetWs
                readonly property bool isHighlighted: isCurrent || isDragTarget
                readonly property bool isHovered: isHighlighted || wsMouse.containsMouse

                width: stripRoot.cardW
                height: stripRoot.cardH
                radius: 14
                scale: 1.0

                color: isHighlighted
                       ? (stripRoot.theme ? Qt.alpha(stripRoot.theme.getColor("primaryContainer"), 0.90) : "#453850")
                       : (isHovered
                          ? (stripRoot.theme ? Qt.alpha(stripRoot.theme.getColor("surfaceVariant"), 0.90) : "#352c2c")
                          : (stripRoot.theme ? Qt.alpha(stripRoot.theme.getColor("surface"), 0.70) : "#201818"))

                border.width: isHighlighted ? 2 : 1
                border.color: isHighlighted
                              ? (stripRoot.theme ? stripRoot.theme.getColor("primary") : "#cba6f7")
                              : (isHovered
                                 ? (stripRoot.theme ? stripRoot.theme.getColor("outline") : "#887575")
                                 : (stripRoot.theme ? Qt.alpha(stripRoot.theme.getColor("outlineVariant"), 0.35) : "#403535"))

                Item {
                    anchors.fill: parent
                    anchors.margins: 8

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Repeater {
                            model: {
                                var wins = [];
                                for (var k = 0; k < stripRoot.allClients.length; k++) {
                                    var cl = stripRoot.allClients[k];
                                    if (cl && cl.workspace && (cl.workspace.id === targetWs || cl.workspace === targetWs)) {
                                        wins.push(cl);
                                    }
                                }
                                return wins.slice(0, 2);
                            }
                            delegate: Rectangle {
                                width: Math.min(36, stripRoot.cardH * 0.38)
                                height: width
                                radius: 8
                                color: stripRoot.theme ? Qt.alpha(stripRoot.theme.getColor("background"), 0.85) : "#151518"
                                border.width: 1
                                border.color: stripRoot.theme ? Qt.alpha(stripRoot.theme.getColor("outlineVariant"), 0.35) : "#353030"

                                IconImage {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    source: {
                                        var ic = modelData.icon || "";
                                        if (ic && ic.indexOf("/") === 0) return "file://" + ic;
                                        return ic;
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: stripRoot.switchWorkspace(targetWs)
                }
            }
        }
    }
}
