import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "core"
import "theme"
import "services"
import "modules/bar"
import "modules/launcher"
import "modules/notifications"
import "modules/calendar"
import "modules/clipboard"
import "components/ui"
import "modules/bar/components"

QtObject {
    id: root

    property var activeNotifs: []
    onActiveNotifsChanged: {
        if (notifsLoader.item) {
            notifsLoader.item.activeNotifs = root.activeNotifs;
        }
    }
    property var clipboardService: clipService

    property Config shellConfig: Config {
        id: shellConfig
    }

    Component.onCompleted: {
        defaultWallpaperLoader.running = true;
    }

    property var reloadConnection: Connections {
        target: Quickshell
        
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
            Qt.callLater(() => {
                toastPopup.showToast({
                    summary: "Configuration Reloaded",
                    body: "Quickshell reloaded successfully."
                });
            });
        }
    }

    property var defaultWallpaperLoader: Process {
        id: defaultWallpaperLoader
        command: ["sh", "-c", "if [ ! -f " + shellConfig.quickshellDir + "/current_wallpaper ]; then echo \"" + shellConfig.defaultWallpaper + "\" > " + shellConfig.quickshellDir + "/current_wallpaper; fi; awww restore || awww img \"$(cat " + shellConfig.quickshellDir + "/current_wallpaper)\" --transition-type grow"]
    }

    function closeAllPopupsExcept(excludeLoader) {
        var loaders = [
            launcherLoader,
            notifsLoader,
            calendarLoader,
            wifiLoader,
            clipboardLoader,
            wallpaperSelectorLoader,
            keybindsLoader
        ];
        for (var i = 0; i < loaders.length; i++) {
            var l = loaders[i];
            if (l !== excludeLoader && l.loaded && l.item) {
                l.item.active = false;
            }
        }
    }

    function showTrayMenu(trayItem, centerX) {
        if (trayItem && trayItem.menu && trayItem.menu.menu) {
            trayItem.menu.menu.updateLayout();
        }
        trayMenuPopup.activeTrayItem = trayItem;
        trayMenuPopup.targetX = centerX;
        trayMenuPopup.active = true;
    }

    function hideTrayMenu() {
        trayMenuPopup.closeTimer.restart();
    }

    function toggleLoaderActive(loader, targetXVal) {
        if (!loader.loaded) {
            closeAllPopupsExcept(loader);
            loader.loaded = true;
            Qt.callLater(() => {
                if (loader.item) {
                    if (targetXVal !== undefined) {
                        loader.item.targetX = targetXVal;
                    }
                    loader.item.active = true;
                }
            });
        } else {
            if (loader.item) {
                if (targetXVal !== undefined) {
                    loader.item.targetX = targetXVal;
                }
                var nextState = !loader.item.active;
                if (nextState) {
                    closeAllPopupsExcept(loader);
                }
                loader.item.active = nextState;
            }
        }
    }

    function stopLoaderTimerAndActivate(loader, targetXVal) {
        closeAllPopupsExcept(loader);
        if (!loader.loaded) {
            loader.loaded = true;
            Qt.callLater(() => {
                if (loader.item) {
                    if (targetXVal !== undefined) {
                        loader.item.targetX = targetXVal;
                    }
                    loader.item.closeTimer.stop();
                    loader.item.active = true;
                }
            });
        } else {
            if (loader.item) {
                if (targetXVal !== undefined) {
                    loader.item.targetX = targetXVal;
                }
                loader.item.closeTimer.stop();
                loader.item.active = true;
            }
        }
    }

    function restartLoaderTimer(loader) {
        if (loader.loaded && loader.item) {
            loader.item.closeTimer.restart();
        }
    }

    function setLoaderInactive(loader) {
        if (loader.loaded && loader.item) {
            loader.item.active = false;
        }
    }

    property list<QtObject> shellObjects: [
        Theme {
            id: rootTheme
        },

        SysStats {
            id: sysStats
        },

        Clipboard {
            id: clipService
        },

        Bar {
            id: statusBar
            theme: rootTheme
            sysStats: sysStats
            notifCount: root.activeNotifs.length
            
            toggleLauncher: () => { toggleLoaderActive(launcherLoader); }
            toggleNotifications: () => { toggleLoaderActive(notifsLoader, statusBar.getNotifX()); }
            toggleCalendar: () => { toggleLoaderActive(calendarLoader, statusBar.getClockX()); }
            toggleWifi: () => { toggleLoaderActive(wifiLoader, statusBar.getWifiX()); }
        },

        ScreenCorners {
            id: screenCorners
            radius: shellConfig.cornerRadius
            color: rootTheme.getColor("surface")
        },

PanelWindow {
            id: rightEdgeTrigger
            anchors { top: true; bottom: true; right: true }
            implicitWidth: 2
            color: "transparent"
            exclusiveZone: 0

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    root.stopLoaderTimerAndActivate(notifsLoader, statusBar.getNotifX());
                    root.setLoaderInactive(calendarLoader);
                    root.setLoaderInactive(wifiLoader);
                }
            }
        },

        Loader {
            id: launcherLoader
            property bool loaded: false
            active: loaded
            sourceComponent: AppLauncher {
                theme: rootTheme
            }
        },

        Loader {
            id: notifsLoader
            property bool loaded: false
            active: loaded
            onLoaded: {
                if (item) {
                    item.activeNotifs = root.activeNotifs;
                }
            }
            sourceComponent: NotificationCenter {
                theme: rootTheme
                activeNotifs: root.activeNotifs
                onActiveChanged: {
                    if (active) {
                        activeNotifs = root.activeNotifs;
                    }
                }
            }
        },

        Loader {
            id: calendarLoader
            property bool loaded: false
            active: loaded
            sourceComponent: CalendarPopup {
                theme: rootTheme
            }
        },

        Loader {
            id: wifiLoader
            property bool loaded: false
            active: loaded
            sourceComponent: WifiPopup {
                theme: rootTheme
            }
        },

        Loader {
            id: clipboardLoader
            property bool loaded: false
            active: loaded
            sourceComponent: ClipboardManager {
                theme: rootTheme
                clipService: root.clipboardService
            }
        },

        Loader {
            id: wallpaperSelectorLoader
            property bool loaded: false
            active: loaded
            sourceComponent: WallpaperSelector {
                theme: rootTheme
            }
        },

        Loader {
            id: keybindsLoader
            property bool loaded: false
            active: loaded
            sourceComponent: KeybindsPopup {
                theme: rootTheme
            }
        },

        ToastHUD {
            id: toastPopup
            theme: rootTheme
        },

        ErrorPopup {
            id: errorPopup
            theme: rootTheme
        },

        TrayMenuPopup {
            id: trayMenuPopup
            theme: rootTheme
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
                toastPopup.showToast(notification);

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

        IpcHandler {
            target: "shell"

            function toggleLauncher(): void {
                toggleLoaderActive(launcherLoader);
            }

            function toggleNotifications(): void {
                toggleLoaderActive(notifsLoader);
            }

            function toggleClipboard(): void {
                toggleLoaderActive(clipboardLoader);
            }

            function toggleWallpaperSelector(): void {
                toggleLoaderActive(wallpaperSelectorLoader);
            }

            function toggleBar(): void {
                statusBar.visible = !statusBar.visible;
            }

            function toggleKeybinds(): void {
                toggleLoaderActive(keybindsLoader);
            }

            function reloadTheme(): void {
                rootTheme.reloadColors();
            }
        }
    ]
}
