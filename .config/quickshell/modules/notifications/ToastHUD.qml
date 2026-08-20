import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../bar/widgets"
import "./components"

PanelWindow {
    id: toastWindow
    anchors { top: true; bottom: true; left: false; right: true }
    implicitWidth: 416
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0
    mask: Region { item: contentRect }

    property var theme
    property bool active: false
    property var currentNotification: null
    readonly property int toastRadius: 16
    readonly property int topOverlap: 14

    readonly property string appName: currentNotification ? (currentNotification.appName || currentNotification.applicationName || "") : ""
    readonly property string summaryText: currentNotification ? (currentNotification.summary || "Notification") : "Notification"
    readonly property string bodyText: currentNotification ? (currentNotification.body || "").replace(/\n/g, " ") : ""

    function getNotifIcon() {
        if (!currentNotification) return "file://" + shellConfig.defaultAppIcon;
        var ic = currentNotification.appIcon || currentNotification.icon || "";
        if (!ic) return "file://" + shellConfig.defaultAppIcon;
        return ic.indexOf("/") === 0 ? ("file://" + ic) : ic;
    }

    visible: active || hideTimer.running
    onActiveChanged: {
        if (!active) hideTimer.start();
        else { hideTimer.stop(); toastTranslate.x = 0; }
    }

    Timer { id: hideTimer; interval: 250; running: false; repeat: false }
    Timer {
        id: dismissTimer
        interval: 3500
        running: false
        repeat: false
        onTriggered: { if (!toastMouseArea.containsMouse) toastWindow.active = false; }
    }

    function showToast(notification) {
        currentNotification = notification;
        toastTranslate.x = 0;
        dismissTimer.stop();
        active = true;
        progressBar.progressAnim.stop();
        progressBar.progress = 1.0;
        progressBar.progressAnim.start();
        dismissTimer.start();
    }

    Rectangle {
        id: contentRect
        x: toastWindow.active ? 16 : 46
        y: toastWindow.active ? -toastWindow.topOverlap : -(toastWindow.topOverlap + 10)
        width: 400
        height: Math.max(84, notifRow.implicitHeight + toastWindow.topOverlap + 18)
        radius: toastWindow.toastRadius
        clip: true
        color: toastWindow.theme ? toastWindow.theme.getColor("surface") : "#1b1b1b"
        border.width: 0
        opacity: toastWindow.active ? Math.max(0.0, 1.0 - Math.abs(toastTranslate.x) / 250.0) : 0.0
        transform: Translate { id: toastTranslate; x: 0 }
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
            width: parent.radius
            color: parent.color
        }

        RowLayout {
            id: notifRow
            anchors { fill: parent; topMargin: toastWindow.topOverlap + 8; leftMargin: 14; rightMargin: 16; bottomMargin: 12 }
            spacing: 12

            Rectangle {
                id: iconWrapper
                width: 44; height: 44; radius: 22
                color: toastWindow.theme ? toastWindow.theme.getColor("surfaceVariant") : "#34343c"
                clip: true
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                    anchors.fill: parent
                    source: toastWindow.getNotifIcon()
                    onStatusChanged: { if (status === Image.Error) source = "file://" + shellConfig.defaultAppIcon; }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: toastWindow.appName
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 10; font.bold: true
                    color: toastWindow.theme ? toastWindow.theme.getColor("primary") : "#ffb3b4"
                    elide: Text.ElideRight; Layout.fillWidth: true
                    visible: toastWindow.appName !== "" && toastWindow.appName !== toastWindow.summaryText
                }
                Text {
                    text: toastWindow.summaryText
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 12; font.bold: true
                    color: toastWindow.theme ? toastWindow.theme.getColor("onSurface") : "#f0dede"
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
                Text {
                    text: toastWindow.bodyText
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 11
                    color: toastWindow.theme ? toastWindow.theme.getColor("onSurfaceVariant") : "#8f8f9f"
                    elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap
                    Layout.fillWidth: true; visible: toastWindow.bodyText !== ""
                }
            }
        }

        ToastProgressCanvas { id: progressBar; theme: toastWindow.theme }

        MouseArea {
            id: toastMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            property real startX: 0
            property bool isDragging: false
            onEntered: { dismissTimer.stop(); progressBar.progressAnim.pause(); }
            onExited: { if (!isDragging) { progressBar.progressAnim.resume(); dismissTimer.restart(); } }
            onPressed: mouse => { startX = mouse.x; isDragging = true; dismissTimer.stop(); progressBar.progressAnim.pause(); }
            onPositionChanged: mouse => { if (isDragging) { var deltaX = mouse.x - startX; toastTranslate.x = deltaX > 0 ? deltaX : 0; } }
            onReleased: mouse => {
                if (isDragging) {
                    isDragging = false;
                    if (toastTranslate.x > 70) toastDismissAnim.start();
                    else { snapBackAnim.start(); progressBar.progressAnim.resume(); dismissTimer.restart(); }
                }
            }
            onCanceled: { if (isDragging) { isDragging = false; snapBackAnim.start(); progressBar.progressAnim.resume(); dismissTimer.restart(); } }
        }
    }

    NumberAnimation { id: snapBackAnim; target: toastTranslate; property: "x"; to: 0; duration: 200; easing.type: Easing.OutCubic }
    NumberAnimation {
        id: toastDismissAnim
        target: toastTranslate
        property: "x"
        to: contentRect.width + 50
        duration: 180
        easing.type: Easing.OutCubic
        onStopped: toastWindow.active = false
    }

    Corner {
        x: contentRect.x - 16
        y: contentRect.y + toastWindow.topOverlap
        alignRight: true
        cornerRadius: 16
        color: toastWindow.theme ? toastWindow.theme.getColor("surface") : "#1b1b1b"
        opacity: contentRect.opacity
        transform: Translate { x: toastTranslate.x }
    }

    Canvas {
        width: 16; height: 16; antialiasing: true; renderTarget: Canvas.FramebufferObject
        x: contentRect.x + contentRect.width - 16
        y: contentRect.y + contentRect.height
        opacity: contentRect.opacity
        transform: Translate { x: toastTranslate.x }
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = toastWindow.theme ? toastWindow.theme.getColor("surface") : "#1b1b1b";
            ctx.beginPath();
            ctx.moveTo(width, height);
            ctx.lineTo(width, 0);
            ctx.lineTo(0, 0);
            ctx.arc(0, height, width, Math.PI * 1.5, 0, false);
            ctx.closePath();
            ctx.fill();
        }
    }
}
