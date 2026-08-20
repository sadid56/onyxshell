import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../../utils"

Row {
    id: workspacesRoot
    spacing: 6

    property var theme

    AppIconUtils {
        id: iconUtils
    }

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

            property var windowIcons: {
                if (!wsData || !wsData.toplevels || !wsData.toplevels.values) return [];
                var list = wsData.toplevels.values;
                var icons = [];
                for (var j = 0; j < list.length; j++) {
                    var top = list[j];
                    if (!top) continue;

                    var cls = "";
                    if (top.lastIpcObject && top.lastIpcObject.class) {
                        cls = top.lastIpcObject.class;
                    } else if (top.wayland && top.wayland.appId) {
                        cls = top.wayland.appId;
                    } else if (top.appId) {
                        cls = top.appId;
                    }

                    var title = top.title || (top.wayland ? top.wayland.title : "") || (top.lastIpcObject ? top.lastIpcObject.title : "") || "";
                    var icon = iconUtils.mapClassToIcon(cls, title);

                    if (icon && icons.indexOf(icon) === -1) {
                        icons.push(icon);
                    }
                }
                return icons;
            }

            height: 24

            width: isActive
                   ? Math.max(48, iconsRow.implicitWidth + 24)
                   : (windowIcons.length > 0 ? Math.max(28, iconsRow.implicitWidth + 18) : 24)

            radius: height / 2

            color: isActive
                   ? (workspacesRoot.theme ? workspacesRoot.theme.getColor("primary") : "#D0BCFF")
                   : (workspacesRoot.theme ? workspacesRoot.theme.getColor("surfaceVariant") : "#2AFFFFFF")

            Behavior on width {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
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
                visible: dot.windowIcons.length === 0
                width: dot.isActive ? 8 : 6
                height: dot.isActive ? 8 : 6
                radius: width / 2
                color: dot.isActive
                    ? (workspacesRoot.theme ? workspacesRoot.theme.getColor("onPrimary") : "#381E72")
                    : (workspacesRoot.theme ? workspacesRoot.theme.getColor("onSurface") : "#E6E1E5")
                opacity: dot.isActive ? 1.0 : 0.4
            }

            RowLayout {
                id: iconsRow
                anchors.centerIn: parent
                spacing: 6
                visible: dot.windowIcons.length > 0

                Repeater {
                    model: dot.windowIcons
                    Text {
                        text: modelData
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignVCenter
                        color: dot.isActive
                            ? (workspacesRoot.theme ? workspacesRoot.theme.getColor("onPrimary") : "#381E72")
                            : (workspacesRoot.theme ? workspacesRoot.theme.getColor("onSurface") : "#E6E1E5")

                        Behavior on color {
                            ColorAnimation { duration: 250 }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (dot.wsData && typeof dot.wsData.activate === "function") {
                        dot.wsData.activate();
                    } else {
                        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(dot.wsId)]);
                    }
                }
            }
        }
    }
}
