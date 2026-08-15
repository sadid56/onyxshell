import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: emptyStateRoot
    Layout.fillWidth: true
    spacing: 8
    Layout.topMargin: 20
    Layout.bottomMargin: 20
    
    property var theme
    property string searchQuery

    Text {
        text: "󱉬"
        font.family: "Noto Sans"
        font.pixelSize: 32
        color: emptyStateRoot.theme.getColor("outline")
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        text: emptyStateRoot.searchQuery === "" ? "No applications installed" : "No matching applications found"
        font.family: "Google Sans Flex, sans-serif"
        font.pixelSize: 13
        font.bold: true
        color: emptyStateRoot.theme.getColor("outline")
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
    }
}
