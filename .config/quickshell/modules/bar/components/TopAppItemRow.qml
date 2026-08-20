import QtQuick
import QtQuick.Layouts

Item {
    id: rowRoot
    Layout.fillWidth: true
    implicitHeight: 28

    property var theme
    property var appData: ({})
    property int rank: 1

    signal rightClicked(var data, real globalX, real globalY)

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                var gPos = rowRoot.mapToItem(null, mouse.x, mouse.y);
                rowRoot.rightClicked(rowRoot.appData, gPos.x, gPos.y);
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 0

        Text {
            text: String(rowRoot.rank)
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 10
            color: rowRoot.theme ? rowRoot.theme.getColor("outline") : "#8c909f"
            Layout.preferredWidth: 16
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: rowRoot.appData.name || "—"
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 11
            color: rowRoot.theme ? rowRoot.theme.getColor("onSurface") : "#FFFFFF"
            Layout.fillWidth: true
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: (rowRoot.appData.count || 1) > 1
            text: "×" + (rowRoot.appData.count || 1)
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 9
            color: rowRoot.theme ? rowRoot.theme.getColor("outline") : "#8c909f"
            Layout.preferredWidth: 22
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: (rowRoot.appData.cpu || 0).toFixed(1) + "%"
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 10
            font.bold: (rowRoot.appData.cpu || 0) > 10
            color: (rowRoot.appData.cpu || 0) > 15
                ? (rowRoot.theme ? rowRoot.theme.getColor("primary") : "#adc6ff")
                : (rowRoot.theme ? rowRoot.theme.getColor("outline") : "#8c909f")
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: {
                var mb = rowRoot.appData.rss_mb || 0;
                return mb >= 1024 ? (mb / 1024).toFixed(1) + " GB" : mb.toFixed(0) + " MB";
            }
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 10
            font.bold: (rowRoot.appData.rss_mb || 0) > 1000
            color: (rowRoot.appData.rss_mb || 0) > 1000
                ? (rowRoot.theme ? rowRoot.theme.getColor("primary") : "#adc6ff")
                : (rowRoot.theme ? rowRoot.theme.getColor("outline") : "#8c909f")
            Layout.preferredWidth: 52
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
