import QtQuick
import QtQuick.Layouts

Item {
    id: emojiTileRoot
    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    property var theme
    property var emojiData: ({})
    property bool isSelected: false
    signal clicked(string emojiChar, string emojiName)

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 6, 52)
        height: Math.min(parent.height - 6, 52)
        radius: 10
        color: emojiTileRoot.isSelected || tileMouse.containsMouse
            ? (emojiTileRoot.theme ? emojiTileRoot.theme.getColor("surfaceVariant") : "#2b2a27")
            : "transparent"
        border.width: emojiTileRoot.isSelected ? 1.5 : 0
        border.color: emojiTileRoot.isSelected
            ? (emojiTileRoot.theme ? emojiTileRoot.theme.getColor("primary") : "#adc6ff")
            : "transparent"

        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text: emojiTileRoot.emojiData.e || ""
            font.family: "Noto Color Emoji, Apple Color Emoji, Segoe UI Emoji, sans-serif"
            font.pixelSize: 30
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: emojiTileRoot.clicked(emojiTileRoot.emojiData.e || "", emojiTileRoot.emojiData.n || "")
    }
}
