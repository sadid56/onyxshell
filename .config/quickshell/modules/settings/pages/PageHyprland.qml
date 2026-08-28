import QtQuick
import QtQuick.Layouts
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
                    icon: "system/layout.svg"
                    color: pageRoot.theme.getColor("primary")
                }
            }

            UI.Typography {
                Layout.fillWidth: true
                theme: pageRoot.theme
                text: "Window Manager & Workspace"
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

                SettingsUI.SettingsCard {
                    theme: pageRoot.theme
                    title: "Window Spacing (Gaps)"

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Inner Gaps (" + (pageRoot.settingsService ? pageRoot.settingsService.gapsIn : 5) + "px)"
                        icon: "system/layout.svg"

                        UI.Slider {
                            theme: pageRoot.theme
                            implicitWidth: 160
                            min: 0
                            max: 20
                            value: pageRoot.settingsService ? pageRoot.settingsService.gapsIn : 5
                            onMoved: val => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.gapsIn = val;
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
                        title: "Outer Gaps (" + (pageRoot.settingsService ? pageRoot.settingsService.gapsOut : 10) + "px)"
                        icon: "system/app-window.svg"

                        UI.Slider {
                            theme: pageRoot.theme
                            implicitWidth: 160
                            min: 0
                            max: 40
                            value: pageRoot.settingsService ? pageRoot.settingsService.gapsOut : 10
                            onMoved: val => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.gapsOut = val;
                                    pageRoot.settingsService.saveSettings();
                                }
                            }
                        }
                    }
                }

                SettingsUI.SettingsCard {
                    theme: pageRoot.theme
                    title: "Tiling & Layout"

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Layout Engine"
                        icon: "system/layout.svg"

                        SettingsUI.SegmentedButton {
                            theme: pageRoot.theme
                            model: [
                                { text: "Dwindle", value: "dwindle" },
                                { text: "Master", value: "master" }
                            ]
                            Component.onCompleted: {
                                if (pageRoot.settingsService) {
                                    selectValue(pageRoot.settingsService.layout);
                                }
                            }
                            onSelected: (idx, val, txt) => {
                                if (pageRoot.settingsService && val) {
                                    pageRoot.settingsService.layout = val;
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
                        title: "Follow Mouse Focus"
                        icon: "system/mouse.svg"

                        UI.Switch {
                            theme: pageRoot.theme
                            checked: pageRoot.settingsService ? pageRoot.settingsService.followMouse : true
                            onToggled: isChecked => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.followMouse = isChecked;
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
