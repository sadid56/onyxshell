import QtQuick
import QtQuick.Layouts
import Quickshell

Text {
    id: logoText
    text: ""
    font.pixelSize: 16
    color: barWindow.theme.getColor("primary")
    font.family: "Noto Sans"
    font.bold: true
    Layout.alignment: Qt.AlignVCenter
}
