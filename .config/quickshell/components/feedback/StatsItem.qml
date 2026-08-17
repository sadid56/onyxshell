import QtQuick
import QtQuick.Layouts

RowLayout {
    id: statsItemRoot
    spacing: 4
    Layout.alignment: Qt.AlignVCenter

    property var theme
    property string icon: ""
    property string value: ""
    property string customColor: ""
    property int iconSize: 13
    property int textSize: 13
    property int iconOffsetY: 0

    Text {
        text: statsItemRoot.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: statsItemRoot.iconSize
        font.bold: true
        color: statsItemRoot.customColor !== ""
            ? statsItemRoot.customColor
            : (statsItemRoot.theme ? statsItemRoot.theme.getColor("onSurface") : "#FFFFFF")
        Layout.alignment: Qt.AlignVCenter
        topPadding: statsItemRoot.iconOffsetY
    }

    Text {
        text: statsItemRoot.value
        font.family: "Noto Sans"
        font.pixelSize: statsItemRoot.textSize
        font.bold: true
        color: statsItemRoot.customColor !== ""
            ? statsItemRoot.customColor
            : (statsItemRoot.theme ? statsItemRoot.theme.getColor("onSurface") : "#FFFFFF")
        Layout.alignment: Qt.AlignVCenter
    }
}
