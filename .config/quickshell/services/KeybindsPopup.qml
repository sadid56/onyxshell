import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import "../components/ui" as UI
import "./components"

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
    property string selectedCategory: "All"
    property var allKeybinds: []
    visible: active || hideTimer.running

    onActiveChanged: {
        if (active) { searchInput.forceFocus(); refreshKeybinds(); }
        else { searchInput.text = ""; searchQuery = ""; selectedCategory = "All"; hideTimer.start(); }
    }

    onVisibleChanged: { if (visible && active) refreshKeybinds(); }

    Timer { id: hideTimer; interval: 250; running: false; repeat: false }

    function refreshKeybinds() {
        keybindsProc.running = false;
        keybindsProc.running = true;
    }

    function getFilteredKeybinds() {
        var arr = [], q = searchQuery.toLowerCase().trim();
        for (var i = 0; i < allKeybinds.length; i++) {
            var kb = allKeybinds[i];
            var matchesCat = (selectedCategory === "All" || kb.category === selectedCategory);
            var matchesQ = (q === "" || kb.keys.toLowerCase().indexOf(q) !== -1 || kb.action.toLowerCase().indexOf(q) !== -1 || (kb.category && kb.category.toLowerCase().indexOf(q) !== -1));
            if (matchesCat && matchesQ) arr.push(kb);
        }
        return arr;
    }

    onSearchQueryChanged: {
        shortcutsList.hoveredIndex = -1;
        updateFilteredModel();
    }
    onSelectedCategoryChanged: {
        shortcutsList.hoveredIndex = -1;
        updateFilteredModel();
    }
    onAllKeybindsChanged: updateFilteredModel()

    function updateFilteredModel() {
        var filtered = getFilteredKeybinds();
        shortcutsList.syncListModel(dynamicKeybindsModel, filtered, "keys", 250);
    }

    ListModel {
        id: dynamicKeybindsModel
    }

    property var keybindsProc: Process {
        id: keybindsProc
        command: ["python", shellConfig.getScript("list_keybinds.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text);
                    if (parsed && parsed.length > 0) keybindsWindow.allKeybinds = parsed;
                } catch(e) {}
            }
        }
    }

    Shortcut { sequence: "Escape"; enabled: keybindsWindow.active; onActivated: keybindsWindow.active = false }
    MouseArea { anchors.fill: parent; onClicked: keybindsWindow.active = false }

    Rectangle {
        id: contentRect
        anchors.centerIn: parent
        width: Math.min(760, parent.width - 48)
        height: Math.min(620, parent.height - 80)
        radius: (root && root.shellConfig) ? root.shellConfig.cornerRadius : 16
        color: keybindsWindow.theme ? keybindsWindow.theme.getColor("surface") : "#1b1b1b"
        border.width: 0
        opacity: keybindsWindow.active ? 1.0 : 0.0
        scale: keybindsWindow.active ? 1.0 : 0.95

        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                RowLayout {
                    spacing: 8
                    IconImage {
                        width: 20; height: 20
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/keyboard.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect { colorization: 1.0; colorizationColor: keybindsWindow.theme ? keybindsWindow.theme.getColor("primary") : "#ffb3b4" }
                    }

                    Text {
                        text: "Keyboard Shortcuts"
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 18; font.bold: true
                        color: keybindsWindow.theme ? keybindsWindow.theme.getColor("onSurface") : "#f0dede"
                    }

                    Rectangle {
                        height: 22; width: countText.implicitWidth + 14; radius: 11
                        color: keybindsWindow.theme ? keybindsWindow.theme.getColor("surfaceVariant") : "#2b2a27"
                        Text {
                            id: countText; anchors.centerIn: parent
                            text: String(keybindsWindow.getFilteredKeybinds().length)
                            font.family: "Google Sans Flex, sans-serif"
                            font.pixelSize: 11; font.bold: true
                            color: keybindsWindow.theme ? keybindsWindow.theme.getColor("onSurfaceVariant") : "#c4c5d0"
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: closeMouse.containsMouse ? (keybindsWindow.theme ? keybindsWindow.theme.getColor("surfaceVariant") : "#2b2a27") : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }
                    IconImage {
                        anchors.centerIn: parent; width: 14; height: 14
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/dismiss.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect { colorization: 1.0; colorizationColor: keybindsWindow.theme ? keybindsWindow.theme.getColor("onSurfaceVariant") : "#c4c5d0" }
                    }
                    MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: keybindsWindow.active = false }
                }
            }

            UI.Input {
                id: searchInput
                Layout.fillWidth: true
                theme: keybindsWindow.theme
                placeholder: "Search shortcuts by key or action..."
                icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/search.svg")
                onTextChanged: keybindsWindow.searchQuery = text
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: keybindsWindow.theme ? keybindsWindow.theme.getColor("surfaceVariant") : "#2b2a27" }

            UI.AnimatedListView {
                id: shortcutsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: dynamicKeybindsModel.count > 0
                theme: keybindsWindow.theme
                pillColor: keybindsWindow.theme ? keybindsWindow.theme.getColor("surfaceVariant") : "#2b2a27"
                pillRadius: 12
                pillMargin: 4
                clip: true
                spacing: 4
                model: dynamicKeybindsModel
                delegate: KeybindItemDelegate {
                    parentListView: shortcutsList
                    theme: keybindsWindow.theme
                }
            }

            UI.EmptyState {
                visible: dynamicKeybindsModel.count === 0
                theme: keybindsWindow.theme
                searchQuery: keybindsWindow.searchQuery
                defaultIcon: "devices/keyboard.svg"
                title: keybindsWindow.searchQuery !== "" ? "No matching keybinds" : "No keybinds registered"
                subtitle: keybindsWindow.searchQuery !== "" ? ("Nothing matched \"" + keybindsWindow.searchQuery + "\"\nMaybe bind it in keybinds.lua ⌨️😉") : ""
            }
        }
    }
}
