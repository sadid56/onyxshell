import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "core"
import "theme"
import "services"
import "modules/bar"
import "modules/bar/components"
import "components/ui"
import "modules/wallpaper"

QtObject {
    id: root

    property bool dndEnabled: false
    property bool isReady: false
    property var startupGraceTimer: Timer {
        id: startupGraceTimer
        interval: 350
        running: true
        repeat: false
        onTriggered: root.isReady = true
    }
    property var activeNotifs: []
    property var clipboardService: clipService
    property MediaService mediaService: MediaService { id: mediaService }
    property Config shellConfig: Config { id: shellConfig }
    property Paths paths: Paths { id: paths }
    property SettingsService settingsService: settingsService
    property AppService appService: appService
    property Theme rootTheme: rootTheme
    property alias theme: rootTheme

    property alias wallpaperBackground: wallpaperBackground
    property alias dashboardLoader: popupManager.dashboardLoader
    property alias mediaLoader: popupManager.mediaLoader
    property alias notifsLoader: popupManager.notifsLoader
    property alias calendarLoader: popupManager.calendarLoader
    property alias wifiLoader: popupManager.wifiLoader
    property alias resourcesLoader: popupManager.resourcesLoader
    property alias emojiLoader: popupManager.emojiLoader
    property alias clipboardLoader: popupManager.clipboardLoader
    property alias wallpaperSelectorLoader: popupManager.wallpaperSelectorLoader
    property alias powerMenuLoader: popupManager.powerMenuLoader
    property alias altTab: popupManager.altTab

    property alias errorPopup: popupManager.errorPopup
    property alias trayMenuPopup: popupManager.trayMenuPopup
    property alias confirmationModal: popupManager.confirmationModal

    function confirm(options) {
        if (popupManager && popupManager.confirmationModal) {
            popupManager.confirmationModal.ask(options);
        }
    }

    function closeAllPopupsExcept(excludeLoader) {
        popupManager.closeAllPopupsExcept(excludeLoader);
    }

    function showTrayMenu(trayItem, centerX) {
        popupManager.showTrayMenu(trayItem, centerX);
    }

    function hideTrayMenu() {
        popupManager.hideTrayMenu();
    }

    function toggleLoaderActive(loader, targetXVal) {
        popupManager.toggleLoaderActive(loader, targetXVal);
    }

    function stopLoaderTimerAndActivate(loader, targetXVal) {
        popupManager.stopLoaderTimerAndActivate(loader, targetXVal);
    }

    function restartLoaderTimer(loader) {
        popupManager.restartLoaderTimer(loader);
    }

    function clearAllNotifications() {
        var toDismiss = root.activeNotifs.slice();

        root.activeNotifs = [];

        for (var i = 0; i < toDismiss.length; i++) {
            var n = toDismiss[i];
            if (n && typeof n.dismiss === "function") {
                n.dismiss();
            }
        }
    }

    function clearNotificationGroup(groupName) {
        var remaining = [];
        var toDismiss = [];
        var source = root.activeNotifs;
        for (var i = 0; i < source.length; i++) {
            var n = source[i];
            if (!n) continue;
            var notifObj = n.trackedNotification || n;
            var app = notifObj.appName || notifObj.applicationName || "Other";
            if (app === groupName) {
                toDismiss.push(n);
            } else {
                remaining.push(n);
            }
        }

        root.activeNotifs = remaining;

        for (var j = 0; j < toDismiss.length; j++) {
            var d = toDismiss[j];
            if (d && typeof d.dismiss === "function") {
                d.dismiss();
            }
        }
    }

    function setLoaderInactive(loader) {
        popupManager.setLoaderInactive(loader);
    }

    function setWallpaper(filePath) {
        if (wallpaperBackground && typeof wallpaperBackground.setWallpaper === "function") {
            wallpaperBackground.setWallpaper(filePath);
        }
    }

    property var reloadConnection: Connections {
        target: Quickshell

        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
            Qt.callLater(() => {
                if (statusBar && typeof statusBar.showNotification === "function") {
                    var cfg = ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig);
                    statusBar.showNotification({
                        appName: "Quickshell",
                        summary: "Configuration Reloaded",
                        body: "Quickshell reloaded successfully.",
                        appIcon: cfg ? cfg.getIcon("system/info.svg") : ""
                    });
                }
            });
        }
    }

    property list<QtObject> shellObjects: [
        Theme {
            id: rootTheme
        },

        Wallpaper {
            id: wallpaperBackground
        },

        SysStats {
            id: sysStats
        },

        Clipboard {
            id: clipService
        },

        SettingsService {
            id: settingsService
            rootTheme: rootTheme
        },

        AppService {
            id: appService
        },

        PopupManager {
            id: popupManager
            theme: rootTheme
            statusBar: statusBar
            mediaService: root.mediaService
            clipboardService: root.clipboardService
            activeNotifs: root.activeNotifs
            settingsService: settingsService
            appService: appService
        },

        IpcService {
            id: ipcService
            popupManager: popupManager
            statusBar: statusBar
            theme: rootTheme
        },

        Bar {
            id: statusBar
            theme: rootTheme
            sysStats: sysStats
            mediaService: root.mediaService
            popupManager: popupManager
            notifCount: root.activeNotifs.length

            toggleLauncher: () => { popupManager.toggleLoaderActive(popupManager.dashboardLoader); }
            toggleNotifications: () => { popupManager.toggleLoaderActive(popupManager.notifsLoader, statusBar.getNotifX()); }
            toggleCalendar: () => { popupManager.toggleLoaderActive(popupManager.calendarLoader, statusBar.getClockX()); }
            toggleWifi: () => { popupManager.toggleLoaderActive(popupManager.wifiLoader, statusBar.getWifiX()); }
            toggleMedia: () => { popupManager.toggleLoaderActive(popupManager.mediaLoader, statusBar.getMediaX()); }
        },

        ScreenCorners {
            id: screenCorners
            showTop: false
            radius: (settingsService && settingsService.cornerRadius !== undefined) ? settingsService.cornerRadius : shellConfig.cornerRadius
            color: rootTheme.getColor("surface")
        },

        NotificationServer {
            id: notifServer
            property int _notifSeq: 1
            bodySupported: true
            actionsSupported: true
            imageSupported: true
            onNotification: notification => {
                if (!root.isReady) {
                    if (typeof notification.dismiss === "function") notification.dismiss();
                    return;
                }

                if (settingsService && (settingsService.isAppMuted(notification) || settingsService.isAppMuted(notification.appName) || settingsService.isAppMuted(notification.applicationName) || settingsService.isAppMuted(notification.desktopEntry) || settingsService.isAppMuted(notification.appIcon))) {
                    if (typeof notification.dismiss === "function") notification.dismiss();
                    return;
                }

                if (root.dndEnabled || (settingsService && settingsService.dndEnabled)) {
                    if (typeof notification.dismiss === "function") notification.dismiss();
                    return;
                }

                notification.tracked = true;
                notification._uid = "notif_id_" + (notifServer._notifSeq++);
                var arr = root.activeNotifs.slice();
                if (arr.length >= 50) {
                    var old = arr.shift();
                    if (old && typeof old.dismiss === "function") old.dismiss();
                }
                arr.push(notification);
                root.activeNotifs = arr;
                if (statusBar && typeof statusBar.showNotification === "function") {
                    statusBar.showNotification(notification);
                }

                notification.closed.connect(() => {
                    var cur = root.activeNotifs;
                    if (!cur || cur.length === 0) return;
                    var idx = cur.indexOf(notification);
                    if (idx !== -1) {
                        var temp = cur.slice();
                        temp.splice(idx, 1);
                        root.activeNotifs = temp;
                    }
                });
            }
        },
    ]
}
