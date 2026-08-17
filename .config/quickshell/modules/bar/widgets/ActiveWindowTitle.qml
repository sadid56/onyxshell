import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: windowTitle

    property var theme

    implicitWidth: titleText.implicitWidth
    implicitHeight: 28
    Layout.maximumWidth: 260

    Text {
        id: titleText
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: 12

        text: {
            if (!Hyprland.activeToplevel) return "";
            var title = Hyprland.activeToplevel.title;
            if (!title || title === "") return "";
            return title;
        }

        font.family: "Google Sans Flex, sans-serif"
        font.pixelSize: 12
        color: windowTitle.theme ? windowTitle.theme.getColor("outline") : "#757680"
        elide: Text.ElideRight
        maximumLineCount: 1
        width: windowTitle.width
        opacity: text !== "" ? 0.8 : 0.0

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
}
