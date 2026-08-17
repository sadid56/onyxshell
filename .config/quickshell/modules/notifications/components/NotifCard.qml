import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

Item {
    id: cardItem
    width: parent ? parent.width : 400
    height: Math.max(68, notifMainCol.implicitHeight + 24)

    property var theme
    property var notifItem: modelData
    property var parentList
    property bool expanded: false
    property bool copiedFeedback: false

    signal dismissRequested()
    signal toggleExpandedRequested()

    readonly property string notifId: notifItem ? (notifItem.notifId || "") : ""
    readonly property string appName: notifItem ? (notifItem.appName || "") : ""
    readonly property string summaryText: notifItem ? (notifItem.summary || "Notification") : "Notification"
    readonly property string bodyText: notifItem ? (notifItem.body || "") : ""

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Timer {
        id: expandScrollTimer
        interval: 40
        repeat: false
        onTriggered: {
            if (cardItem.expanded && parentList && typeof parentList.ensureVisible === "function") {
                var targetH = Math.max(160, notifMainCol.implicitHeight + 24);
                parentList.ensureVisible(cardItem.y, targetH);
            }
        }
    }

    onExpandedChanged: {
        if (expanded) {
            expandScrollTimer.restart();
        }
    }

    function getNotifIcon() {
        if (!notifItem) return "file://" + shellConfig.defaultAppIcon;
        var ic = notifItem.appIcon || "";
        if (!ic) return "file://" + shellConfig.defaultAppIcon;
        if (ic.indexOf("/") === 0) return "file://" + ic;
        return ic;
    }

    function startDismiss() {
        if (dismissAnim.running) return;
        dismissAnim.start();
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 16
        color: cardItem.theme.getColor("surfaceVariant")
        border.width: 0
        opacity: Math.max(0.0, 1.0 - Math.abs(cardTranslate.x) / (cardItem.width * 0.7))

        transform: Translate {
            id: cardTranslate
            x: 0
            y: 14
        }

        Component.onCompleted: {
            entranceAnim.start();
        }

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

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ClippingRectangle {
                    id: iconWrapper
                    width: 38
                    height: 38
                    radius: 19
                    color: cardItem.theme.getColor("surface")
                    Layout.alignment: Qt.AlignTop

                    IconImage {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: cardItem.getNotifIcon()
                        onStatusChanged: {
                            if (status === Image.Error) {
                                source = "file://" + shellConfig.defaultAppIcon;
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: cardItem.appName
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 10
                        font.bold: true
                        color: cardItem.theme ? cardItem.theme.getColor("primary") : "#ffb3b4"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: cardItem.appName !== "" && cardItem.appName !== cardItem.summaryText
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: cardItem.summaryText
                            font.family: "Google Sans Flex, sans-serif"
                            font.pixelSize: 13
                            font.bold: true
                            color: cardItem.theme.getColor("onSurface")
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: cardItem.theme ? cardItem.theme.getColor("surface") : "#1b1b1b"
                            opacity: arrowMouse.containsMouse ? 0.7 : 1.0
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            IconImage {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("chevron-down.svg")
                                rotation: cardItem.expanded ? 180 : 0
                                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: cardItem.theme ? cardItem.theme.getColor("onSurface") : "#f0dede"
                                }
                            }

                            MouseArea {
                                id: arrowMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: cardItem.toggleExpandedRequested()
                            }
                        }
                    }

                    Text {
                        text: cardItem.bodyText
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 11
                        color: cardItem.theme.getColor("onSurfaceVariant")
                        elide: cardItem.expanded ? Text.ElideNone : Text.ElideRight
                        maximumLineCount: cardItem.expanded ? 8 : 2
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        visible: cardItem.bodyText !== ""
                    }
                }
            }

            RowLayout {
                id: actionRow
                Layout.fillWidth: true
                spacing: 10
                visible: cardItem.expanded
                opacity: cardItem.expanded ? 1.0 : 0.0

                Behavior on opacity { NumberAnimation { duration: 140 } }

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 12
                    color: cardItem.theme ? cardItem.theme.getColor("surface") : "#1b1b1b"
                    opacity: delMouse.containsMouse ? 0.7 : 1.0

                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        IconImage {
                            width: 14
                            height: 14
                            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("dismiss.svg")
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: cardItem.theme ? cardItem.theme.getColor("onSurface") : "#f0dede"
                            }
                        }
                    }

                    MouseArea {
                        id: delMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: cardItem.startDismiss()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 12
                    color: cardItem.theme ? cardItem.theme.getColor("surface") : "#1b1b1b"
                    opacity: copyMouse.containsMouse ? 0.7 : 1.0

                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        IconImage {
                            width: 14
                            height: 14
                            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(cardItem.copiedFeedback ? "check.svg" : "image-copy.svg")
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: cardItem.copiedFeedback ?
                                       (cardItem.theme ? cardItem.theme.getColor("primary") : "#ffb3b4") :
                                       (cardItem.theme ? cardItem.theme.getColor("onSurface") : "#f0dede")
                            }
                        }
                    }

                    MouseArea {
                        id: copyMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            var toCopy = (cardItem.summaryText + (cardItem.bodyText ? "\n" + cardItem.bodyText : "")).trim();
                            Quickshell.execDetached(["wl-copy", toCopy]);
                            cardItem.copiedFeedback = true;
                            feedbackTimer.restart();
                        }
                    }
                }
            }
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
            if (isDragging) {
                if (deltaX > 0) {
                    cardTranslate.x = deltaX;
                } else {
                    cardTranslate.x = 0;
                }
            }
        }

        onReleased: mouse => {
            if (isDragging) {
                isDragging = false;
                if (cardItem.parentList) cardItem.parentList.interactive = true;
                var threshold = cardItem.width * 0.30;
                if (cardTranslate.x > threshold) {
                    cardItem.startDismiss();
                } else {
                    snapBackAnim.start();
                }
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
        NumberAnimation {
            target: cardTranslate
            property: "x"
            to: cardItem.width + 40
            duration: 180
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0.0
            duration: 160
            easing.type: Easing.OutQuad
        }
        onStopped: {
            cardItem.dismissRequested();
        }
    }
}
