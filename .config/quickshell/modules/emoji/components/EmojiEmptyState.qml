import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

ColumnLayout {
    id: emptyStateRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    spacing: 10

    property var theme
    property string searchQuery: ""

    IconImage {
        width: 32
        height: 32
        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/search.svg")
        Layout.alignment: Qt.AlignHCenter
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("outline") : "#8c909f"
        }
    }

    Text {
        text: emptyStateRoot.searchQuery === "" ? "No emojis found" : "No emojis matching \"" + emptyStateRoot.searchQuery + "\""
        font.family: "Google Sans Flex, sans-serif"
        font.pixelSize: 13
        font.bold: true
        color: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("outline") : "#8c909f"
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
    }
}
