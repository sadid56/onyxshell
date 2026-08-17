import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../modules/bar/widgets"

PanelWindow {
    id: popupWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    visible: active || contentRect.opacity > 0.0

    property var theme
    property real targetX: -1
    property alias closeTimer: closeTimer
    property alias contentRect: contentRect
    property alias contentX: contentRect.x

    property int popupWidth: 380
    property int popupHeight: 420
    property int topOverlap: 14
    property bool flatBottom: false
    property bool showCorners: true
    property bool closeOnHoverOutside: true

    readonly property int safeWidth: popupWindow.width > 0 ? popupWindow.width : 1920
    
    property real contentRectX: targetX > 0 ? Math.max(0, Math.min(targetX - popupWidth / 2, safeWidth - popupWidth)) : (safeWidth - popupWidth) / 2
    property real contentRectY: popupWindow.active ? -popupWindow.topOverlap : -(popupWindow.topOverlap + 20)

    default property alias contentData: columnLayout.data

    Timer {
        id: closeTimer
        interval: 150
        running: false
        repeat: false
        onTriggered: {
            popupWindow.active = false;
        }
    }

    Timer {
        id: openGuard
        interval: 300
        running: false
        repeat: false
    }

    onActiveChanged: {
        if (active) {
            openGuard.running = true;
            popupWindow.closeTimer.stop();
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            if (popupWindow.closeOnHoverOutside && !openGuard.running) {
                popupWindow.closeTimer.restart();
            }
        }
        onClicked: popupWindow.active = false
    }

    Rectangle {
        id: contentRect
        y: popupWindow.contentRectY
        x: popupWindow.contentRectX
        
        width: popupWindow.popupWidth
        height: popupWindow.popupHeight

        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        radius: 16
        color: popupWindow.theme.getColor("surface")
        border.width: 0

        MouseArea {
            id: contentMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                popupWindow.closeTimer.stop();
            }
            onClicked: {}
        }

        opacity: popupWindow.active ? 1.0 : 0.0
        scale: popupWindow.active ? 1.0 : 0.95
        
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Corner {
            anchors.top: parent.top
            anchors.topMargin: popupWindow.topOverlap
            anchors.right: parent.left
            alignRight: true
            color: popupWindow.theme.getColor("surface")
            visible: popupWindow.showCorners
        }

        Corner {
            anchors.top: parent.top
            anchors.topMargin: popupWindow.topOverlap
            anchors.left: parent.right
            alignRight: false
            color: popupWindow.theme.getColor("surface")
            visible: popupWindow.showCorners
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.radius
            color: parent.color
            visible: popupWindow.flatBottom
        }

        ColumnLayout {
            id: columnLayout
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 20
            anchors.topMargin: popupWindow.topOverlap + 10
            spacing: 14
        }
    }
}
