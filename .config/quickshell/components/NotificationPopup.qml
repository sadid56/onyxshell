import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./statusbar"

PanelWindow {
    id: toastWindow
    
    // Small window: just big enough for toast + corners, NOT full-screen
    // Full-height strip on the right so exclusive zone doesn't push it down
    anchors { top: true; bottom: true; left: false; right: true }
    implicitWidth: 416     // 16 (left corner) + 400 (popup)
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0

    // Only capture input on the toast card itself — clicks pass through everywhere else
    mask: Region { item: contentRect }

    property var theme
    property bool active: false
    property var currentNotification: null
    property int topOverlap: 14  // How much contentRect overlaps into the status bar

    visible: active || hideTimer.running

    onActiveChanged: {
        if (!active) {
            hideTimer.start();
        } else {
            hideTimer.stop();
        }
    }

    Timer {
        id: hideTimer
        interval: 250
        running: false
        repeat: false
    }

    // Auto-dismiss after 3 seconds
    Timer {
        id: dismissTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: toastWindow.active = false
    }

    function showToast(notification) {
        currentNotification = notification;
        dismissTimer.stop();
        active = true;
        
        progressAnim.stop();
        progressBar.width = contentRect.width;
        progressAnim.start();
        
        dismissTimer.start();
    }

    // --- Content Rectangle (the toast card) ---
    Rectangle {
        id: contentRect
        // 16px from left edge for corner space, overlaps status bar by topOverlap
        x: toastWindow.active ? 16 : 46
        y: toastWindow.active ? -toastWindow.topOverlap : -(toastWindow.topOverlap + 10)
        width: 400
        height: 84
        radius: 16
        
        color: toastWindow.theme.getColor("surface")
        border.width: 0

        opacity: toastWindow.active ? 1.0 : 0.0
        
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // Flatten right side corners (flush against screen edge)
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: parent.radius
            color: parent.color
        }

        // Layout container for toast content
        RowLayout {
            anchors.fill: parent
            anchors.topMargin: toastWindow.topOverlap + 8
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 10
            spacing: 12

            // Icon with glowing primary background
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: toastWindow.theme.getColor("surfaceVariant")
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    font.family: "Noto Sans"
                    font.pixelSize: 18
                    color: toastWindow.theme.getColor("primary")
                }
            }

            // Info Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                


                Text {
                    text: toastWindow.currentNotification ? (toastWindow.currentNotification.summary || "") : ""
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 13
                    font.bold: true
                    color: toastWindow.theme.getColor("onSurface")
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: toastWindow.currentNotification ? (toastWindow.currentNotification.body || "") : ""
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 11
                    color: toastWindow.theme.getColor("outline")
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Dismiss Button
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: "transparent"
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: "Noto Sans"
                    font.pixelSize: 14
                    color: toastWindow.theme.getColor("outline")
                }

                MouseArea {
                    id: dismissMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toastWindow.active = false
                    onEntered: parent.color = toastWindow.theme.getColor("surfaceVariant")
                    onExited: parent.color = "transparent"
                }
            }
        }

        // Tap toast to dismiss
        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: 40
            onClicked: {
                toastWindow.active = false;
            }
        }

        // Bottom Progress Bar
        Rectangle {
            id: progressBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            height: 3
            radius: 1.5
            color: toastWindow.theme.getColor("primary")
            width: 0

            NumberAnimation on width {
                id: progressAnim
                from: 400
                to: 0
                duration: 3000
                running: false
                easing.type: Easing.Linear
            }
        }
    }

    // Top-Left Inverted Corner — connects popup left wall to status bar bottom
    Corner {
        x: contentRect.x - 16
        y: contentRect.y + toastWindow.topOverlap
        alignRight: true
        color: toastWindow.theme.getColor("surface")
        opacity: contentRect.opacity
    }

    // Bottom-Right Inverted Corner — connects popup bottom to right screen edge
    Canvas {
        width: 16
        height: 16
        antialiasing: true
        x: contentRect.x + contentRect.width - 16
        y: contentRect.y + contentRect.height
        opacity: contentRect.opacity

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = toastWindow.theme.getColor("surface");
            ctx.beginPath();
            ctx.moveTo(16, 0);
            ctx.lineTo(16, 16);
            ctx.lineTo(0, 16);
            ctx.arc(0, 0, 16, Math.PI * 0.5, 0, false);
            ctx.closePath();
            ctx.fill();
        }
    }
}
