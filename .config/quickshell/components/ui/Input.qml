import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: inputRoot
    Layout.fillWidth: true
    implicitHeight: 40
    height: 40
    radius: 20
    color: inputRoot.theme ? inputRoot.theme.getColor("surfaceVariant") : "#282836"
    border.color: textInput.activeFocus ? (inputRoot.theme ? inputRoot.theme.getColor("primary") : "#c5c5d8") : "transparent"
    border.width: textInput.activeFocus ? 1.5 : 0

    Behavior on border.color { ColorAnimation { duration: 180 } }
    Behavior on color { ColorAnimation { duration: 180 } }

    property var theme
    property alias text: textInput.text
    property string placeholder: "Search..."
    property string icon: "actions/search.svg"
    property int echoMode: TextInput.Normal
    property bool clearButtonEnabled: true
    property alias textInput: textInput

    signal escapePressed()
    signal downPressed()
    signal upPressed()
    signal leftPressed()
    signal rightPressed()
    signal returnPressed()

    function forceFocus() {
        textInput.forceActiveFocus();
    }

    function resolveIcon(src) {
        if (!src || src === "") return "";
        if (src.indexOf("/") === 0) return "file://" + src;
        if (src.indexOf("file://") === 0 || src.indexOf("image://") === 0 || src.indexOf("qrc:/") === 0) return src;
        var cfg = (typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : ((typeof root !== "undefined" && root.shellConfig) ? root.shellConfig : null);
        if (cfg && typeof cfg.getIcon === "function") return cfg.getIcon(src);
        return "file://" + (Quickshell.env("HOME") || "") + "/.config/quickshell/assets/icons/" + src;
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
            source: inputRoot.resolveIcon(inputRoot.icon)
            visible: inputRoot.icon !== "" && inputRoot.icon.length > 2
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: textInput.activeFocus ? (inputRoot.theme ? inputRoot.theme.getColor("primary") : "#c5c5d8") : (inputRoot.theme ? inputRoot.theme.getColor("outline") : "#909090")
            }
        }

        Typography {
            theme: inputRoot.theme
            text: inputRoot.icon
            mono: true
            font.pixelSize: 17
            color: textInput.activeFocus ? (inputRoot.theme ? inputRoot.theme.getColor("primary") : "#c5c5d8") : (inputRoot.theme ? inputRoot.theme.getColor("outline") : "#909090")
            visible: inputRoot.icon !== "" && inputRoot.icon.length <= 2
            Layout.alignment: Qt.AlignVCenter

            Behavior on color { ColorAnimation { duration: 180 } }
        }

        TextInput {
            id: textInput
            Layout.fillWidth: true
            color: inputRoot.theme ? inputRoot.theme.getColor("onSurface") : "#ffffff"
            font.family: inputRoot.theme ? inputRoot.theme.fontFamily : ""
            font.pixelSize: 13
            echoMode: inputRoot.echoMode
            selectByMouse: true
            Layout.alignment: Qt.AlignVCenter

            Typography {
                theme: inputRoot.theme
                text: inputRoot.placeholder
                font.pixelSize: 13
                colorRole: "outline"
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
                } else if (event.key === Qt.Key_Up) {
                    inputRoot.upPressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left && (!textInput.text || textInput.cursorPosition === 0)) {
                    inputRoot.leftPressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right && (!textInput.text || textInput.cursorPosition === textInput.text.length)) {
                    inputRoot.rightPressed();
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
            color: clearMouse.containsMouse ? (inputRoot.theme ? inputRoot.theme.getColor("surface") : "#1a1a24") : "transparent"
            visible: inputRoot.clearButtonEnabled && textInput.text.length > 0
            Layout.alignment: Qt.AlignVCenter

            Behavior on color { ColorAnimation { duration: 120 } }

            IconImage {
                anchors.centerIn: parent
                width: 12
                height: 12
                source: inputRoot.resolveIcon("actions/dismiss.svg")
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: clearMouse.containsMouse ? (inputRoot.theme ? inputRoot.theme.getColor("primary") : "#c5c5d8") : (inputRoot.theme ? inputRoot.theme.getColor("outline") : "#909090")
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
