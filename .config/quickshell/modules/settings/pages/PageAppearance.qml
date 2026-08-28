import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components" as SettingsUI
import "../../../components/ui" as UI

Item {
    id: pageRoot

    property var theme
    property var settingsService

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
                    icon: "system/palette.svg"
                    color: pageRoot.theme.getColor("primary")
                }
            }

            UI.Typography {
                Layout.fillWidth: true
                theme: pageRoot.theme
                text: "Appearance & Theme"
                variant: "titleMedium"
                Layout.alignment: Qt.AlignVCenter
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

                SettingsUI.AccentColorCard {
                    theme: pageRoot.theme
                    settingsService: pageRoot.settingsService
                }

                SettingsUI.SettingsCard {
                    theme: pageRoot.theme
                    title: "Window & Surface Styling"

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Corner Radius"
                        icon: "system/corner-radius.svg"

                        UI.Dropdown {
                            theme: pageRoot.theme
                            implicitWidth: 175
                            model: [
                                { text: "0px (Sharp)", value: 0 },
                                { text: "8px (Compact)", value: 8 },
                                { text: "12px (Subtle)", value: 12 },
                                { text: "16px (Standard)", value: 16 },
                                { text: "20px (Curved)", value: 20 },
                                { text: "24px (Round)", value: 24 }
                            ]
                            currentValue: (pageRoot.settingsService && pageRoot.settingsService.cornerRadius !== undefined)
                                ? pageRoot.settingsService.cornerRadius
                                : 16

                            onActivated: (index, val, txt) => {
                                if (pageRoot.settingsService && val !== null && val !== undefined) {
                                    pageRoot.settingsService.cornerRadius = val;
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
                        title: "Border Width"
                        icon: "system/app-window.svg"

                        SettingsUI.SegmentedButton {
                            theme: pageRoot.theme
                            model: [
                                { text: "0px", value: 0 },
                                { text: "1px", value: 1 },
                                { text: "2px", value: 2 },
                                { text: "3px", value: 3 }
                            ]
                            Component.onCompleted: {
                                if (pageRoot.settingsService) {
                                    selectValue(pageRoot.settingsService.borderWidth);
                                }
                            }
                            onSelected: (idx, val, txt) => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.borderWidth = val;
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
                        title: "Active Window Opacity"
                        icon: "system/opacity.svg"

                        UI.Slider {
                            theme: pageRoot.theme
                            implicitWidth: 160
                            min: 50
                            max: 100
                            value: Math.round(((pageRoot.settingsService ? pageRoot.settingsService.activeOpacity : 1.0) || 1.0) * 100)
                            onMoved: val => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.activeOpacity = val / 100.0;
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
                        title: "Inactive Window Opacity"
                        icon: "system/moon.svg"

                        UI.Slider {
                            theme: pageRoot.theme
                            implicitWidth: 160
                            min: 30
                            max: 100
                            value: Math.round(((pageRoot.settingsService ? pageRoot.settingsService.inactiveOpacity : 0.95) || 0.95) * 100)
                            onMoved: val => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.inactiveOpacity = val / 100.0;
                                    pageRoot.settingsService.saveSettings();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
