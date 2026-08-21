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
    mask: Region { item: staticMaskArea }

    Item {
        id: staticMaskArea
        x: 0
        y: 0
        width: 416
        height: 180
    }

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

    function redirectToApp() {
        if (!currentNotification) return;

        var invoked = false;
        if (currentNotification.actions && currentNotification.actions.length > 0) {
            for (var i = 0; i < currentNotification.actions.length; i++) {
                var act = currentNotification.actions[i];
                if (act && (act.id === "default" || act.id === "0" || act.id === "default-action" || act.id === "open" || act.text === "Open" || act.text === "Default")) {
                    try { act.invoke(); invoked = true; } catch(e) {}
                    break;
                }
            }
            if (!invoked && currentNotification.actions[0]) {
                try { currentNotification.actions[0].invoke(); invoked = true; } catch(e) {}
            }
        }
        if (!invoked) {
            if (typeof currentNotification.invokeDefault === "function") {
                try { currentNotification.invokeDefault(); } catch(e) {}
            } else if (typeof currentNotification.invoke === "function") {
                try { currentNotification.invoke("default"); } catch(e) {}
            }
        }

        var app = toastWindow.appName || "";
        var summary = toastWindow.summaryText || "";
        var body = toastWindow.bodyText || "";
        var scriptPath = (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getScript("focus_app.sh");
        Quickshell.execDetached([scriptPath, app, summary, body]);
    }

    visible: active || toastDismissAnim.running
    onActiveChanged: {
        if (!active && !toastDismissAnim.running) {
            toastTranslate.x = 0;
            contentRect.opacity = 0.0;
        }
    }

    Timer {
        id: dismissTimer
        interval: 4000
        running: false
        repeat: false
        onTriggered: {
            if (!toastSwipeArea.containsMouse && !toastSwipeArea.isDragging) {
                toastDismissAnim.start();
            }
        }
    }

    function showToast(notification) {
        toastDismissAnim.stop();
        snapBackAnim.stop();
        currentNotification = notification;
        toastTranslate.x = 0;
        contentRect.opacity = 1.0;
        dismissTimer.stop();
        active = true;
        if (progressBar && progressBar.progressAnim) {
            progressBar.progressAnim.stop();
            progressBar.progress = 1.0;
            progressBar.progressAnim.start();
        }
        dismissTimer.start();
    }

    Rectangle {
        id: contentRect
        x: 16
        y: -toastWindow.topOverlap
        width: 400
        height: Math.max(84, notifRow.implicitHeight + toastWindow.topOverlap + 24)
        radius: toastWindow.toastRadius
        clip: true
        color: toastWindow.theme ? toastWindow.theme.getColor("surface") : "#1b1b1b"
        border.width: 0
        opacity: 0.0
        transform: Translate {
            id: toastTranslate
            x: 0
        }

        Rectangle {
            anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
            width: parent.radius
            color: parent.color
        }

        // Notification Content Row
        RowLayout {
            id: notifRow
            anchors.top: parent.top
            anchors.topMargin: toastWindow.topOverlap + 12
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 16
            spacing: 12

            Rectangle {
                id: iconWrapper
                width: 44
                height: 44
                radius: 22
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
                    font.pixelSize: 10
                    font.bold: true
                    color: toastWindow.theme ? toastWindow.theme.getColor("primary") : "#ffb3b4"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: toastWindow.appName !== "" && toastWindow.appName !== toastWindow.summaryText
                }

                Text {
                    text: toastWindow.summaryText
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 12
                    font.bold: true
                    color: toastWindow.theme ? toastWindow.theme.getColor("onSurface") : "#f0dede"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: toastWindow.bodyText
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 11
                    color: toastWindow.theme ? toastWindow.theme.getColor("onSurfaceVariant") : "#8f8f9f"
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    visible: toastWindow.bodyText !== ""
                }
            }
        }

        ToastProgressCanvas {
            id: progressBar
            theme: toastWindow.theme
        }

        // Clickable & Swipeable Mouse Area
        MouseArea {
            id: toastSwipeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            property real startX: 0
            property bool isDragging: false

            onEntered: {
                dismissTimer.stop();
                if (progressBar && progressBar.progressAnim && progressBar.progressAnim.running) {
                    progressBar.progressAnim.pause();
                }
            }
            onExited: {
                if (!isDragging) {
                    if (progressBar && progressBar.progressAnim && progressBar.progressAnim.paused) {
                        progressBar.progressAnim.resume();
                    }
                    dismissTimer.restart();
                }
            }
            onPressed: mouse => {
                startX = mouse.x;
                isDragging = false;
                dismissTimer.stop();
                if (progressBar && progressBar.progressAnim && progressBar.progressAnim.running) {
                    progressBar.progressAnim.pause();
                }
            }
            onPositionChanged: mouse => {
                if (mouse.buttons & Qt.LeftButton) {
                    var deltaX = mouse.x - startX;
                    if (!isDragging && Math.abs(deltaX) > 8) isDragging = true;
                    if (isDragging) {
                        toastTranslate.x = deltaX > 0 ? deltaX : 0;
                        contentRect.opacity = Math.max(0.0, 1.0 - toastTranslate.x / 260.0);
                    }
                }
            }
            onReleased: mouse => {
                if (isDragging) {
                    isDragging = false;
                    if (toastTranslate.x > 60) {
                        toastDismissAnim.start();
                    } else {
                        snapBackAnim.start();
                        if (progressBar && progressBar.progressAnim && progressBar.progressAnim.paused) {
                            progressBar.progressAnim.resume();
                        }
                        dismissTimer.restart();
                    }
                } else {
                    toastWindow.redirectToApp();
                    toastDismissAnim.start();
                }
            }
            onCanceled: {
                if (isDragging) {
                    isDragging = false;
                    snapBackAnim.start();
                    if (progressBar && progressBar.progressAnim && progressBar.progressAnim.paused) {
                        progressBar.progressAnim.resume();
                    }
                    dismissTimer.restart();
                }
            }
        }
    }

    ParallelAnimation {
        id: snapBackAnim
        NumberAnimation { target: toastTranslate; property: "x"; to: 0; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { target: contentRect; property: "opacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: toastDismissAnim
        NumberAnimation { target: toastTranslate; property: "x"; to: contentRect.width + 40; duration: 160; easing.type: Easing.OutQuad }
        NumberAnimation { target: contentRect; property: "opacity"; to: 0.0; duration: 140; easing.type: Easing.OutQuad }
        onStopped: {
            toastWindow.active = false;
            toastTranslate.x = 0;
        }
    }

    // Top-Left Seamless Inverted Corner
    Corner {
        x: contentRect.x - 16
        y: contentRect.y + toastWindow.topOverlap
        alignRight: true
        cornerRadius: 16
        color: toastWindow.theme ? toastWindow.theme.getColor("surface") : "#1b1b1b"
        opacity: contentRect.opacity
        transform: Translate { x: toastTranslate.x }
    }

    // Bottom-Right Seamless Inverted Canvas Curve
    Canvas {
        width: 16
        height: 16
        antialiasing: true
        renderTarget: Canvas.Image
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
