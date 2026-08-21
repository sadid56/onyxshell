import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

ColumnLayout {
    id: emptyStateRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignCenter
    spacing: 10

    property var theme
    property string searchQuery: ""

    Item { Layout.fillHeight: true }

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 54
        height: 54
        radius: 27
        color: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("surfaceVariant") : "#2b2a27"

        IconImage {
            anchors.centerIn: parent
            width: 24
            height: 24
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/keyboard.svg")
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("primary") : "#ffb3b4"
            }
        }
    }

    Text {
        text: "No shortcuts found!"
        font.family: "Google Sans Flex, sans-serif"
        font.pixelSize: 15
        font.bold: true
        color: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("onSurface") : "#f0dede"
        Layout.alignment: Qt.AlignHCenter
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        text: emptyStateRoot.searchQuery !== ""
            ? "Nothing matched \"" + emptyStateRoot.searchQuery + "\"\nMaybe bind it yourself in keybinds.lua ⌨️😉"
            : "No keybindings loaded\nAdd some in keybinds.lua 🚀"
        font.family: "Google Sans Flex, sans-serif"
        font.pixelSize: 12
        color: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("outline") : "#757680"
        Layout.alignment: Qt.AlignHCenter
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 1.3
    }

    Item { Layout.fillHeight: true }
}
