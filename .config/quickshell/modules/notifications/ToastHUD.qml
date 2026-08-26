import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../bar/widgets"
import "./components"

PanelWindow {
    id: toastWindow
    anchors { top: true; left: true; right: true }
    implicitHeight: 200
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0
    mask: Region { item: contentRect }

    property var theme
    property bool active: false
    property var currentNotification: null
    readonly property int toastRadius: 22

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
        var cfg = (typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : ((typeof root !== "undefined" && root) ? root.shellConfig : null);
        var home = (cfg && cfg.homeDir) ? cfg.homeDir : Quickshell.env("HOME");
        var scriptPath = cfg ? cfg.getScript("focus_app.sh") : (home + "/.config/quickshell/scripts/focus_app.sh");
        Quickshell.execDetached([scriptPath, app, summary, body]);
    }

    visible: active || enterAnim.running || exitAnim.running || contentRect.opacity > 0.0

    Timer {
        id: dismissTimer
        interval: 4000
        running: false
        repeat: false
        onTriggered: {
            if (!toastSwipeArea.containsMouse && !toastSwipeArea.isDragging) {
                exitAnim.start();
            }
        }
    }

    function showToast(notification) {
        exitAnim.stop();
        currentNotification = notification;
        dismissTimer.stop();
        active = true;
        contentRect.y = -contentRect.height - 30;
        contentRect.opacity = 0.0;
        contentRect.scale = 0.88;
        enterAnim.restart();
        if (progressBar && progressBar.progressAnim) {
            progressBar.progressAnim.stop();
            progressBar.progress = 1.0;
            progressBar.progressAnim.start();
        }
        dismissTimer.start();
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation {
            target: contentRect
            property: "y"
            from: -contentRect.height - 30
            to: 0
            duration: 380
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: contentRect
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 250
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: contentRect
            property: "scale"
            from: 0.88
            to: 1.0
            duration: 380
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation {
            target: contentRect
            property: "y"
            to: -contentRect.height - 30
            duration: 240
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: contentRect
            property: "opacity"
            to: 0.0
            duration: 200
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: contentRect
            property: "scale"
            to: 0.88
            duration: 240
            easing.type: Easing.InCubic
        }
        onStopped: {
            toastWindow.active = false;
        }
    }

    Rectangle {
        id: contentRect
        anchors.horizontalCenter: parent.horizontalCenter
        y: -height - 30
        width: Math.min(470, parent.width - 32)
        height: Math.max(70, notifRow.implicitHeight + 16)
        radius: toastWindow.toastRadius
        color: toastWindow.theme ? toastWindow.theme.getColor("surface") : "#1b1b1b"
        border.width: 1
        border.color: Qt.rgba(toastWindow.theme ? toastWindow.theme.getColor("outline").r : 1, toastWindow.theme ? toastWindow.theme.getColor("outline").g : 1, toastWindow.theme ? toastWindow.theme.getColor("outline").b : 1, 0.12)
        opacity: 0.0
        scale: 0.88
        transformOrigin: Item.Top

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.radius
            color: parent.color
        }

        Corner {
            anchors.top: parent.top
            anchors.right: parent.left
            anchors.rightMargin: -0.5
            alignRight: true
            cornerRadius: toastWindow.toastRadius
            color: toastWindow.theme ? toastWindow.theme.getColor("surface") : "#1b1b1b"
        }

        Corner {
            anchors.top: parent.top
            anchors.left: parent.right
            anchors.leftMargin: -0.5
            alignRight: false
            cornerRadius: toastWindow.toastRadius
            color: toastWindow.theme ? toastWindow.theme.getColor("surface") : "#1b1b1b"
        }

        RowLayout {
            id: notifRow
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 10
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Item {
                id: iconContainer
                width: 48
                height: 48
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: iconWrapper
                    anchors.centerIn: parent
                    width: 38
                    height: 38
                    radius: 19
                    color: toastWindow.theme ? toastWindow.theme.getColor("surfaceVariant") : "#34343c"
                    clip: true

                    IconImage {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: toastWindow.getNotifIcon()
                        onStatusChanged: { if (status === Image.Error) source = "file://" + shellConfig.defaultAppIcon; }
                    }
                }

                ToastProgressCanvas {
                    id: progressBar
                    anchors.fill: parent
                    theme: toastWindow.theme
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

        MouseArea {
            id: toastSwipeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            property real startY: 0
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
                startY = mouse.y;
                isDragging = false;
                dismissTimer.stop();
                if (progressBar && progressBar.progressAnim && progressBar.progressAnim.running) {
                    progressBar.progressAnim.pause();
                }
            }
            onPositionChanged: mouse => {
                if (mouse.buttons & Qt.LeftButton) {
                    var deltaY = mouse.y - startY;
                    if (!isDragging && Math.abs(deltaY) > 6) isDragging = true;
                    if (isDragging && deltaY < -20) {
                        exitAnim.start();
                    }
                }
            }
            onReleased: mouse => {
                if (isDragging) {
                    isDragging = false;
                } else {
                    toastWindow.redirectToApp();
                    exitAnim.start();
                }
            }
            onCanceled: {
                isDragging = false;
            }
        }
    }
}
