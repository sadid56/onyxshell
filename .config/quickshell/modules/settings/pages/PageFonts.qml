import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../components" as SettingsUI
import "../../../components/ui" as UI

Item {
    id: pageRoot

    property var theme
    property var settingsService

    property var installedFonts: []
    property string playgroundText: "The quick brown fox jumps over the lazy dog"

    Process {
        id: fontsProc
        command: ["python", (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getScript("list_fonts.py")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(this.text.trim());
                        if (Array.isArray(parsed)) {
                            pageRoot.installedFonts = parsed;
                        }
                    } catch (e) {}
                }
            }
        }
    }

    function selectFont(fontFamily) {
        if (pageRoot.settingsService && fontFamily) {
            pageRoot.settingsService.applyFont(fontFamily, pageRoot.settingsService.fontSize);
            var pMgr = (typeof popupManager !== "undefined" && popupManager) ? popupManager : ((typeof root !== "undefined" && root.popupManager) ? root.popupManager : null);
            if (pMgr && typeof pMgr.showNotification === "function") {
                pMgr.showNotification({
                    appName: "Fonts",
                    summary: "Font Applied",
                    body: "System font updated to " + fontFamily,
                    appIcon: "system/keyboard.svg"
                });
            }
        }
    }

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
                    icon: "system/font.svg"
                    color: pageRoot.theme.getColor("primary")
                }
            }

            UI.Typography {
                Layout.fillWidth: true
                theme: pageRoot.theme
                text: "Fonts & Typography"
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
                    title: "Live Typography Preview"

                    ColumnLayout {
                        width: parent.width
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            UI.Typography {
                                Layout.fillWidth: true
                                theme: pageRoot.theme
                                text: (pageRoot.settingsService && pageRoot.settingsService.fontFamily)
                                    ? pageRoot.settingsService.fontFamily
                                    : pageRoot.theme.fontFamily
                                variant: "titleLarge"
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                implicitWidth: fontBadge.implicitWidth + 14
                                height: 22
                                radius: 6
                                color: pageRoot.theme.getColor("surfaceVariant")

                                UI.Typography {
                                    id: fontBadge
                                    anchors.centerIn: parent
                                    theme: pageRoot.theme
                                    text: (pageRoot.settingsService && pageRoot.settingsService.fontSize)
                                        ? (pageRoot.settingsService.fontSize + " pt")
                                        : "12 pt"
                                    variant: "labelSmall"
                                    font.weight: Font.Medium
                                    colorRole: "onSurfaceVariant"
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: pageRoot.theme.getColor("outlineVariant") + "20"
                        }

                        UI.Typography {
                            Layout.fillWidth: true
                            theme: pageRoot.theme
                            text: pageRoot.playgroundText
                            variant: "bodyLarge"
                            wrapMode: Text.WordWrap
                        }

                        UI.Typography {
                            Layout.fillWidth: true
                            theme: pageRoot.theme
                            text: "1234567890 • !@#$%^&*() • Beautiful typography made for Quickshell"
                            variant: "bodySmall"
                            colorRole: "onSurfaceVariant"
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                SettingsUI.SettingsCard {
                    theme: pageRoot.theme
                    title: "Font Selection"

                    SettingsUI.SettingsRow {
                        theme: pageRoot.theme
                        title: "Font Family"
                        icon: "system/font.svg"

                        UI.Dropdown {
                            id: fontDropdown
                            theme: pageRoot.theme
                            implicitWidth: 240
                            searchable: true
                            searchPlaceholder: "Search fonts..."
                            showFontPreview: false
                            placeholder: "Select Font"
                            model: pageRoot.installedFonts
                            currentValue: (pageRoot.settingsService && pageRoot.settingsService.fontFamily)
                                ? pageRoot.settingsService.fontFamily
                                : pageRoot.theme.fontFamily

                            onActivated: (idx, val, txt) => {
                                if (val) pageRoot.selectFont(val);
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
                        title: "Font Size"
                        icon: "system/text-size.svg"

                        UI.Slider {
                            theme: pageRoot.theme
                            implicitWidth: 160
                            min: 8
                            max: 18
                            value: (pageRoot.settingsService && pageRoot.settingsService.fontSize) ? pageRoot.settingsService.fontSize : 12
                            onMoved: val => {
                                if (pageRoot.settingsService) {
                                    pageRoot.settingsService.fontSize = val;
                                    pageRoot.settingsService.applyFont(pageRoot.settingsService.fontFamily, val);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
