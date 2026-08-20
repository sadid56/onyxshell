import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

Rectangle {
    id: cardItem
    width: parent ? parent.width : 400
    height: Math.max(68, notifMainCol.implicitHeight + 24)

    property var theme
    property var notifItem: modelData
    property var parentList
    property bool expanded: false
    property bool copiedFeedback: false
    property alias feedbackTimer: feedbackTimer

    signal dismissRequested()
    signal toggleExpandedRequested()

    readonly property string notifId: notifItem ? (notifItem.notifId || "") : ""
    readonly property string appName: notifItem ? (notifItem.appName || "") : ""
    readonly property string summaryText: notifItem ? (notifItem.summary || "Notification") : "Notification"
    readonly property string bodyText: notifItem ? (notifItem.body || "") : ""

    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Timer {
        id: expandScrollTimer
        interval: 40
        repeat: false
        onTriggered: {
            if (cardItem.expanded && parentList && typeof parentList.ensureVisible === "function") {
                parentList.ensureVisible(cardItem.y, Math.max(160, notifMainCol.implicitHeight + 24));
            }
        }
    }

    onExpandedChanged: { if (expanded) expandScrollTimer.restart(); }

    function getNotifIcon() {
        if (!notifItem) return "file://" + shellConfig.defaultAppIcon;
        var ic = notifItem.appIcon || "";
        if (!ic) return "file://" + shellConfig.defaultAppIcon;
        return ic.indexOf("/") === 0 ? ("file://" + ic) : ic;
    }

    function startDismiss() {
        if (!dismissAnim.running) dismissAnim.start();
    }

    radius: 16
    color: cardItem.theme.getColor("surfaceVariant")
    border.width: 0
    opacity: Math.max(0.0, 1.0 - Math.abs(cardTranslate.x) / (cardItem.width * 0.7))

    transform: Translate {
        id: cardTranslate
        x: 0
        y: 14
    }

    Component.onCompleted: entranceAnim.start()

    NumberAnimation {
        id: entranceAnim
        target: cardTranslate
        property: "y"
        to: 0
        duration: 220
        easing.type: Easing.OutBack
        easing.overshoot: 1.3
    }

    ColumnLayout {
        id: notifMainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 10

        NotifHeaderContent {
            cardItem: cardItem
            theme: cardItem.theme
        }

        NotifActionsRow {
            cardItem: cardItem
            theme: cardItem.theme
        }
    }

    Timer {
        id: feedbackTimer
        interval: 1500
        onTriggered: cardItem.copiedFeedback = false
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: -1

        property real startX: 0
        property real startY: 0
        property bool isDragging: false

        onPressed: mouse => {
            startX = mouse.x;
            startY = mouse.y;
            isDragging = false;
        }

        onPositionChanged: mouse => {
            var deltaX = mouse.x - startX;
            var deltaY = mouse.y - startY;
            if (!isDragging && Math.abs(deltaX) > 12 && Math.abs(deltaX) > Math.abs(deltaY) * 1.5) {
                isDragging = true;
                if (cardItem.parentList) cardItem.parentList.interactive = false;
            }
            if (isDragging) cardTranslate.x = deltaX > 0 ? deltaX : 0;
        }

        onReleased: mouse => {
            if (isDragging) {
                isDragging = false;
                if (cardItem.parentList) cardItem.parentList.interactive = true;
                if (cardTranslate.x > (cardItem.width * 0.30)) cardItem.startDismiss();
                else snapBackAnim.start();
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

    NumberAnimation {
        id: snapBackAnim
        target: cardTranslate
        property: "x"
        to: 0
        duration: 180
        easing.type: Easing.OutCubic
    }

    ParallelAnimation {
        id: dismissAnim
        NumberAnimation { target: cardTranslate; property: "x"; to: cardItem.width + 40; duration: 180; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardItem; property: "opacity"; to: 0.0; duration: 160; easing.type: Easing.OutQuad }
        onStopped: cardItem.dismissRequested()
    }
}
