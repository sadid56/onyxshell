import QtQuick
import Quickshell
import Quickshell.Io

IpcHandler {
    id: ipcHandler
    target: "shell"

    property var popupManager: null
    property var statusBar: null
    property var theme: null

    function toggleLauncher(): void {
        if (popupManager) {
            popupManager.toggleLoaderActive(popupManager.launcherLoader);
        }
    }

    function toggleMedia(): void {
        if (popupManager) {
            var mediaX = statusBar ? statusBar.getMediaX() : undefined;
            popupManager.toggleLoaderActive(popupManager.mediaLoader, mediaX);
        }
    }

    function toggleNotifications(): void {
        if (popupManager) {
            popupManager.toggleLoaderActive(popupManager.notifsLoader);
        }
    }

    function toggleClipboard(): void {
        if (popupManager) {
            popupManager.toggleLoaderActive(popupManager.clipboardLoader);
        }
    }

    function toggleWallpaperSelector(): void {
        if (popupManager) {
            popupManager.toggleLoaderActive(popupManager.wallpaperSelectorLoader);
        }
    }

    function toggleBar(): void {
        if (statusBar) {
            statusBar.visible = !statusBar.visible;
        }
    }

    function toggleKeybinds(): void {
        if (popupManager) {
            popupManager.toggleLoaderActive(popupManager.keybindsLoader);
        }
    }

    function reloadTheme(): void {
        if (theme && typeof theme.reloadColors === "function") {
            theme.reloadColors();
        }
    }
}
