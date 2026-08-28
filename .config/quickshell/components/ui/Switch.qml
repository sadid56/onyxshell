import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: switchRoot

    property var theme
    property bool checked: false
    property bool disabled: false

    implicitWidth: 48
    implicitHeight: 26

    signal toggled(bool checked)

    Rectangle {
        id: track
        anchors.fill: parent
        radius: 13
        color: switchRoot.checked
            ? (switchRoot.theme ? switchRoot.theme.getColor("primary") : "#c5c5d8")
            : (switchRoot.theme ? switchRoot.theme.getColor("surfaceVariant") : "#28292e")
        border.width: switchRoot.checked ? 0 : 1
        border.color: switchRoot.theme ? switchRoot.theme.getColor("outline") + "66" : "#ffffff33"

        opacity: switchRoot.disabled ? 0.4 : 1.0

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        Rectangle {
            id: thumb
            width: switchRoot.checked ? 18 : 14
            height: switchRoot.checked ? 18 : 14
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: switchRoot.checked ? (track.width - width - 4) : 5
            color: switchRoot.checked
                ? (switchRoot.theme ? switchRoot.theme.getColor("onPrimary") : "#1b1b22")
                : (switchRoot.theme ? switchRoot.theme.getColor("outline") : "#919096")

            Behavior on x {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
            Behavior on width {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            Behavior on height {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: !switchRoot.disabled
        cursorShape: switchRoot.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: {
            if (!switchRoot.disabled) {
                switchRoot.checked = !switchRoot.checked;
                switchRoot.toggled(switchRoot.checked);
            }
        }
    }
}
