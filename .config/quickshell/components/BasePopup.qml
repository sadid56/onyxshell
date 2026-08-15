import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./statusbar"

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
    property int topOverlap: 14 // How much the popup overlaps the status bar bottom edge
    property bool flatBottom: false
    property bool showCorners: true
    property real contentRectX: targetX > 0 ? Math.max(0, Math.min(targetX - popupWidth / 2, popupWindow.width - popupWidth)) : (popupWindow.width - popupWidth) / 2
    property real contentRectY: popupWindow.active ? -popupWindow.topOverlap : -(popupWindow.topOverlap + 10)

    // Allows children placed inside BasePopup in subclass files to load directly into the ColumnLayout
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

    // Grace period after opening to prevent immediate close from keyboard shortcuts
    Timer {
        id: openGuard
        interval: 300
        running: false
        repeat: false
    }

    onActiveChanged: {
        if (active) {
            openGuard.restart();
        }
    }

    // Capture clicks/hover outside to trigger closing
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            if (!openGuard.running) popupWindow.closeTimer.restart();
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

        // Prevent click through & stop closeTimer when hovered
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
        scale: popupWindow.active ? 1.0 : 0.97
        
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on x {
            enabled: popupWindow.active && contentRect.opacity === 1.0
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        // Inverted corner on the left side of the popup, aligning with the status bar bottom edge
        Corner {
            anchors.top: parent.top
            anchors.topMargin: popupWindow.topOverlap
            anchors.right: parent.left
            alignRight: true
            color: popupWindow.theme.getColor("surface")
            visible: popupWindow.showCorners
        }

        // Inverted corner on the right side of the popup, aligning with the status bar bottom edge
        Corner {
            anchors.top: parent.top
            anchors.topMargin: popupWindow.topOverlap
            anchors.left: parent.right
            alignRight: false
            color: popupWindow.theme.getColor("surface")
            visible: popupWindow.showCorners
        }

        // Optional cover to flatten the bottom rounded corners (e.g. for full screen height sidebars)
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
