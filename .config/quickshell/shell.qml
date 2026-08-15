import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "components"
import "services"

QtObject {
    id: root

    property var activeNotifs: []

    property list<QtObject> shellObjects: [
        // Theme Service
        Theme {
            id: rootTheme
        },

        // System Monitor Stats Service
        SysStats {
            id: sysStats
        },

        // Clipboard History Service
        CliphistService {
            id: clipService
        },

        // Status Bar Instance
        StatusBar {
            id: statusBar
            theme: rootTheme
            sysStats: sysStats
            notifCount: notifs.notifCount
            // Pass callbacks
            toggleLauncher: () => { launcher.active = !launcher.active; }
            toggleNotifications: () => {
                notifs.targetX = statusBar.getNotifX();
                notifs.active = !notifs.active;
            }
            toggleCalendar: () => {
                calendarPopup.targetX = statusBar.getClockX();
                calendarPopup.active = !calendarPopup.active;
            }
            toggleWifi: () => {
                wifiPopup.targetX = statusBar.getWifiX();
                wifiPopup.active = !wifiPopup.active;
            }
        },

        ScreenCorners {
            id: screenCorners
            radius: 16
            color: rootTheme.getColor("surface")
        },

        // App Launcher Panel
        AppLauncher {
            id: launcher
            theme: rootTheme
        },

        // Notifications Center Overlay (Merged with Settings)
        NotificationCenter {
            id: notifs
            theme: rootTheme
            activeNotifs: root.activeNotifs
        },

        // Control Center Panel (Merged into Notification Center)
        // ControlCenter {
        //     id: controlCenter
        //     theme: rootTheme
        // },

        // Notification HUD Toast Popup Window
        NotificationPopup {
            id: toastPopup
            theme: rootTheme
        },

        // Notification Server to handle incoming D-Bus system notifications
        NotificationServer {
            id: notifServer
            bodySupported: true
            actionsSupported: true
            imageSupported: true
            onNotification: notification => {
                notification.tracked = true;
                
                // Add to reactive array using slice() to enforce new reference
                var arr = root.activeNotifs.slice();
                arr.push(notification);
                root.activeNotifs = arr;
                
                // Trigger Toast HUD popup!
                toastPopup.showToast(notification);

                // Remove from array when closed/dismissed
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

        // Calendar Dialog Popup
        CalendarPopup {
            id: calendarPopup
            theme: rootTheme
        },

        // Wifi Manager Popup
        WifiPopup {
            id: wifiPopup
            theme: rootTheme
        },

        // Clipboard Manager Dialog
        ClipboardManager {
            id: clipboard
            theme: rootTheme
            clipService: clipService
        },

        // Wallpaper Selector Popup
        WallpaperSelector {
            id: wallpaperSelector
            theme: rootTheme
        },

        // Keybinds Cheat Sheet Popup
        KeybindsPopup {
            id: keybindsPopup
            theme: rootTheme
        },

        // External IPC commands interface
        IpcHandler {
            target: "shell"

            function toggleLauncher(): void {
                launcher.active = !launcher.active;
            }

            function toggleNotifications(): void {
                notifs.active = !notifs.active;
            }


            function toggleClipboard(): void {
                clipboard.active = !clipboard.active;
            }

            function toggleWallpaperSelector(): void {
                wallpaperSelector.active = !wallpaperSelector.active;
            }

            function toggleBar(): void {
                statusBar.visible = !statusBar.visible;
            }

            function toggleKeybinds(): void {
                keybindsPopup.active = !keybindsPopup.active;
            }

            function reloadTheme(): void {
                rootTheme.reloadColors();
            }
        }
    ]
}
