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

        function toggleDashboard(): void {
            if (ipcServiceRoot.popupManager) {
                var distroX = ipcServiceRoot.statusBar ? ipcServiceRoot.statusBar.getDistroX() : undefined;
                ipcServiceRoot.popupManager.toggleLoaderActive(ipcServiceRoot.popupManager.dashboardLoader, distroX);
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

        function toggleKeybinds(): void {
            if (ipcServiceRoot.popupManager) {
                ipcServiceRoot.popupManager.toggleLoaderActive(ipcServiceRoot.popupManager.keybindsLoader);
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
    }
}
