import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components" as SettingsUI
import "../../../components/ui" as UI

Item {
    id: pageRoot

    property var theme
    property var settingsService
    property var appService: (typeof root !== "undefined" && root.appService) ? root.appService : null
    property var allApps: (appService && appService.apps && appService.apps.length > 0) ? appService.apps : []

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 42
            spacing: 12

            Rectangle {
                width: 36
                height: 36
                radius: 10
                color: pageRoot.theme.getColor("surfaceVariant")

                UI.Icon {
                    anchors.centerIn: parent
                    size: 20
                    icon: "system/app-window.svg"
                    color: pageRoot.theme.getColor("primary")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                UI.Typography {
                    theme: pageRoot.theme
                    text: "Dock & Applications"
                    variant: "titleMedium"
                }
                UI.Typography {
                    theme: pageRoot.theme
                    text: "Configure bottom smart dock, live previews, sizing, and pinned applications"
                    variant: "bodySmall"
                    colorRole: "onSurfaceVariant"
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentLayout.implicitHeight + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 14

                SettingsUI.SettingsCard {
                    theme: pageRoot.theme
                    title: "General Dock Settings"

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Enable Bottom Smart Dock"
                        subtitle: "Unload dock from memory when disabled to save 100% resources"
                        icon: "system/app-window.svg"

                        UI.Switch {
                            theme: pageRoot.theme
                            checked: pageRoot.settingsService ? pageRoot.settingsService.dockEnabled : true
                            onToggled: function(val) {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.dockEnabled = val;
                                    pageRoot.settingsService.saveSettings();
                                }
                            }
                        }
                    }

                    UI.Divider {
                        theme: pageRoot.theme
                        Layout.fillWidth: true
                        horizontal: true
                    }

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Live Window Previews"
                        subtitle: "Show real-time window stream card on icon hover"
                        icon: "system/monitor.svg"

                        UI.Switch {
                            theme: pageRoot.theme
                            checked: pageRoot.settingsService ? pageRoot.settingsService.dockLivePreview : true
                            onToggled: function(val) {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.dockLivePreview = val;
                                    pageRoot.settingsService.saveSettings();
                                }
                            }
                        }
                    }

                    UI.Divider {
                        theme: pageRoot.theme
                        Layout.fillWidth: true
                        horizontal: true
                    }

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Auto-Show On Empty Workspace"
                        subtitle: "Show dock automatically when no windows are open in active workspace"
                        icon: "system/zap.svg"

                        UI.Switch {
                            theme: pageRoot.theme
                            checked: pageRoot.settingsService ? pageRoot.settingsService.dockAutoShowEmpty : true
                            onToggled: function(val) {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.dockAutoShowEmpty = val;
                                    pageRoot.settingsService.saveSettings();
                                }
                            }
                        }
                    }
                }

                SettingsUI.SettingsCard {
                    theme: pageRoot.theme
                    title: "Dock Dimensions & Spacing"

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Dock Icon Size"
                        subtitle: "Adjust the size of application icons in the dock"
                        icon: "actions/crop.svg"

                        UI.Slider {
                            theme: pageRoot.theme
                            implicitWidth: 160
                            min: 20
                            max: 44
                            value: (pageRoot.settingsService && pageRoot.settingsService.dockIconSize) ? pageRoot.settingsService.dockIconSize : 28
                            onMoved: val => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.dockIconSize = val;
                                    pageRoot.settingsService.saveSettings();
                                }
                            }
                        }
                    }

                    UI.Divider {
                        theme: pageRoot.theme
                        Layout.fillWidth: true
                        horizontal: true
                    }

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Item Spacing & Padding"
                        subtitle: "Gap between app icons in the dock"
                        icon: "system/layout.svg"

                        UI.Slider {
                            theme: pageRoot.theme
                            implicitWidth: 160
                            min: 2
                            max: 16
                            value: (pageRoot.settingsService && pageRoot.settingsService.dockSpacing !== undefined) ? pageRoot.settingsService.dockSpacing : 6
                            onMoved: val => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.dockSpacing = val;
                                    pageRoot.settingsService.saveSettings();
                                }
                            }
                        }
                    }
                }

                SettingsUI.DockPinnedAppsCard {
                    theme: pageRoot.theme
                    settingsService: pageRoot.settingsService
                    appService: pageRoot.appService
                    allApps: pageRoot.allApps
                }
            }
        }
    }
}
