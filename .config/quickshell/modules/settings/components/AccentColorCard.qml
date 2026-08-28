import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components" as SettingsUI
import "../../../components/ui" as UI

SettingsUI.SettingsCard {
    id: accentCard

    property var settingsService

    title: "Accent Color"

    Process {
        id: hyprpickerProc
        command: ["hyprpicker", "-a", "-f", "hex"]
        stdout: StdioCollector {
            onStreamFinished: {
                var hex = this.text ? this.text.trim() : "";
                if (hex && (hex.startsWith("#") || hex.length === 6)) {
                    if (!hex.startsWith("#")) hex = "#" + hex;
                    if (accentCard.settingsService) {
                        accentCard.settingsService.applyAccentColor(hex);
                    }
                }
            }
        }
    }

    SettingsUI.SettingsRow {
        theme: accentCard.theme
        title: "Pick from Wallpaper"
        subtitle: "Generate dynamic Material You palette from active wallpaper"
        icon: "actions/image.svg"

        UI.Button {
            theme: accentCard.theme
            text: (accentCard.settingsService && accentCard.settingsService.accentColor === "auto")
                ? "✓ Active (Wallpaper)"
                : "Pick from Wallpaper"
            icon: "actions/image.svg"
            active: accentCard.settingsService ? (accentCard.settingsService.accentColor === "auto") : true
            onClicked: {
                if (accentCard.settingsService) {
                    accentCard.settingsService.applyAccentColor("auto");
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: accentCard.theme ? (accentCard.theme.getColor("outlineVariant") + "20") : "#ffffff15"
    }

    SettingsUI.SettingsRow {
        theme: accentCard.theme
        title: "Preset Swatches"
        subtitle: "Curated Material You accent color palettes"
        icon: "system/palette.svg"

        SettingsUI.ColorSwatchPicker {
            theme: accentCard.theme
            selectedColor: accentCard.settingsService ? accentCard.settingsService.accentColor : "auto"
            onColorSelected: hex => {
                if (accentCard.settingsService) {
                    accentCard.settingsService.applyAccentColor(hex);
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: accentCard.theme ? (accentCard.theme.getColor("outlineVariant") + "20") : "#ffffff15"
    }

    SettingsUI.SettingsRow {
        theme: accentCard.theme
        title: "Custom Color & Eyedropper"
        subtitle: "Pick any color from screen or enter custom hex"
        icon: "actions/eyedropper-filled.svg"

        RowLayout {
            spacing: 8

            UI.Button {
                theme: accentCard.theme
                text: "Pick from Screen"
                icon: "actions/eyedropper-filled.svg"
                onClicked: {
                    if (hyprpickerProc.running) {
                        hyprpickerProc.running = false;
                    }
                    hyprpickerProc.running = true;
                }
            }

            Rectangle {
                id: hexInputBox
                width: 125
                height: 32
                radius: 8
                color: accentCard.theme ? (accentCard.theme.getColor("surfaceVariant") + "50") : "#302f38"
                border.width: 1
                border.color: accentCard.theme ? (accentCard.theme.getColor("outlineVariant") + "30") : "#404040"

                readonly property bool isCustomActive: accentCard.settingsService && accentCard.settingsService.accentColor && accentCard.settingsService.accentColor !== "auto"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        customHexInput.forceActiveFocus();
                        customHexInput.selectAll();
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: {
                            var txt = customHexInput.text.trim();
                            if (txt.startsWith("#") && (txt.length === 7 || txt.length === 4)) return txt;
                            if (txt.length === 6) return "#" + txt;
                            return accentCard.theme ? accentCard.theme.getColor("primary") : "#c5c5d8";
                        }
                        border.width: 1
                        border.color: "#ffffff33"
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: customHexInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: accentCard.theme ? accentCard.theme.getColor("onSurface") : "#ffffff"
                            selectByMouse: true

                            readonly property string currentSystemColor: accentCard.theme ? accentCard.theme.getColor("primary") : "#c5c5d8"

                            Binding on text {
                                when: !customHexInput.activeFocus
                                value: customHexInput.currentSystemColor
                            }

                            onActiveFocusChanged: {
                                if (activeFocus) selectAll();
                            }

                            onTextEdited: {
                                var val = text.trim();
                                if (val.length === 6 && !val.startsWith("#")) val = "#" + val;
                                if (val.startsWith("#") && (val.length === 7 || val.length === 4)) {
                                    if (accentCard.settingsService) {
                                        accentCard.settingsService.applyAccentColor(val);
                                    }
                                }
                            }

                            onAccepted: {
                                var val = text.trim();
                                if (val.length === 6 && !val.startsWith("#")) val = "#" + val;
                                if (val.startsWith("#") && (val.length === 7 || val.length === 4)) {
                                    if (accentCard.settingsService) {
                                        accentCard.settingsService.applyAccentColor(val);
                                    }
                                }
                                customHexInput.focus = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
