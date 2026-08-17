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
    property bool isLoading: false

    IconImage {
        width: 32
        height: 32
        source: emptyStateRoot.isLoading
            ? (typeof shellConfig !== "undefined" ? shellConfig.getIcon("arrow-clockwise-filled.svg") : "")
            : (typeof shellConfig !== "undefined" ? shellConfig.getIcon("search.svg") : "")
        Layout.alignment: Qt.AlignHCenter
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: emptyStateRoot.theme ? emptyStateRoot.theme.getColor("outline") : "#FFFFFF"
        }

        RotationAnimation on rotation {
            running: emptyStateRoot.isLoading
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
        }
    }

    Text {
        text: emptyStateRoot.isLoading
            ? "Loading applications..."
            : (emptyStateRoot.searchQuery === "" ? "No applications installed" : "No matching applications found")
        font.family: "Google Sans Flex, sans-serif"
        font.pixelSize: 13
        font.bold: true
        color: emptyStateRoot.theme.getColor("outline")
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
    }
}
