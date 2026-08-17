import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: cardItem
    width: parent ? parent.width : 400
    height: Math.max(68, notifLayout.implicitHeight + 20)

    property var theme
    property var notifItem: modelData
    property var parentList

    signal dismissRequested()

    readonly property string appName: notifItem ? (notifItem.appName || "") : ""
    readonly property string summaryText: notifItem ? (notifItem.summary || "Notification") : "Notification"
    readonly property string bodyText: notifItem ? (notifItem.body || "").replace(/\n/g, " ") : ""

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
        radius: 12
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

        RowLayout {
            id: notifLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Rectangle {
                id: iconWrapper
                width: 36
                height: 36
                radius: 18
                color: cardItem.theme.getColor("surface")
                clip: true
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                    anchors.fill: parent
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
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: cardItem.appName
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 10
                    font.bold: true
                    color: cardItem.theme.getColor("primary")
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: cardItem.appName !== "" && cardItem.appName !== cardItem.summaryText
                }

                Text {
                    text: cardItem.summaryText
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 12
                    font.bold: true
                    color: cardItem.theme.getColor("onSurface")
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: cardItem.bodyText
                    font.family: "Google Sans Flex, sans-serif"
                    font.pixelSize: 11
                    color: cardItem.theme.getColor("onSurfaceVariant")
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    visible: cardItem.bodyText !== ""
                }
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        property real startX: 0
        property bool isDragging: false

        onPressed: mouse => {
            startX = dragArea.mapToItem(cardItem, mouse.x, mouse.y).x;
            isDragging = true;
            if (cardItem.parentList) cardItem.parentList.interactive = false;
        }

        onPositionChanged: mouse => {
            if (isDragging) {
                var currentX = dragArea.mapToItem(cardItem, mouse.x, mouse.y).x;
                var deltaX = currentX - startX;
                if (deltaX > 5) {
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
