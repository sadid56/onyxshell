import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

ColumnLayout {
    id: emptyStateRoot
    Layout.fillWidth: true
    spacing: 10
    Layout.topMargin: 20
    Layout.bottomMargin: 20

    property var theme
    property string searchQuery

    IconImage {
        width: 32
        height: 32
        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(emptyStateRoot.searchQuery === "" ? "actions/image-copy.svg" : "actions/search.svg")
        Layout.alignment: Qt.AlignHCenter
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("outline") : "#757680"
        }
    }

    Text {
        text: emptyStateRoot.searchQuery === "" ? "Clipboard is empty" : "No matching items found"
        font.family: "Google Sans Flex, sans-serif"
        font.pixelSize: 13
        font.bold: true
        color: emptyStateRoot.theme.getColor("outline")
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
    }
}
