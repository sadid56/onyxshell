import QtQuick
import QtQuick.Layouts

RowLayout {
    id: headerRoot
    Layout.fillWidth: true
    
    property var theme

    signal clearAllClicked()

    Text {
        text: "Clipboard History"
        font.family: "Noto Sans"
        font.pixelSize: 16
        font.bold: true
        color: headerRoot.theme.getColor("primary")
    }

    Item { Layout.fillWidth: true }

    Text {
        text: "󰆴 Clear All"
        font.family: "Noto Sans"
        font.pixelSize: 12
        font.bold: true
        color: headerRoot.theme.getColor("error")
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                headerRoot.clearAllClicked();
            }
        }
    }
}
