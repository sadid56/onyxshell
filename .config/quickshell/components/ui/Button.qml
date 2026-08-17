import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Rectangle {
    id: buttonRoot
    implicitWidth: buttonRoot.text !== "" ? (btnRow.implicitWidth + 24) : 40
    implicitHeight: 40
    radius: 12
    color: active
        ? buttonRoot.theme.getColor("primary")
        : (hoverArea.containsMouse ? buttonRoot.theme.getColor("surfaceVariant") : buttonRoot.theme.getColor("surfaceVariant"))
    opacity: active ? 1.0 : (hoverArea.containsMouse ? 1.0 : 0.85)
    border.width: 0

    property var theme
    property string icon: ""
    property string text: ""
    property bool active: false
    property int iconSize: 20

    signal clicked()

    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        id: btnRow
        anchors.fill: parent
        anchors.leftMargin: buttonRoot.text !== "" ? 12 : 0
        anchors.rightMargin: buttonRoot.text !== "" ? 12 : 0
        spacing: 8
        visible: buttonRoot.text !== ""

        IconImage {
            width: 17
            height: 17
            source: buttonRoot.icon.length > 2 ? buttonRoot.icon : ""
            visible: buttonRoot.icon !== "" && buttonRoot.icon.length > 2
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: buttonRoot.active
                    ? (buttonRoot.theme ? buttonRoot.theme.getColor("onPrimary") : "#000000")
                    : (buttonRoot.theme ? buttonRoot.theme.getColor("onSurface") : "#FFFFFF")
            }
        }

        Text {
            text: buttonRoot.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: buttonRoot.active
                ? (buttonRoot.theme ? buttonRoot.theme.getColor("onPrimary") : "#000000")
                : (buttonRoot.theme ? buttonRoot.theme.getColor("onSurface") : "#FFFFFF")
            visible: buttonRoot.icon !== "" && buttonRoot.icon.length <= 2
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: buttonRoot.text
            font.family: "Noto Sans"
            font.pixelSize: 11
            font.bold: true
            color: buttonRoot.active
                ? (buttonRoot.theme ? buttonRoot.theme.getColor("onPrimary") : "#000000")
                : (buttonRoot.theme ? buttonRoot.theme.getColor("onSurface") : "#FFFFFF")
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignLeft
        }
    }

    Item {
        anchors.centerIn: parent
        width: buttonRoot.iconSize
        height: buttonRoot.iconSize
        visible: buttonRoot.text === ""

        IconImage {
            anchors.fill: parent
            source: buttonRoot.icon.length > 2 ? buttonRoot.icon : ""
            visible: buttonRoot.icon !== "" && buttonRoot.icon.length > 2
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: buttonRoot.active
                    ? (buttonRoot.theme ? buttonRoot.theme.getColor("onPrimary") : "#000000")
                    : (buttonRoot.theme ? buttonRoot.theme.getColor("onSurface") : "#FFFFFF")
            }
        }

        Text {
            anchors.centerIn: parent
            text: buttonRoot.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            font.bold: true
            color: buttonRoot.active
                ? (buttonRoot.theme ? buttonRoot.theme.getColor("onPrimary") : "#000000")
                : (buttonRoot.theme ? buttonRoot.theme.getColor("onSurface") : "#FFFFFF")
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
