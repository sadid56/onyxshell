import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../components/containers"
import "../../components/ui" as UI
import "./components" as SettingsUI
import "./pages" as SettingsPages

Popup {
    id: settingsWindow

    popupWidth: 980
    popupHeight: 640
    showCorners: false
    flatBottom: false
    closeOnHoverOutside: false
    contentMargin: 12

    contentRectX: Math.round((safeWidth - popupWidth) / 2)
    contentRectY: active ? Math.round((Screen.height - popupHeight) / 2) : Math.round((Screen.height - popupHeight) / 2 - 20)

    property var settingsService: null
    property var appService: null

    Item {
        focus: settingsWindow.active
        Keys.onEscapePressed: {
            settingsWindow.active = false;
        }
    }

    Rectangle {
        id: closeBtn
        parent: settingsWindow.contentRect
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 14
        width: 32
        height: 32
        radius: width / 2
        z: 9999

        color: settingsWindow.theme ? Qt.alpha(settingsWindow.theme.getColor("surfaceVariant"), 0.5) : "#222129"

        UI.Icon {
            anchors.centerIn: parent
            icon: "actions/dismiss.svg"
            size: 14
            color: settingsWindow.theme ? settingsWindow.theme.getColor("onSurface") : "#ffffff"
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: settingsWindow.active = false
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        SettingsUI.SettingsSidebar {
            id: sidebar
            theme: settingsWindow.theme
            Layout.preferredWidth: 200
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: settingsWindow.theme ? settingsWindow.theme.getColor("outlineVariant") + "20" : "#ffffff15"
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StackLayout {
                id: pagesStack
                anchors.fill: parent
                anchors.margins: 20
                currentIndex: sidebar.selectedIndex

                Loader {
                    id: appearancePageLoader
                    active: sidebar.selectedIndex === 0 || appearancePageLoader.item !== null
                    sourceComponent: SettingsPages.PageAppearance {
                        theme: settingsWindow.theme
                        settingsService: settingsWindow.settingsService
                    }
                }

                Loader {
                    id: dockPageLoader
                    active: sidebar.selectedIndex === 1 || dockPageLoader.item !== null
                    sourceComponent: SettingsPages.PageDock {
                        theme: settingsWindow.theme
                        settingsService: settingsWindow.settingsService
                        appService: settingsWindow.appService
                    }
                }

                Loader {
                    id: fontsPageLoader
                    active: sidebar.selectedIndex === 2 || fontsPageLoader.item !== null
                    sourceComponent: SettingsPages.PageFonts {
                        theme: settingsWindow.theme
                        settingsService: settingsWindow.settingsService
                    }
                }

                Loader {
                    id: hyprlandPageLoader
                    active: sidebar.selectedIndex === 3 || hyprlandPageLoader.item !== null
                    sourceComponent: SettingsPages.PageHyprland {
                        theme: settingsWindow.theme
                        settingsService: settingsWindow.settingsService
                    }
                }

                Loader {
                    id: keybindsPageLoader
                    active: sidebar.selectedIndex === 4 || keybindsPageLoader.item !== null
                    sourceComponent: SettingsPages.PageKeybinds {
                        theme: settingsWindow.theme
                        settingsService: settingsWindow.settingsService
                    }
                }

                Loader {
                    id: notificationsPageLoader
                    active: sidebar.selectedIndex === 5 || notificationsPageLoader.item !== null
                    sourceComponent: SettingsPages.PageNotifications {
                        theme: settingsWindow.theme
                        settingsService: settingsWindow.settingsService
                    }
                }

                Loader {
                    id: displayPageLoader
                    active: sidebar.selectedIndex === 6 || displayPageLoader.item !== null
                    sourceComponent: SettingsPages.PageDisplay {
                        theme: settingsWindow.theme
                        settingsService: settingsWindow.settingsService
                    }
                }

                Loader {
                    id: systemPageLoader
                    active: sidebar.selectedIndex === 7 || systemPageLoader.item !== null
                    sourceComponent: SettingsPages.PageSystem {
                        theme: settingsWindow.theme
                        settingsService: settingsWindow.settingsService
                    }
                }
            }
        }
    }
}
