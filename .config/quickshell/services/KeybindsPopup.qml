import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
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
    property string selectedCategory: "All"
    property var allKeybinds: []

    visible: active || hideTimer.running

    onActiveChanged: {
        if (active) {
            searchInput.forceFocus();
            refreshKeybinds();
        } else {
            searchInput.text = "";
            searchQuery = "";
            selectedCategory = "All";
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
        var arr = [];
        var query = searchQuery.toLowerCase().trim();
        for (var i = 0; i < allKeybinds.length; i++) {
            var kb = allKeybinds[i];
            var matchesCategory = (selectedCategory === "All" || kb.category === selectedCategory);
            var matchesQuery = (query === "" ||
                                kb.keys.toLowerCase().indexOf(query) !== -1 ||
                                kb.action.toLowerCase().indexOf(query) !== -1 ||
                                (kb.category && kb.category.toLowerCase().indexOf(query) !== -1));
            if (matchesCategory && matchesQuery) {
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

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

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
                        width: 20
                        height: 20
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("keyboard.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: keybindsWindow.theme ? keybindsWindow.theme.getColor("primary") : "#ffb3b4"
                        }
                    }

                    Text {
                        text: "Keyboard Shortcuts"
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 18
                        font.bold: true
                        color: keybindsWindow.theme ? keybindsWindow.theme.getColor("onSurface") : "#f0dede"
                    }

                    Rectangle {
                        height: 22
                        width: countText.implicitWidth + 14
                        radius: 11
                        color: keybindsWindow.theme ? keybindsWindow.theme.getColor("surfaceVariant") : "#2b2a27"

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: String(keybindsWindow.getFilteredKeybinds().length)
                            font.family: "Google Sans Flex, sans-serif"
                            font.pixelSize: 11
                            font.bold: true
                            color: keybindsWindow.theme ? keybindsWindow.theme.getColor("onSurfaceVariant") : "#c4c5d0"
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: closeMouse.containsMouse ?
                           (keybindsWindow.theme ? keybindsWindow.theme.getColor("surfaceVariant") : "#2b2a27") :
                           "transparent"

                    Behavior on color { ColorAnimation { duration: 140 } }

                    IconImage {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("dismiss.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: keybindsWindow.theme ? keybindsWindow.theme.getColor("onSurfaceVariant") : "#c4c5d0"
                        }
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: keybindsWindow.active = false
                    }
                }
            }

            UIInputs.Input {
                id: searchInput
                theme: keybindsWindow.theme
                placeholder: "Search commands or shortcuts (e.g. Browser, Terminal, SUPER)..."
                icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("search.svg")
                Layout.fillWidth: true
                onTextChanged: keybindsWindow.searchQuery = text
                onEscapePressed: keybindsWindow.active = false
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: ["All", "Applications", "Window", "Workspaces", "System", "Media", "Screenshot"]
                    delegate: Rectangle {
                        id: catPill
                        height: 30
                        width: catText.implicitWidth + 20
                        radius: 15
                        color: keybindsWindow.selectedCategory === modelData ?
                               (keybindsWindow.theme ? keybindsWindow.theme.getColor("primary") : "#ffb3b4") :
                               (catMouse.containsMouse ?
                                   (keybindsWindow.theme ? keybindsWindow.theme.getColor("surfaceVariant") : "#2b2a27") :
                                   "transparent")
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            id: catText
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "Google Sans Flex, sans-serif"
                            font.pixelSize: 12
                            font.bold: keybindsWindow.selectedCategory === modelData
                            color: keybindsWindow.selectedCategory === modelData ?
                                   (keybindsWindow.theme ? keybindsWindow.theme.getColor("onPrimary") : "#380d15") :
                                   (keybindsWindow.theme ? keybindsWindow.theme.getColor("onSurfaceVariant") : "#c4c5d0")
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: keybindsWindow.selectedCategory = modelData
                        }
                    }
                }
            }

            ListView {
                id: shortcutsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 1600
                maximumFlickVelocity: 2800

                property int hoveredIndex: -1
                property real lastHoveredY: 0

                model: keybindsWindow.getFilteredKeybinds()

                Rectangle {
                    id: glidingPill
                    parent: shortcutsList.contentItem
                    z: 0
                    x: 0
                    width: shortcutsList.width
                    height: 50
                    radius: 14
                    color: keybindsWindow.theme ? keybindsWindow.theme.getColor("surfaceVariant") : "#2b2a27"

                    y: shortcutsList.hoveredIndex >= 0 ? shortcutsList.lastHoveredY : shortcutsList.lastHoveredY
                    opacity: (shortcutsList.hoveredIndex >= 0 && shortcutsList.count > 0) ? 1.0 : 0.0

                    Behavior on y {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 130; easing.type: Easing.OutQuad }
                    }
                }

                WheelHandler {
                    id: wheelHandler
                    target: shortcutsList
                    orientation: Qt.Vertical
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        var step = (event.angleDelta.y / 120) * 90;
                        var maxScroll = Math.max(0, shortcutsList.contentHeight - shortcutsList.height);
                        var nextY = Math.max(0, Math.min(maxScroll, shortcutsList.contentY - step));
                        smoothScrollAnim.to = nextY;
                        smoothScrollAnim.restart();
                    }
                }

                NumberAnimation {
                    id: smoothScrollAnim
                    target: shortcutsList
                    property: "contentY"
                    duration: 180
                    easing.type: Easing.OutCubic
                }

                delegate: Item {
                    id: delegateRoot
                    width: shortcutsList.width
                    height: 50
                    z: 1

                    readonly property bool isHovered: shortcutsList.hoveredIndex === index
                    readonly property var keyParts: (modelData.keys || "").split("+").map(s => s.trim()).filter(s => s !== "")

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            shortcutsList.hoveredIndex = index;
                            shortcutsList.lastHoveredY = delegateRoot.y;
                        }
                        onExited: {
                            if (shortcutsList.hoveredIndex === index) {
                                shortcutsList.hoveredIndex = -1;
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 14

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: keybindsWindow.theme ? keybindsWindow.theme.getColor("surface") : "#1b1b1b"
                            Layout.alignment: Qt.AlignVCenter

                            IconImage {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("keyboard.svg")
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: delegateRoot.isHovered ?
                                           (keybindsWindow.theme ? keybindsWindow.theme.getColor("primary") : "#ffb3b4") :
                                           (keybindsWindow.theme ? keybindsWindow.theme.getColor("onSurfaceVariant") : "#c4c5d0")
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: modelData.action
                                font.family: "Google Sans Flex, sans-serif"
                                font.pixelSize: 13
                                font.bold: true
                                color: delegateRoot.isHovered ?
                                       (keybindsWindow.theme ? keybindsWindow.theme.getColor("primary") : "#ffb3b4") :
                                       (keybindsWindow.theme ? keybindsWindow.theme.getColor("onSurface") : "#f0dede")
                                elide: Text.ElideRight
                                Layout.fillWidth: true

                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                text: modelData.category || "General"
                                font.family: "Google Sans Flex, sans-serif"
                                font.pixelSize: 10
                                color: keybindsWindow.theme ? keybindsWindow.theme.getColor("outline") : "#757680"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: delegateRoot.keyParts
                                delegate: RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        height: 28
                                        width: keyLabel.implicitWidth + 16
                                        radius: 8
                                        color: keybindsWindow.theme ? keybindsWindow.theme.getColor("surface") : "#1b1b1b"
                                        border.width: 0

                                        Text {
                                            id: keyLabel
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.family: "Google Sans Flex, sans-serif"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: keybindsWindow.theme ? keybindsWindow.theme.getColor("primary") : "#ffb3b4"
                                        }
                                    }

                                    Text {
                                        text: "+"
                                        font.family: "Google Sans Flex, sans-serif"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: keybindsWindow.theme ? keybindsWindow.theme.getColor("outline") : "#757680"
                                        visible: index < delegateRoot.keyParts.length - 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
