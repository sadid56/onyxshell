import QtQuick
import QtQuick.Layouts

Rectangle {
    id: inputRoot
    Layout.fillWidth: true
    implicitHeight: 46
    height: 46
    radius: 14
    color: inputRoot.theme.getColor("surfaceVariant")
    border.color: textInput.activeFocus ? inputRoot.theme.getColor("primary") : (inputMouseArea.containsMouse ? inputRoot.theme.getColor("outline") : "transparent")
    border.width: textInput.activeFocus ? 1.5 : 1

    Behavior on border.color { ColorAnimation { duration: 180 } }
    Behavior on color { ColorAnimation { duration: 180 } }

    property var theme
    property alias text: textInput.text
    property string placeholder: "Search..."
    property string icon: "󰍉"
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

        Text {
            text: inputRoot.icon
            font.family: "Noto Sans"
            font.pixelSize: 17
            color: textInput.activeFocus ? inputRoot.theme.getColor("primary") : inputRoot.theme.getColor("outline")
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
                } else if (event.key === Qt.Key_Down) {
                    inputRoot.downPressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return) {
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

            Text {
                anchors.centerIn: parent
                text: "󰅖"
                font.family: "Noto Sans"
                font.pixelSize: 12
                color: clearMouse.containsMouse ? inputRoot.theme.getColor("primary") : inputRoot.theme.getColor("outline")
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
