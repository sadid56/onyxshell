import QtQuick
import Quickshell
import Quickshell.Wayland
import "../modules/notifications"
import "../modules/calendar"
import "../modules/clipboard"
import "../modules/alt_tab"
import "../modules/emoji"
import "../modules/app_launcher"
import "../modules/power_menu"
import "../modules/overview"
import "../modules/bar/components"
import "../services"

QtObject {
    id: popupManager

    property var theme: null
    property var statusBar: null
    property var mediaService: null
    property var clipboardService: null
    property var settingsService: null
    property var appService: null
    property var activeNotifs: []

    property alias overviewLoader: overviewLoader
    property alias dashboardLoader: dashboardLoader
    property alias mediaLoader: mediaLoader
    property alias notifsLoader: notifsLoader
    property alias calendarLoader: calendarLoader
    property alias wifiLoader: wifiLoader
    property alias resourcesLoader: resourcesLoader
    property alias emojiLoader: emojiLoader
    property alias clipboardLoader: clipboardLoader
    property alias wallpaperSelectorLoader: wallpaperSelectorLoader
    property alias powerMenuLoader: powerMenuLoader
    property alias altTab: altTab
    property alias errorPopup: errorPopup
    property alias trayMenuPopup: trayMenuPopup
    property alias confirmationModal: confirmationModal

    property real activeCenterPopupWidth: 0

    function updateCenterPopupWidth() {
        if (dashboardLoader.loaded && dashboardLoader.item && dashboardLoader.item.active) {
            activeCenterPopupWidth = dashboardLoader.item.popupWidth || 580;
            return;
        }
        if (calendarLoader.loaded && calendarLoader.item && calendarLoader.item.active) {
            activeCenterPopupWidth = calendarLoader.item.popupWidth || 500;
            return;
        }
        if (notifsLoader.loaded && notifsLoader.item && notifsLoader.item.active) {
            activeCenterPopupWidth = notifsLoader.item.popupWidth || 540;
            return;
        }
        if (clipboardLoader.loaded && clipboardLoader.item && clipboardLoader.item.active) {
            activeCenterPopupWidth = clipboardLoader.item.popupWidth || 480;
            return;
        }
        if (emojiLoader.loaded && emojiLoader.item && emojiLoader.item.active) {
            activeCenterPopupWidth = emojiLoader.item.popupWidth || 520;
            return;
        }
        activeCenterPopupWidth = 0;
    }

    function showNotification(notif) {
        if (statusBar && typeof statusBar.showNotification === "function") {
            statusBar.showNotification(notif);
        }
    }

    function closeAllPopupsExcept(excludeLoader) {
        var loaders = [overviewLoader, dashboardLoader, notifsLoader, calendarLoader, wifiLoader, resourcesLoader, emojiLoader, clipboardLoader, wallpaperSelectorLoader, powerMenuLoader, mediaLoader];
        for (var i = 0; i < loaders.length; i++) {
            var l = loaders[i];
            if (l !== excludeLoader && l.loaded && l.item) l.item.active = false;
        }
        if (altTab && altTab !== excludeLoader && altTab.active) {
            altTab.active = false;
        }
        if (trayMenuPopup && trayMenuPopup !== excludeLoader && trayMenuPopup.active) {
            trayMenuPopup.active = false;
        }
        updateCenterPopupWidth();
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

    function quickSwitchAltTab() {
        if (altTab) {
            altTab.quickSwitch();
        }
    }

    function toggleAltTab() {
        if (altTab) {
            if (altTab.active) {
                if (typeof altTab.nextWindow === "function") altTab.nextWindow();
            } else {
                closeAllPopupsExcept(null);
                altTab.active = true;
                if (altTab.clientsList && altTab.clientsList.length > 1) {
                    altTab.selectedIndex = 1;
                }
            }
            updateCenterPopupWidth();
        }
    }

    function toggleAltTabPrev() {
        if (altTab) {
            if (altTab.active) {
                if (typeof altTab.previousWindow === "function") altTab.previousWindow();
            } else {
                closeAllPopupsExcept(null);
                altTab.active = true;
                if (altTab.clientsList && altTab.clientsList.length > 1) {
                    altTab.selectedIndex = altTab.clientsList.length - 1;
                }
            }
            updateCenterPopupWidth();
        }
    }

    function toggleLoaderActive(loader, targetXVal) {
        if (!loader.loaded) {
            closeAllPopupsExcept(loader);
            loader.loaded = true;
            Qt.callLater(() => {
                if (loader.item) {
                    if (targetXVal !== undefined && "targetX" in loader.item) loader.item.targetX = targetXVal;
                    loader.item.active = true;
                }
                updateCenterPopupWidth();
            });
        } else if (loader.item) {
            if (targetXVal !== undefined && "targetX" in loader.item) loader.item.targetX = targetXVal;
            var nextState = !loader.item.active;
            if (nextState) closeAllPopupsExcept(loader);
            loader.item.active = nextState;
            updateCenterPopupWidth();
        }
    }

    function stopLoaderTimerAndActivate(loader, targetXVal) {
        closeAllPopupsExcept(loader);
        if (!loader.loaded) {
            loader.loaded = true;
            Qt.callLater(() => {
                if (loader.item) {
                    if (targetXVal !== undefined && "targetX" in loader.item) loader.item.targetX = targetXVal;
                    if (loader.item.closeTimer && typeof loader.item.closeTimer.stop === "function") loader.item.closeTimer.stop();
                    loader.item.active = true;
                }
                updateCenterPopupWidth();
            });
        } else if (loader.item) {
            if (targetXVal !== undefined && "targetX" in loader.item) loader.item.targetX = targetXVal;
            if (loader.item.closeTimer && typeof loader.item.closeTimer.stop === "function") loader.item.closeTimer.stop();
            loader.item.active = true;
            updateCenterPopupWidth();
        }
    }

    function restartLoaderTimer(loader) {
        if (loader.loaded && loader.item && loader.item.closeTimer && typeof loader.item.closeTimer.restart === "function") {
            loader.item.closeTimer.restart();
        }
    }

    function setLoaderInactive(loader) {
        if (loader.loaded && loader.item) {
            loader.item.active = false;
            updateCenterPopupWidth();
        }
    }

    property list<QtObject> elements: [
        AutoUnloadLoader {
            id: overviewLoader
            loaded: true
            autoUnloadEnabled: false
            sourceComponent: Overview {
                theme: popupManager.theme
                appService: popupManager.appService
            }
        },
        AutoUnloadLoader {
            id: mediaLoader
            onItemInitialized: item => { item.mediaService = popupManager.mediaService; }
            sourceComponent: MediaPopup { theme: popupManager.theme; mediaService: popupManager.mediaService }
        },
        AutoUnloadLoader {
            id: notifsLoader
            onItemInitialized: item => { item.activeChanged.connect(() => { popupManager.updateCenterPopupWidth(); }); }
            sourceComponent: NotificationCenter { theme: popupManager.theme }
        },
        AutoUnloadLoader {
            id: calendarLoader
            onItemInitialized: item => { item.activeChanged.connect(() => { popupManager.updateCenterPopupWidth(); }); }
            sourceComponent: CalendarPopup { theme: popupManager.theme }
        },
        AutoUnloadLoader {
            id: wifiLoader
            sourceComponent: WifiPopup { theme: popupManager.theme }
        },
        AutoUnloadLoader {
            id: resourcesLoader
            sourceComponent: SystemResourcesPopup { theme: popupManager.theme; statusBar: popupManager.statusBar }
        },
        AutoUnloadLoader {
            id: emojiLoader
            onItemInitialized: item => { item.activeChanged.connect(() => { popupManager.updateCenterPopupWidth(); }); }
            sourceComponent: EmojiPicker { theme: popupManager.theme }
        },
        AutoUnloadLoader {
            id: clipboardLoader
            onItemInitialized: item => { item.activeChanged.connect(() => { popupManager.updateCenterPopupWidth(); }); }
            sourceComponent: ClipboardManager { theme: popupManager.theme; clipService: popupManager.clipboardService }
        },
        AutoUnloadLoader {
            id: wallpaperSelectorLoader
            sourceComponent: WallpaperSelector { theme: popupManager.theme }
        },
        AutoUnloadLoader {
            id: dashboardLoader
            onItemInitialized: item => { item.activeChanged.connect(() => { popupManager.updateCenterPopupWidth(); }); }
            sourceComponent: AppLauncher {
                theme: popupManager.theme
                appService: popupManager.appService
            }
        },
        AutoUnloadLoader {
            id: powerMenuLoader
            sourceComponent: PowerMenuPopup { theme: popupManager.theme; statusBar: popupManager.statusBar }
        },
        AltTab {
            id: altTab
            theme: popupManager.theme
        },
        ErrorPopup { id: errorPopup; theme: popupManager.theme },
        TrayMenuPopup { id: trayMenuPopup; theme: popupManager.theme },
        ConfirmationModal { id: confirmationModal; theme: popupManager.theme }
    ]
}
