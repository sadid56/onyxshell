import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import "./widgets"
import "./components"
import "../../core"
import "../../components/ui" as UI

PanelWindow {
    id: barWindow
    anchors { top: true; left: true; right: true }
    implicitHeight: 56
    color: "transparent"

    readonly property bool isFullscreen: (Hyprland.focusedWorkspace && Boolean(Hyprland.focusedWorkspace.hasfullscreen || Hyprland.focusedWorkspace.hasFullscreen))
    visible: !barWindow.isFullscreen

    margins { top: 0; left: 0; right: 0 }
    exclusiveZone: isFullscreen ? 0 : 40

    property var theme
    property var sysStats
    property var mediaService
    property var popupManager: null

    property var toggleLauncher
    property var toggleNotifications
    property var toggleCalendar
    property var toggleWifi
    property var toggleMedia
    property int notifCount: 0

    property int barHeight: 40
    property int barCornerRadius: (typeof root !== "undefined" && root && root.settingsService && root.settingsService.cornerRadius !== undefined) ? root.settingsService.cornerRadius : ((typeof root !== "undefined" && root && root.shellConfig) ? root.shellConfig.cornerRadius : 16)
    readonly property color barSurfaceColor: barWindow.theme ? barWindow.theme.getColor("surface") : "#1e1e2e"
    readonly property real rightIslandBaseWidth: rightIslandDock ? rightIslandDock.rightIslandBaseWidth : 230

    readonly property real centerPopupTargetWidth: (popupManager && popupManager.activeCenterPopupWidth > 0) ? popupManager.activeCenterPopupWidth : 0

    property var activeNotifData: null

    function showNotification(notif) {
        if (!notif) return;
        activeNotifData = {
            appName: notif.appName || notif.applicationName || "",
            summary: notif.summary || "Notification",
            body: (notif.body || "").replace(/\n/g, " "),
            appIcon: notif.appIcon || notif.icon || "",
            isEmoji: Boolean(notif.isEmoji),
            emojiChar: notif.emojiChar || "",
            notifRef: notif
        };
        centerNotifTimer.restart();
    }

    function triggerNotificationAction() {
        if (!activeNotifData) return;
        if (typeof root !== "undefined") {
            if (typeof calendarLoader !== "undefined") root.setLoaderInactive(calendarLoader);
            if (typeof notifsLoader !== "undefined") root.setLoaderInactive(notifsLoader);
        }

        var notif = activeNotifData.notifRef;
        if (notif) {
            var invoked = false;
            if (notif.actions && notif.actions.length > 0) {
                for (var i = 0; i < notif.actions.length; i++) {
                    var act = notif.actions[i];
                    if (act && (act.id === "default" || act.id === "0" || act.id === "default-action" || act.id === "open" || act.text === "Open" || act.text === "Default")) {
                        try { act.invoke(); invoked = true; } catch(e) {}
                        break;
                    }
                }
                if (!invoked && notif.actions[0]) {
                    try { notif.actions[0].invoke(); invoked = true; } catch(e) {}
                }
            }
            if (!invoked) {
                if (typeof notif.invokeDefault === "function") {
                    try { notif.invokeDefault(); } catch(e) {}
                } else if (typeof notif.invoke === "function") {
                    try { notif.invoke("default"); } catch(e) {}
                }
            }
        }

        var app = activeNotifData.appName || "";
        if (app) {
            var scriptPath = (typeof shellConfig !== "undefined" && shellConfig)
                ? shellConfig.getScript("focus_app.sh")
                : (Quickshell.env("HOME") + "/.config/quickshell/scripts/focus_app.sh");
            Quickshell.execDetached([scriptPath, app, "", ""]);
        }

        activeNotifData = null;
        notifDismissCooldown.restart();
    }

    Timer {
        id: centerNotifTimer
        interval: 4500
        repeat: false
        onTriggered: {
            barWindow.activeNotifData = null;
            notifDismissCooldown.restart();
        }
    }

    Timer {
        id: notifDismissCooldown
        interval: 600
        repeat: false
    }

    property alias notifDismissCooldown: notifDismissCooldown

    readonly property var leftIslandRef: leftIslandDock
    readonly property var netPillRef: netIslandPill
    readonly property var rightIslandRef: rightIslandDock

    function getClockX() { return barWindow.width / 2; }
    function getDistroX() { return 32; }
    function getMediaX() { return mediaIslandPill.getMediaX(); }
    function getWifiX() { return netIslandPill.getWifiX(); }
    function getResourcesX() { return rightIslandDock.sysStatsIndicator.getResourcesX(); }
    function getNotifX() {
        return (typeof centerIsland !== "undefined" && centerIsland && typeof centerIsland.clockItem !== "undefined" && centerIsland.clockItem)
            ? centerIsland.clockItem.getNotifX()
            : (width / 2 + 50);
    }
    function getPowerX() {
        var pos = rightIslandDock.powerMenuButton.mapToItem(null, 0, 0);
        return pos.x + rightIslandDock.powerMenuButton.width / 2;
    }

    Item {
        anchors.fill: parent

        Corner {
            anchors.top: leftIslandDock.bottom
            anchors.left: parent.left
            alignRight: false
            alignBottom: false
            color: barWindow.barSurfaceColor
            cornerRadius: barWindow.barCornerRadius
        }

        LeftIslandDock {
            id: leftIslandDock
            barWindow: barWindow
        }

        MediaIslandPill {
            id: mediaIslandPill
            barWindow: barWindow
        }

        Corner {
            anchors.top: parent.top
            anchors.right: centerIsland.left
            alignRight: true
            alignBottom: false
            color: barWindow.barSurfaceColor
            cornerRadius: barWindow.barCornerRadius
        }

        CenterNotch {
            id: centerIsland
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            barWindow: barWindow
        }

        Corner {
            anchors.top: parent.top
            anchors.left: centerIsland.right
            alignRight: false
            alignBottom: false
            color: barWindow.barSurfaceColor
            cornerRadius: barWindow.barCornerRadius
        }

        TrayIslandPill {
            id: trayIslandPill
            barWindow: barWindow
        }

        NetworkIslandPill {
            id: netIslandPill
            barWindow: barWindow
        }

        RightIslandDock {
            id: rightIslandDock
            barWindow: barWindow
        }

        Corner {
            anchors.top: rightIslandDock.bottom
            anchors.right: parent.right
            alignRight: true
            alignBottom: false
            color: barWindow.barSurfaceColor
            cornerRadius: barWindow.barCornerRadius
        }
    }
}
