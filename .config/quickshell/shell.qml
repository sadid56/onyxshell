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
    property var activeNotifs: []
    property var clipboardService: clipService
    property MediaService mediaService: MediaService { id: mediaService }
    property Config shellConfig: Config { id: shellConfig }

    property alias launcherLoader: popupManager.launcherLoader
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
        var temp = root.activeNotifs.slice();
        for (var i = temp.length - 1; i >= 0; i--) {
            var n = temp[i];
            if (n && typeof n.dismiss === "function") {
                n.dismiss();
            }
        }
        root.activeNotifs = [];
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

    property var defaultWallpaperLoader: Process {
        id: defaultWallpaperLoader
        command: ["sh", "-c", "if [ ! -f " + shellConfig.quickshellDir + "/current_wallpaper ]; then echo \"" + shellConfig.defaultWallpaper + "\" > " + shellConfig.quickshellDir + "/current_wallpaper; fi"]
    }

    Component.onCompleted: {
        defaultWallpaperLoader.running = true;
    }

    property list<QtObject> shellObjects: [
        Wallpaper {
            id: wallpaperBackground
        },

        Theme {
            id: rootTheme
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

            toggleLauncher: () => { popupManager.toggleLoaderActive(popupManager.launcherLoader); }
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
                    var temp = root.activeNotifs.slice();
                    var idx = temp.indexOf(notification);
                    if (idx !== -1) {
                        temp.splice(idx, 1);
                        root.activeNotifs = temp;
                    }
                });
            }
        },
    ]
}
