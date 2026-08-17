import QtQuick
import Quickshell
import Quickshell.Wayland
import "../modules/launcher"
import "../modules/notifications"
import "../modules/calendar"
import "../modules/clipboard"
import "../modules/bar/components"
import "../services"

QtObject {
    id: popupManager

    property var theme: null
    property var statusBar: null
    property var mediaService: null
    property var clipboardService: null
    property var activeNotifs: []

    property alias launcherLoader: launcherLoader
    property alias mediaLoader: mediaLoader
    property alias notifsLoader: notifsLoader
    property alias calendarLoader: calendarLoader
    property alias wifiLoader: wifiLoader
    property alias clipboardLoader: clipboardLoader
    property alias wallpaperSelectorLoader: wallpaperSelectorLoader
    property alias keybindsLoader: keybindsLoader
    property alias toastPopup: toastPopup
    property alias errorPopup: errorPopup
    property alias trayMenuPopup: trayMenuPopup

    onActiveNotifsChanged: {
        if (notifsLoader.item) {
            notifsLoader.item.activeNotifs = popupManager.activeNotifs;
        }
    }

    function closeAllPopupsExcept(excludeLoader) {
        var loaders = [
            launcherLoader,
            notifsLoader,
            calendarLoader,
            wifiLoader,
            clipboardLoader,
            wallpaperSelectorLoader,
            keybindsLoader,
            mediaLoader
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

    property list<QtObject> elements: [
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
                    var notifX = popupManager.statusBar ? popupManager.statusBar.getNotifX() : undefined;
                    popupManager.stopLoaderTimerAndActivate(notifsLoader, notifX);
                    popupManager.setLoaderInactive(calendarLoader);
                    popupManager.setLoaderInactive(wifiLoader);
                    popupManager.setLoaderInactive(mediaLoader);
                }
            }
        },

        Loader {
            id: launcherLoader
            property bool loaded: false
            active: loaded
            sourceComponent: AppLauncher {
                theme: popupManager.theme
            }
        },

        Loader {
            id: mediaLoader
            property bool loaded: false
            active: loaded
            onLoaded: {
                if (item) {
                    item.mediaService = popupManager.mediaService;
                }
            }
            sourceComponent: MediaPopup {
                theme: popupManager.theme
                mediaService: popupManager.mediaService
            }
        },

        Loader {
            id: notifsLoader
            property bool loaded: false
            active: loaded
            onLoaded: {
                if (item) {
                    item.activeNotifs = popupManager.activeNotifs;
                }
            }
            sourceComponent: NotificationCenter {
                theme: popupManager.theme
                activeNotifs: popupManager.activeNotifs
                onActiveChanged: {
                    if (active) {
                        activeNotifs = popupManager.activeNotifs;
                    }
                }
            }
        },

        Loader {
            id: calendarLoader
            property bool loaded: false
            active: loaded
            sourceComponent: CalendarPopup {
                theme: popupManager.theme
            }
        },

        Loader {
            id: wifiLoader
            property bool loaded: false
            active: loaded
            sourceComponent: WifiPopup {
                theme: popupManager.theme
            }
        },

        Loader {
            id: clipboardLoader
            property bool loaded: false
            active: loaded
            sourceComponent: ClipboardManager {
                theme: popupManager.theme
                clipService: popupManager.clipboardService
            }
        },

        Loader {
            id: wallpaperSelectorLoader
            property bool loaded: false
            active: loaded
            sourceComponent: WallpaperSelector {
                theme: popupManager.theme
            }
        },

        Loader {
            id: keybindsLoader
            property bool loaded: false
            active: loaded
            sourceComponent: KeybindsPopup {
                theme: popupManager.theme
            }
        },

        ToastHUD {
            id: toastPopup
            theme: popupManager.theme
        },

        ErrorPopup {
            id: errorPopup
            theme: popupManager.theme
        },

        TrayMenuPopup {
            id: trayMenuPopup
            theme: popupManager.theme
        }
    ]
}
