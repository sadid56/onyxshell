import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: ipcServiceRoot

    property var popupManager: null
    property var statusBar: null
    property var theme: null

    property var handler: IpcHandler {
        target: "shell"

        function toggleLauncher(): void {
            toggleDashboard();
        }

        function toggleOverview(): void {
            if (ipcServiceRoot.popupManager) {
                var loader = ipcServiceRoot.popupManager.overviewLoader;
                if (!loader.loaded) {
                    ipcServiceRoot.popupManager.closeAllPopupsExcept(loader);
                    loader.loaded = true;
                    Qt.callLater(() => {
                        if (loader.item) {
                            loader.item.showAllWorkspaces = false;
                            loader.item.active = true;
                        }
                    });
                } else if (loader.item) {
                    if (loader.item.active && !loader.item.showAllWorkspaces) {
                        loader.item.active = false;
                    } else {
                        ipcServiceRoot.popupManager.closeAllPopupsExcept(loader);
                        loader.item.showAllWorkspaces = false;
                        loader.item.active = true;
                    }
                }
            }
        }

        function toggleOverviewAll(): void {
            if (ipcServiceRoot.popupManager) {
                var loader = ipcServiceRoot.popupManager.overviewLoader;
                if (!loader.loaded) {
                    ipcServiceRoot.popupManager.closeAllPopupsExcept(loader);
                    loader.loaded = true;
                    Qt.callLater(() => {
                        if (loader.item) {
                            loader.item.showAllWorkspaces = true;
                            loader.item.active = true;
                        }
                    });
                } else if (loader.item) {
                    if (loader.item.active && loader.item.showAllWorkspaces) {
                        loader.item.active = false;
                    } else {
                        ipcServiceRoot.popupManager.closeAllPopupsExcept(loader);
                        loader.item.showAllWorkspaces = true;
                        loader.item.active = true;
                    }
                }
            }
        }

        function toggleDashboard(): void {
            if (ipcServiceRoot.popupManager) {
                ipcServiceRoot.popupManager.toggleLoaderActive(ipcServiceRoot.popupManager.dashboardLoader);
            }
        }

        function toggleMedia(): void {
            if (ipcServiceRoot.popupManager) {
                var mediaX = ipcServiceRoot.statusBar ? ipcServiceRoot.statusBar.getMediaX() : undefined;
                ipcServiceRoot.popupManager.toggleLoaderActive(ipcServiceRoot.popupManager.mediaLoader, mediaX);
            }
        }

        function toggleNotifications(): void {
            if (ipcServiceRoot.popupManager) {
                ipcServiceRoot.popupManager.toggleLoaderActive(ipcServiceRoot.popupManager.notifsLoader);
            }
        }

        function toggleClipboard(): void {
            if (ipcServiceRoot.popupManager) {
                ipcServiceRoot.popupManager.toggleLoaderActive(ipcServiceRoot.popupManager.clipboardLoader);
            }
        }

        function toggleEmoji(): void {
            if (ipcServiceRoot.popupManager) {
                ipcServiceRoot.popupManager.toggleLoaderActive(ipcServiceRoot.popupManager.emojiLoader);
            }
        }

        function toggleWallpaperSelector(): void {
            if (ipcServiceRoot.popupManager) {
                ipcServiceRoot.popupManager.toggleLoaderActive(ipcServiceRoot.popupManager.wallpaperSelectorLoader);
            }
        }

        function toggleBar(): void {
            if (ipcServiceRoot.statusBar) {
                ipcServiceRoot.statusBar.visible = !ipcServiceRoot.statusBar.visible;
            }
        }

        function toggleSettings(): void {
            if (ipcServiceRoot.popupManager) {
                ipcServiceRoot.popupManager.toggleLoaderActive(ipcServiceRoot.popupManager.settingsLoader);
            }
        }

        function togglePowerMenu(): void {
            if (ipcServiceRoot.popupManager) {
                ipcServiceRoot.popupManager.toggleLoaderActive(ipcServiceRoot.popupManager.powerMenuLoader);
            }
        }

        function toggleAltTab(): void {
            if (ipcServiceRoot.popupManager) {
                ipcServiceRoot.popupManager.toggleAltTab();
            }
        }

        function closeAltTab(): void {
            if (ipcServiceRoot.popupManager && ipcServiceRoot.popupManager.altTabLoader && ipcServiceRoot.popupManager.altTabLoader.item) {
                ipcServiceRoot.popupManager.altTabLoader.item.selectAndClose();
            }
        }

        function reloadTheme(): void {
            if (ipcServiceRoot.theme && typeof ipcServiceRoot.theme.reloadColors === "function") {
                ipcServiceRoot.theme.reloadColors();
            }
        }

        function confirmShutdown(): void {
            if (ipcServiceRoot.popupManager && ipcServiceRoot.popupManager.confirmationModal) {
                ipcServiceRoot.popupManager.closeAllPopupsExcept(null);
                ipcServiceRoot.popupManager.confirmationModal.ask({
                    title: "Power Off",
                    message: "Are you sure you want to power off the system?",
                    icon: "system/power.svg",
                    confirmText: "Power Off",
                    cancelText: "Cancel",
                    isDanger: true,
                    onConfirm: () => {
                        var home = Quickshell.env("HOME") || "/home";
                        Quickshell.execDetached(["bash", home + "/.config/hypr/scripts/shutdown.sh"]);
                    }
                });
            }
        }
    }
}
