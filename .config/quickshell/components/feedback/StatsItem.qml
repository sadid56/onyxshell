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

    Text {
        text: statsItemRoot.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        font.bold: true
        color: statsItemRoot.customColor !== "" 
            ? statsItemRoot.customColor 
            : (statsItemRoot.theme ? statsItemRoot.theme.getColor("onSurface") : "#FFFFFF")
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: statsItemRoot.value
        font.family: "Noto Sans"
        font.pixelSize: 13
        font.bold: true
        color: statsItemRoot.customColor !== "" 
            ? statsItemRoot.customColor 
            : (statsItemRoot.theme ? statsItemRoot.theme.getColor("onSurface") : "#FFFFFF")
        Layout.alignment: Qt.AlignVCenter
    }
}
