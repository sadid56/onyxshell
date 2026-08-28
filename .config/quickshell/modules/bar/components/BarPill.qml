import QtQuick
import QtQuick.Layouts

Item {
    id: pillRoot

    property bool active: true
    property color pillColor: "#1e1e2e"
    property int pillRadius: 16
    property int pillHeight: 34
    property int contentPadding: 24
    property real contentWidth: contentContainer.children.length > 0 ? (contentContainer.children[0].implicitWidth || contentContainer.children[0].width || 0) : 0

    property int cursorShape: Qt.PointingHandCursor

    height: pillHeight
    width: active ? (contentWidth + contentPadding) : 0
    opacity: active ? 1.0 : 0.0
    visible: opacity > 0.001
    clip: true

    Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

    MouseArea {
        id: pillHoverArea
        anchors.fill: parent
        cursorShape: pillRoot.cursorShape
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        z: -1
    }

    Rectangle {
        anchors.fill: parent
        radius: pillRoot.pillRadius
        color: pillRoot.pillColor
    }

    Item {
        id: contentContainer
        anchors.centerIn: parent
        width: pillRoot.contentWidth
        height: pillRoot.pillHeight
    }

    default property alias contentData: contentContainer.data
}
