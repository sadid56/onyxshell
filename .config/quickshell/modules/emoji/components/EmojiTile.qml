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
    signal hovered()
    signal unhovered()

    Text {
        anchors.centerIn: parent
        text: emojiTileRoot.emojiData.e || ""
        font.family: "Noto Color Emoji, Apple Color Emoji, Segoe UI Emoji, sans-serif"
        font.pixelSize: 30
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: emojiTileRoot.hovered()
        onExited: emojiTileRoot.unhovered()
        onClicked: emojiTileRoot.clicked(emojiTileRoot.emojiData.e || "", emojiTileRoot.emojiData.n || "")
    }
}
