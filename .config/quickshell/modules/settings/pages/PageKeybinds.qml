import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components" as SettingsUI
import "../../../components/ui" as UI

Item {
    id: pageRoot

    property var theme
    property var settingsService

    readonly property var keybindGroups: [
        {
            category: "General & Window Management",
            items: [
                { mod: "SUPER + C", desc: "Close focused window" },
                { mod: "SUPER + M", desc: "Open Power Menu" },
                { mod: "SUPER + Q", desc: "Toggle Dropdown Terminal" },
                { mod: "SUPER + E", desc: "Launch File Manager" },
                { mod: "SUPER + SPACE", desc: "Toggle window floating mode" },
                { mod: "SUPER + J", desc: "Toggle split layout" },
                { mod: "SUPER + P", desc: "Pin window to all workspaces" },
                { mod: "SUPER + F", desc: "Toggle fullscreen" }
            ]
        },
        {
            category: "Applications & Launchers",
            items: [
                { mod: "SUPER + RETURN", desc: "Launch Terminal" },
                { mod: "ALT + SPACE", desc: "Open Application Launcher" },
                { mod: "SUPER + B", desc: "Launch Web Browser" },
                { mod: "SUPER + PERIOD", desc: "Open Emoji Picker" },
                { mod: "SUPER + V", desc: "Open Clipboard History" }
            ]
        },
        {
            category: "Workspace & Special Scratchpad",
            items: [
                { mod: "SUPER + 1..9", desc: "Switch to workspace 1-9" },
                { mod: "SUPER + SHIFT + 1..9", desc: "Move window to workspace 1-9" },
                { mod: "SUPER + S", desc: "Toggle Special Workspace (Scratchpad)" },
                { mod: "SUPER + CTRL + S", desc: "Move window to Special Workspace" },
                { mod: "SUPER + CTRL + Y", desc: "Move window out of Special Workspace" },
                { mod: "SUPER + LEFT/RIGHT", desc: "Focus window in direction" },
                { mod: "SUPER + SHIFT + LEFT/RIGHT", desc: "Move active window in direction" }
            ]
        },
        {
            category: "Screenshots & Media",
            items: [
                { mod: "PRINT", desc: "Capture full screen screenshot" },
                { mod: "SUPER + SHIFT + S", desc: "Interactive area screenshot" },
                { mod: "XF86AudioRaiseVolume", desc: "Increase audio volume" },
                { mod: "XF86AudioLowerVolume", desc: "Decrease audio volume" },
                { mod: "XF86AudioMute", desc: "Toggle audio mute" },
                { mod: "XF86MonBrightnessUp", desc: "Increase display brightness" },
                { mod: "XF86MonBrightnessDown", desc: "Decrease display brightness" }
            ]
        }
    ]

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
                    icon: "system/keyboard.svg"
                    color: pageRoot.theme.getColor("primary")
                }
            }

            UI.Typography {
                Layout.fillWidth: true
                theme: pageRoot.theme
                text: "Hyprland Keybindings"
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

                Repeater {
                    model: pageRoot.keybindGroups

                    SettingsUI.SettingsCard {
                        id: groupCard
                        theme: pageRoot.theme
                        title: modelData.category

                        readonly property var currentGroupItems: modelData.items

                        Repeater {
                            model: groupCard.currentGroupItems

                            Column {
                                width: parent ? parent.width : 400
                                spacing: 8

                                SettingsUI.SettingsRow {
                                    theme: pageRoot.theme
                                    title: modelData.desc
                                    icon: "system/keyboard.svg"

                                    Row {
                                        spacing: 4
                                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                                        Repeater {
                                            model: modelData.mod.split(" + ")
                                            Rectangle {
                                                implicitWidth: keyCapText.implicitWidth + 14
                                                height: 24
                                                radius: 7
                                                color: pageRoot.theme ? pageRoot.theme.getColor("secondaryContainer") : "#363442"
                                                border.width: 0

                                                UI.Typography {
                                                    id: keyCapText
                                                    theme: pageRoot.theme
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    mono: true
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    colorRole: "onSecondaryContainer"
                                                }
                                            }
                                        }
                                    }
                                }

                                UI.Divider {
                                    theme: pageRoot.theme
                                    horizontal: true
                                    width: parent.width
                                    visible: index < (groupCard.currentGroupItems.length - 1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
