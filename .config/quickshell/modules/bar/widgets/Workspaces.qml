import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Row {
    id: workspacesRoot
    spacing: 6

    property var theme

    property int highestUsedWs: {
        var focusedId = (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id : 1;
        var maxId = Math.max(3, focusedId);
        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            var list = Hyprland.workspaces.values;
            for (var i = 0; i < list.length; i++) {
                var ws = list[i];
                if (ws && ws.id > 0) {
                    if (ws.toplevels && ws.toplevels.values && ws.toplevels.values.length > 0) {
                        if (ws.id > maxId) maxId = ws.id;
                    }
                }
            }
        }
        return maxId;
    }

    Repeater {
        model: 10

        Rectangle {
            id: dot
            property int wsId: index + 1
            visible: wsId <= workspacesRoot.highestUsedWs

            property var wsData: {
                if (!Hyprland.workspaces || !Hyprland.workspaces.values) return null;
                var list = Hyprland.workspaces.values;
                for (var i = 0; i < list.length; i++) {
                    if (list[i] && list[i].id === wsId) return list[i];
                }
                return null;
            }

            property bool isActive: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId)
            property bool hasWindows: (wsData && wsData.toplevels && wsData.toplevels.values && wsData.toplevels.values.length > 0)

            height: 24
            width: isActive ? 44 : 24
            radius: 12

            color: isActive
                   ? (workspacesRoot.theme ? workspacesRoot.theme.getColor("primary") : "#D0BCFF")
                   : (workspacesRoot.theme ? workspacesRoot.theme.getColor("surfaceVariant") : "#2AFFFFFF")

            Behavior on width {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 250
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: dot.isActive ? 8 : 6
                height: dot.isActive ? 8 : 6
                radius: width / 2
                color: dot.isActive
                    ? (workspacesRoot.theme ? workspacesRoot.theme.getColor("onPrimary") : "#381E72")
                    : (workspacesRoot.theme ? workspacesRoot.theme.getColor("onSurface") : "#E6E1E5")
                opacity: dot.isActive ? 1.0 : (dot.hasWindows ? 0.9 : 0.4)

                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (dot.wsData && typeof dot.wsData.activate === "function") {
                        dot.wsData.activate();
                    } else {
                        Quickshell.execDetached([
                            "hyprctl", "eval",
                            "hl.dispatch(hl.dsp.focus({ workspace = " + dot.wsId + " }))"
                        ]);
                    }
                }
            }
        }
    }
}
