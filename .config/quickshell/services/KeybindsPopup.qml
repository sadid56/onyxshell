import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../modules/launcher/components"
import "../components/ui" as UIInputs

PanelWindow {
    id: keybindsWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    property var theme
    property bool active: false
    property string searchQuery: ""
    property var allKeybinds: []

    visible: active || hideTimer.running

    onActiveChanged: {
        if (active) {
            searchInput.forceFocus();
            refreshKeybinds();
        } else {
            searchInput.text = "";
            searchQuery = "";
            hideTimer.start();
        }
    }

    onVisibleChanged: {
        if (visible && active) {
            refreshKeybinds();
        }
    }

    Timer {
        id: hideTimer
        interval: 250
        running: false
        repeat: false
    }

    function refreshKeybinds() {
        keybindsProc.running = false;
        keybindsProc.running = true;
    }

    function getFilteredKeybinds() {
        if (searchQuery === "") return allKeybinds;
        var arr = [];
        var query = searchQuery.toLowerCase();
        for (var i = 0; i < allKeybinds.length; i++) {
            var kb = allKeybinds[i];
            if (kb.keys.toLowerCase().indexOf(query) !== -1 || 
                kb.action.toLowerCase().indexOf(query) !== -1) {
                arr.push(kb);
            }
        }
        return arr;
    }

    property var keybindsProc: Process {
        id: keybindsProc
        command: ["python", shellConfig.getScript("list_keybinds.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text);
                    if (parsed && parsed.length > 0) {
                        keybindsWindow.allKeybinds = parsed;
                    }
                } catch(e) {
                    console.error("Failed to parse keybinds JSON:", e);
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: keybindsWindow.active
        onActivated: keybindsWindow.active = false
    }

    MouseArea {
        anchors.fill: parent
        onClicked: keybindsWindow.active = false
    }

    Rectangle {
        id: contentRect
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 580
        height: 540
        radius: 20
        color: keybindsWindow.theme.getColor("surface")
        border.width: 1
        border.color: keybindsWindow.theme.colors.outline ? (keybindsWindow.theme.colors.outline + "15") : "#75768015"

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        opacity: keybindsWindow.active ? 1.0 : 0.0
        scale: keybindsWindow.active ? 1.0 : 0.97
        
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        transform: Translate {
            y: keybindsWindow.active ? 0 : -10
            Behavior on y {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Keyboard Shortcuts"
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 18
                    font.bold: true
                    color: keybindsWindow.theme.getColor("onSurface")
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "󰅖"
                    font.family: "Noto Sans"
                    font.pixelSize: 18
                    color: keybindsWindow.theme.getColor("outline")
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: keybindsWindow.active = false
                    }
                }
            }

            UIInputs.Input {
                id: searchInput
                theme: keybindsWindow.theme
                placeholder: "Search keybinds..."
                icon: ""
                Layout.fillWidth: true
                onTextChanged: keybindsWindow.searchQuery = text
                onEscapePressed: keybindsWindow.active = false
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: keybindsWindow.theme.getColor("surfaceVariant")
            }

            ListView {
                id: shortcutsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: keybindsWindow.getFilteredKeybinds()

                delegate: Rectangle {
                    width: shortcutsList.width
                    height: 48
                    radius: 10
                    color: "transparent"

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = keybindsWindow.theme.getColor("surfaceVariant")
                        onExited: parent.color = "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 16

                        Rectangle {
                            Layout.preferredWidth: keysText.implicitWidth + 16
                            Layout.fillHeight: true
                            radius: 8
                            color: keybindsWindow.theme.getColor("surfaceVariant")
                            border.width: 1
                            border.color: keybindsWindow.theme.colors.outline ? (keybindsWindow.theme.colors.outline + "10") : "#75768010"

                            Text {
                                id: keysText
                                anchors.centerIn: parent
                                text: modelData.keys
                                font.family: "Noto Sans"
                                font.pixelSize: 10
                                font.bold: true
                                color: keybindsWindow.theme.getColor("primary")
                            }
                        }

                        Text {
                            text: "󰁔"
                            font.family: "Noto Sans"
                            font.pixelSize: 12
                            color: keybindsWindow.theme.getColor("outline")
                        }

                        Text {
                            text: modelData.action
                            font.family: "Google Sans Flex, sans-serif"
                            font.pixelSize: 12
                            font.bold: true
                            color: keybindsWindow.theme.getColor("onSurface")
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
