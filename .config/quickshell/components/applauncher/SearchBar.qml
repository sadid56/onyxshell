import QtQuick
import QtQuick.Layouts

Rectangle {
    id: searchBarRoot
    Layout.fillWidth: true
    height: 42
    radius: 10
    color: theme.getColor("surfaceVariant")
    border.color: searchInput.activeFocus ? theme.getColor("primary") : "transparent"
    border.width: 1

    property var theme
    property alias text: searchInput.text

    signal escapePressed()
    signal downPressed()
    signal returnPressed()
    
    function forceFocus() {
        searchInput.forceActiveFocus();
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Text {
            text: "󰍉"
            font.family: "Noto Sans"
            font.pixelSize: 15
            color: searchBarRoot.theme.getColor("outline")
            Layout.alignment: Qt.AlignVCenter
        }

        TextInput {
            id: searchInput
            Layout.fillWidth: true
            color: searchBarRoot.theme.getColor("onSurface")
            font.family: "Noto Sans"
            font.pixelSize: 13
            selectByMouse: true
            Layout.alignment: Qt.AlignVCenter

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    searchBarRoot.escapePressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    searchBarRoot.downPressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return) {
                    searchBarRoot.returnPressed();
                    event.accepted = true;
                }
            }
        }
    }
}
