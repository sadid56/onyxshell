import QtQuick
import QtQuick.Layouts

Rectangle {
    id: searchBarRoot
    Layout.fillWidth: true
    height: 42
    radius: 10
    color: theme.getColor("surfaceVariant")

    property var theme
    property alias text: searchInput.text

    signal escapePressed()
    
    function forceFocus() {
        searchInput.forceActiveFocus();
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Text {
            text: ""
            font.family: "Noto Sans"
            font.pixelSize: 14
            color: searchBarRoot.theme.getColor("onSurfaceVariant")
        }

        TextInput {
            id: searchInput
            Layout.fillWidth: true
            color: searchBarRoot.theme.getColor("onSurface")
            font.family: "Noto Sans"
            font.pixelSize: 13
            selectByMouse: true
            
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    searchBarRoot.escapePressed();
                    event.accepted = true;
                }
            }
        }
    }
}
