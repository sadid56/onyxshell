import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Rectangle {
    id: inputRoot
    Layout.fillWidth: true
    implicitHeight: 40
    height: 40
    radius: 20
    color: inputRoot.theme.getColor("surfaceVariant")
    border.color: textInput.activeFocus ? inputRoot.theme.getColor("primary") : "transparent"
    border.width: textInput.activeFocus ? 1.5 : 0

    Behavior on border.color { ColorAnimation { duration: 180 } }
    Behavior on color { ColorAnimation { duration: 180 } }

    property var theme
    property alias text: textInput.text
    property string placeholder: "Search..."
    property string icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/search.svg")
    property int echoMode: TextInput.Normal
    property bool clearButtonEnabled: true
    property alias textInput: textInput

    signal escapePressed()
    signal downPressed()
    signal returnPressed()

    function forceFocus() {
        textInput.forceActiveFocus();
    }

    MouseArea {
        id: inputMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onClicked: textInput.forceActiveFocus()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        IconImage {
            width: 16
            height: 16
            source: inputRoot.icon.length > 2 ? inputRoot.icon : (typeof shellConfig !== "undefined" ? shellConfig.getIcon("actions/search.svg") : "")
            visible: inputRoot.icon !== "" && inputRoot.icon.length > 2
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: textInput.activeFocus ? inputRoot.theme.getColor("primary") : inputRoot.theme.getColor("outline")
            }
        }

        Text {
            text: inputRoot.icon
            font.family: "Noto Sans"
            font.pixelSize: 17
            color: textInput.activeFocus ? inputRoot.theme.getColor("primary") : inputRoot.theme.getColor("outline")
            visible: inputRoot.icon !== "" && inputRoot.icon.length <= 2
            Layout.alignment: Qt.AlignVCenter

            Behavior on color { ColorAnimation { duration: 180 } }
        }

        TextInput {
            id: textInput
            Layout.fillWidth: true
            color: inputRoot.theme.getColor("onSurface")
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 13
            echoMode: inputRoot.echoMode
            selectByMouse: true
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: inputRoot.placeholder
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 13
                color: inputRoot.theme.getColor("outline")
                visible: !textInput.text && !textInput.activeFocus
                anchors.verticalCenter: parent.verticalCenter
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    inputRoot.escapePressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                    inputRoot.downPressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    inputRoot.returnPressed();
                    event.accepted = true;
                }
            }
        }

        Rectangle {
            id: clearBtn
            width: 22
            height: 22
            radius: 11
            color: clearMouse.containsMouse ? inputRoot.theme.getColor("surface") : "transparent"
            visible: inputRoot.clearButtonEnabled && textInput.text.length > 0
            Layout.alignment: Qt.AlignVCenter

            Behavior on color { ColorAnimation { duration: 120 } }

            IconImage {
                anchors.centerIn: parent
                width: 12
                height: 12
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/dismiss.svg")
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: clearMouse.containsMouse ? inputRoot.theme.getColor("primary") : inputRoot.theme.getColor("outline")
                }
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    textInput.text = "";
                    textInput.forceActiveFocus();
                }
            }
        }
    }
}
