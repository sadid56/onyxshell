import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../../../components/ui" as UI

Rectangle {
    id: cardItem
    width: parent ? parent.width : 360
    Layout.fillWidth: true
    implicitHeight: notifMainCol.implicitHeight + 20
    Layout.preferredHeight: implicitHeight
    height: implicitHeight
    radius: 14
    color: cardItem.theme ? cardItem.theme.getColor("surface") : "#1e1e1e"
    border.width: 0
    opacity: 1.0
    clip: true

    property var theme
    property var notifItem: modelData
    property var parentList
    property bool expanded: false
    property bool copiedFeedback: false
    property alias feedbackTimer: feedbackTimer

    signal dismissRequested()
    signal toggleExpandedRequested()
    onToggleExpandedRequested: cardItem.expanded = !cardItem.expanded

    readonly property string notifId: notifItem ? (notifItem.notifId || "") : ""
    readonly property string appName: notifItem ? (notifItem.appName || "") : ""
    readonly property string summaryText: notifItem ? (notifItem.summary || "Notification") : "Notification"
    readonly property string bodyText: notifItem ? (notifItem.body || "") : ""

    function getNotifIcon() {
        if (!notifItem) return "file://" + shellConfig.defaultAppIcon;
        var ic = notifItem.appIcon || "";
        if (!ic) return "file://" + shellConfig.defaultAppIcon;
        return ic.indexOf("/") === 0 ? ("file://" + ic) : ic;
    }

    function redirectToApp() {
        var raw = notifItem ? notifItem.rawNotif : null;
        if (raw) {
            var invoked = false;
            if (raw.actions && raw.actions.length > 0) {
                for (var i = 0; i < raw.actions.length; i++) {
                    var act = raw.actions[i];
                    if (act && (act.id === "default" || act.id === "0" || act.id === "default-action" || act.id === "open" || act.text === "Open" || act.text === "Default")) {
                        try { act.invoke(); invoked = true; } catch(e) {}
                        break;
                    }
                }
                if (!invoked && raw.actions[0]) {
                    try { raw.actions[0].invoke(); invoked = true; } catch(e) {}
                }
            }
            if (!invoked) {
                if (typeof raw.invokeDefault === "function") {
                    try { raw.invokeDefault(); } catch(e) {}
                } else if (typeof raw.invoke === "function") {
                    try { raw.invoke("default"); } catch(e) {}
                }
            }
        }

        var app = appName || "";
        var summary = summaryText || "";
        var body = bodyText || "";
        var cfg = (typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : ((typeof root !== "undefined" && root) ? root.shellConfig : null);
        var home = (cfg && cfg.homeDir) ? cfg.homeDir : Quickshell.env("HOME");
        var scriptPath = cfg ? cfg.getScript("focus_app.sh") : (home + "/.config/quickshell/scripts/focus_app.sh");
        Quickshell.execDetached([scriptPath, app, summary, body]);
    }

    function startDismiss() {
        if (!dismissAnim.running) dismissAnim.start();
    }

    transform: Translate {
        id: cardTranslate
        x: 0
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: 0
        property real startX: 0
        property real startY: 0
        property bool isDragging: false

        onPressed: mouse => {
            startX = mouse.x;
            startY = mouse.y;
            isDragging = false;
        }

        onPositionChanged: mouse => {
            if (mouse.buttons & Qt.LeftButton) {
                var deltaX = mouse.x - startX;
                var deltaY = mouse.y - startY;
                if (!isDragging && Math.abs(deltaX) > 8 && Math.abs(deltaX) > Math.abs(deltaY)) {
                    isDragging = true;
                    if (cardItem.parentList) cardItem.parentList.interactive = false;
                }
                if (isDragging) {
                    cardTranslate.x = deltaX > 0 ? deltaX : 0;
                    cardItem.opacity = Math.max(0.0, 1.0 - cardTranslate.x / (cardItem.width * 0.75));
                }
            }
        }

        onReleased: mouse => {
            if (isDragging) {
                isDragging = false;
                if (cardItem.parentList) cardItem.parentList.interactive = true;
                if (cardTranslate.x > 60) cardItem.startDismiss();
                else snapBackAnim.start();
            } else if (Math.abs(cardTranslate.x) < 5) {
                cardItem.redirectToApp();
            }
        }

        onCanceled: {
            if (isDragging) {
                isDragging = false;
                if (cardItem.parentList) cardItem.parentList.interactive = true;
                snapBackAnim.start();
            }
        }
    }

    ColumnLayout {
        id: notifMainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        spacing: 8
        z: 1

        NotifHeaderContent {
            id: headerContent
            cardItem: cardItem
            theme: cardItem.theme
        }

        NotifActionsRow {
            cardItem: cardItem
            theme: cardItem.theme
            z: 2
        }
    }

    Timer {
        id: feedbackTimer
        interval: 1500
        onTriggered: cardItem.copiedFeedback = false
    }

    ParallelAnimation {
        id: snapBackAnim
        NumberAnimation { target: cardTranslate; property: "x"; to: 0; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { target: cardItem; property: "opacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: dismissAnim
        NumberAnimation { target: cardTranslate; property: "x"; to: cardItem.width + 30; duration: 150; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardItem; property: "opacity"; to: 0.0; duration: 120; easing.type: Easing.OutQuad }
        onStopped: cardItem.dismissRequested()
    }
}
