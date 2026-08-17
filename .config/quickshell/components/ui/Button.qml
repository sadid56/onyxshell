import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

Rectangle {
    id: buttonRoot
    implicitWidth: 60
    implicitHeight: 40
    radius: 12
    color: active 
        ? buttonRoot.theme.getColor("primary") 
        : (hoverArea.containsMouse ? buttonRoot.theme.getColor("surfaceVariant") : buttonRoot.theme.getColor("surface"))
    
    border.width: 1
    border.color: active ? "transparent" : buttonRoot.theme.getColor("outline")

    property var theme
    property string icon: ""
    property string text: ""
    property bool active: false
    
    signal clicked()

    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: buttonRoot.text !== "" ? 12 : 0
        anchors.rightMargin: buttonRoot.text !== "" ? 12 : 0
        spacing: 8
        visible: buttonRoot.text !== ""

        IconImage {
            width: 16
            height: 16
            source: buttonRoot.icon.length > 2 ? buttonRoot.icon : ""
            visible: buttonRoot.icon !== "" && buttonRoot.icon.length > 2
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: buttonRoot.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: buttonRoot.active 
                ? buttonRoot.theme.getColor("onPrimary") 
                : buttonRoot.theme.getColor("onSurface")
            visible: buttonRoot.icon !== "" && buttonRoot.icon.length <= 2
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: buttonRoot.text
            font.family: "Noto Sans"
            font.pixelSize: 11
            font.bold: true
            color: buttonRoot.active 
                ? buttonRoot.theme.getColor("onPrimary") 
                : buttonRoot.theme.getColor("onSurface")
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignLeft
        }
    }

    Item {
        anchors.centerIn: parent
        width: 16
        height: 16
        visible: buttonRoot.text === ""

        IconImage {
            anchors.fill: parent
            source: buttonRoot.icon.length > 2 ? buttonRoot.icon : ""
            visible: buttonRoot.icon !== "" && buttonRoot.icon.length > 2
        }

        Text {
            anchors.centerIn: parent
            text: buttonRoot.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            font.bold: true
            color: buttonRoot.active 
                ? buttonRoot.theme.getColor("onPrimary") 
                : buttonRoot.theme.getColor("onSurface")
            visible: buttonRoot.icon !== "" && buttonRoot.icon.length <= 2
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            buttonRoot.clicked();
        }
    }
}
