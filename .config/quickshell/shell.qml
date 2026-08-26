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
import "modules/splash"

QtObject {
    id: root

    property bool dndEnabled: false
    property var activeNotifs: []
    property var clipboardService: clipService
    property MediaService mediaService: MediaService { id: mediaService }
    property Config shellConfig: Config { id: shellConfig }

    property alias splashScreen: splashScreen
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
    property alias keybindsLoader: popupManager.keybindsLoader
    property alias altTabLoader: popupManager.altTabLoader
    property alias toastPopup: popupManager.toastPopup
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
                popupManager.toastPopup.showToast({
                    summary: "Configuration Reloaded",
                    body: "Quickshell reloaded successfully."
                });
            });
        }
    }

    property list<QtObject> shellObjects: [
        Theme {
            id: rootTheme
        },

        SplashScreen {
            id: splashScreen
            theme: rootTheme
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

        PopupManager {
            id: popupManager
            theme: rootTheme
            statusBar: statusBar
            mediaService: root.mediaService
            clipboardService: root.clipboardService
            activeNotifs: root.activeNotifs
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
            notifCount: root.activeNotifs.length

            toggleLauncher: () => { popupManager.toggleLoaderActive(popupManager.dashboardLoader, statusBar.getDistroX()); }
            toggleNotifications: () => { popupManager.toggleLoaderActive(popupManager.notifsLoader, statusBar.getNotifX()); }
            toggleCalendar: () => { popupManager.toggleLoaderActive(popupManager.calendarLoader, statusBar.getClockX()); }
            toggleWifi: () => { popupManager.toggleLoaderActive(popupManager.wifiLoader, statusBar.getWifiX()); }
            toggleMedia: () => { popupManager.toggleLoaderActive(popupManager.mediaLoader, statusBar.getMediaX()); }
        },

        ScreenCorners {
            id: screenCorners
            radius: shellConfig.cornerRadius
            color: rootTheme.getColor("surface")
        },

        NotificationServer {
            id: notifServer
            property int _notifSeq: 1
            bodySupported: true
            actionsSupported: true
            imageSupported: true
            onNotification: notification => {
                notification.tracked = true;
                notification._uid = "notif_id_" + (notifServer._notifSeq++);
                var arr = root.activeNotifs.slice();
                arr.push(notification);
                root.activeNotifs = arr;
                if (!root.dndEnabled) {
                    popupManager.toastPopup.showToast(notification);
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
