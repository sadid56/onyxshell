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
    property bool isLoading: false

    Text {
        text: emptyStateRoot.isLoading ? "󰑐" : "󱉬"
        font.family: "Noto Sans"
        font.pixelSize: 32
        color: emptyStateRoot.theme.getColor("outline")
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        
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
