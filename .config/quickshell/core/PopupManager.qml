import QtQuick
import Quickshell
import Quickshell.Wayland
import "../modules/notifications"
import "../modules/calendar"
import "../modules/clipboard"
import "../modules/alt_tab"
import "../modules/emoji"
import "../modules/app_launcher"
import "../modules/bar/components"
import "../services"
QtObject {
    id: popupManager
    property var theme: null
    property var statusBar: null
    property var mediaService: null
    property var clipboardService: null
    property var activeNotifs: []
    property alias dashboardLoader: dashboardLoader
    property alias mediaLoader: mediaLoader
    property alias notifsLoader: notifsLoader
    property alias calendarLoader: calendarLoader
    property alias wifiLoader: wifiLoader
    property alias resourcesLoader: resourcesLoader
    property alias emojiLoader: emojiLoader
    property alias clipboardLoader: clipboardLoader
    property alias wallpaperSelectorLoader: wallpaperSelectorLoader
    property alias keybindsLoader: keybindsLoader
    property alias altTabLoader: altTabLoader
    property alias toastPopup: toastPopup
    property alias errorPopup: errorPopup
    property alias trayMenuPopup: trayMenuPopup
    property alias confirmationModal: confirmationModal
    function closeAllPopupsExcept(excludeLoader) {
        var loaders = [dashboardLoader, notifsLoader, calendarLoader, wifiLoader, resourcesLoader, emojiLoader, clipboardLoader, wallpaperSelectorLoader, keybindsLoader, altTabLoader, mediaLoader];
        for (var i = 0; i < loaders.length; i++) {
            var l = loaders[i];
            if (l !== excludeLoader && l.loaded && l.item) l.item.active = false;
        }
        if (trayMenuPopup && trayMenuPopup !== excludeLoader && trayMenuPopup.active) {
            trayMenuPopup.active = false;
        }
    }
    function showTrayMenu(trayItem, centerX) {
        closeAllPopupsExcept(trayMenuPopup);
        if (trayItem && trayItem.menu && trayItem.menu.menu) trayItem.menu.menu.updateLayout();
        trayMenuPopup.activeTrayItem = trayItem;
        trayMenuPopup.targetX = centerX;
        trayMenuPopup.active = true;
    }
    function hideTrayMenu() {
        trayMenuPopup.closeTimer.restart();
    }
    function toggleAltTab() {
        var loader = altTabLoader;
        if (!loader.loaded) {
            closeAllPopupsExcept(loader);
            loader.loaded = true;
            Qt.callLater(() => { if (loader.item) loader.item.active = true; });
        } else if (loader.item) {
            if (loader.item.active) {
                if (typeof loader.item.nextWindow === "function") loader.item.nextWindow();
            } else {
                closeAllPopupsExcept(loader);
                loader.item.active = true;
            }
        }
    }
    function toggleLoaderActive(loader, targetXVal) {
        if (!loader.loaded) {
            closeAllPopupsExcept(loader);
            loader.loaded = true;
            Qt.callLater(() => {
                if (loader.item) {
                    if (targetXVal !== undefined) loader.item.targetX = targetXVal;
                    loader.item.active = true;
                }
            });
        } else if (loader.item) {
            if (targetXVal !== undefined) loader.item.targetX = targetXVal;
            var nextState = !loader.item.active;
            if (nextState) closeAllPopupsExcept(loader);
            loader.item.active = nextState;
        }
    }
    function stopLoaderTimerAndActivate(loader, targetXVal) {
        closeAllPopupsExcept(loader);
        if (!loader.loaded) {
            loader.loaded = true;
            Qt.callLater(() => {
                if (loader.item) {
                    if (targetXVal !== undefined) loader.item.targetX = targetXVal;
                    loader.item.closeTimer.stop();
                    loader.item.active = true;
                }
            });
        } else if (loader.item) {
            if (targetXVal !== undefined) loader.item.targetX = targetXVal;
            loader.item.closeTimer.stop();
            loader.item.active = true;
        }
    }
    function restartLoaderTimer(loader) {
        if (loader.loaded && loader.item) loader.item.closeTimer.restart();
    }
    function setLoaderInactive(loader) {
        if (loader.loaded && loader.item) loader.item.active = false;
    }
    property list<QtObject> elements: [
        Loader {
            id: mediaLoader
            property bool loaded: false
            active: loaded
            onLoaded: { if (item) item.mediaService = popupManager.mediaService; }
            sourceComponent: MediaPopup { theme: popupManager.theme; mediaService: popupManager.mediaService }
        },
        Loader {
            id: notifsLoader
            property bool loaded: false
            active: loaded
            sourceComponent: NotificationCenter { theme: popupManager.theme }
        },
        Loader {
            id: calendarLoader
            property bool loaded: false
            active: loaded
            sourceComponent: CalendarPopup { theme: popupManager.theme }
        },
        Loader {
            id: wifiLoader
            property bool loaded: false
            active: loaded
            sourceComponent: WifiPopup { theme: popupManager.theme }
        },
        Loader {
            id: resourcesLoader
            property bool loaded: false
            active: loaded
            sourceComponent: SystemResourcesPopup { theme: popupManager.theme }
        },
        Loader {
            id: emojiLoader
            property bool loaded: false
            active: loaded
            sourceComponent: EmojiPicker { theme: popupManager.theme }
        },
        Loader {
            id: clipboardLoader
            property bool loaded: false
            active: loaded
            sourceComponent: ClipboardManager { theme: popupManager.theme; clipService: popupManager.clipboardService }
        },
        Loader {
            id: wallpaperSelectorLoader
            property bool loaded: false
            active: loaded
            sourceComponent: WallpaperSelector { theme: popupManager.theme }
        },
        Loader {
            id: keybindsLoader
            property bool loaded: false
            active: loaded
            sourceComponent: KeybindsPopup { theme: popupManager.theme }
        },
        Loader {
            id: dashboardLoader
            property bool loaded: false
            active: loaded
            sourceComponent: AppLauncher { theme: popupManager.theme }
        },
        Loader {
            id: altTabLoader
            property bool loaded: true
            active: true
            sourceComponent: AltTab { theme: popupManager.theme }
        },
        ToastHUD { id: toastPopup; theme: popupManager.theme },
        ErrorPopup { id: errorPopup; theme: popupManager.theme },
        TrayMenuPopup { id: trayMenuPopup; theme: popupManager.theme },
        ConfirmationModal { id: confirmationModal; theme: popupManager.theme }
    ]
}
