import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Row {
    id: workspacesRoot
    // Reduced the gap between workspaces here
    spacing: 6 
    
    property var theme

    function mapClassToIcon(cls, title) {
        if (!cls) return "";
        cls = cls.toLowerCase();
        title = (title || "").toLowerCase();
        
        if (title.indexOf("nvim") !== -1) return "";
        if (title.indexOf("vim") !== -1) return "";
        if (title.indexOf("btop") !== -1 || title.indexOf("htop") !== -1) return "";
        if (title.indexOf("yazi") !== -1) return "󰇥";
        if (title.indexOf("spotify") !== -1) return "";
        
        if (cls === "kitty" || cls === "alacritty" || cls === "wezterm") return "";
        if (cls === "code" || cls === "code-url-handler" || cls.indexOf("cursor") === 0) return "󰨞";
        if (cls.indexOf("jetbrains-") === 0) return "";
        if (cls === "emacs") return "";
        
        if (cls === "firefox") return "";
        if (cls === "google-chrome" || cls === "chromium" || cls === "vivaldi-stable") return "";
        if (cls.indexOf("brave") !== -1) return "🦁";
        if (cls === "zen-alpha") return "󰈹";
        
        if (cls === "postman" || cls === "insomnia") return "󰛦";
        if (cls.indexOf("docker") === 0) return "";
        if (cls === "github-desktop") return "";
        if (cls === "dbeaver") return "";
        if (cls === "mongodb compass") return "";
        
        if (cls === "vlc") return "󰕔";
        if (cls === "mpv") return "";
        if (cls === "com.obsproject.studio") return "󰑋";
        if (cls === "steam") return "";
        
        if (cls === "discord" || cls === "vesktop" || cls === "webcord") return "";
        if (cls === "org.telegram.desktop") return "";
        if (cls === "slack") return "";
        if (cls === "teams-for-linux") return "󰊻";
        if (cls === "zoom") return "";
        
        if (cls === "obsidian") return "󰠮";
        if (cls === "notion-app") return "󰎚";
        if (cls === "thunar" || cls === "org.kde.dolphin" || cls === "org.gnome.nautilus") return "";
        
        if (cls === "org.pulseaudio.pavucontrol") return "󰕾";
        if (cls === "blueman-manager") return "";
        if (cls === "nm-connection-editor") return "󰤨";
        if (cls === "antigravity-ide") return "";
        
        return "";
    }

    Repeater {
        model: {
            if (!Hyprland.workspaces || !Hyprland.workspaces.values) return [];
            return Hyprland.workspaces.values.filter(ws => ws.id > 0);
        }

        Rectangle {
            id: dot
            property var wsData: modelData
            property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsData.id

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
                    }

                    var title = top.title || (top.wayland ? top.wayland.title : "") || "";
                    var icon = workspacesRoot.mapClassToIcon(cls, title);

                    if (icon && icons.indexOf(icon) === -1) {
                        icons.push(icon);
                    }
                }
                return icons;
            }

            visible: isActive || windowIcons.length > 0

            height: 24
            
            width: isActive 
                   ? Math.max(50, iconsRow.implicitWidth + 36) 
                   : Math.max(30, iconsRow.implicitWidth + 22)
            
            radius: height / 2

            color: isActive 
                   ? (workspacesRoot.theme ? workspacesRoot.theme.getColor("primary") : "#D0BCFF") 
                   : (workspacesRoot.theme ? workspacesRoot.theme.getColor("surfaceVariant") : "#2AFFFFFF")

            Behavior on width { 
                NumberAnimation { 
                    duration: 400; 
                    easing.type: Easing.OutBack; 
                    easing.overshoot: 2.0 
                } 
            }
            
            Behavior on color { 
                ColorAnimation { 
                    duration: 300; 
                    easing.type: Easing.OutQuad 
                } 
            }

            Rectangle {
                anchors.centerIn: parent
                visible: dot.isActive && dot.windowIcons.length === 0
                width: 8
                height: 8
                radius: 4
                color: workspacesRoot.theme ? workspacesRoot.theme.getColor("onPrimary") : "#381E72"
            }

            Row {
                id: iconsRow
                anchors.centerIn: parent
                spacing: 8
                visible: dot.windowIcons.length > 0

                Repeater {
                    model: dot.windowIcons
                    Text {
                        text: modelData
                        font.family: "Noto Sans"
                        font.pixelSize: 14
                        color: dot.isActive 
                            ? (workspacesRoot.theme ? workspacesRoot.theme.getColor("onPrimary") : "#381E72")
                            : (workspacesRoot.theme ? workspacesRoot.theme.getColor("onSurface") : "#E6E1E5")
                        
                        Behavior on color { 
                            ColorAnimation { duration: 300 } 
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (wsData && wsData.activate) {
                        wsData.activate();
                    } else {
                        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(wsData.id)]);
                    }
                }
            }
        }
    }
}
