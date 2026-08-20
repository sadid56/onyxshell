import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

RowLayout {
    id: actionRow
    Layout.fillWidth: true
    spacing: 10
    visible: cardItem.expanded
    opacity: cardItem.expanded ? 1.0 : 0.0

    property var cardItem
    property var theme

    Behavior on opacity { NumberAnimation { duration: 140 } }

    Rectangle {
        Layout.fillWidth: true
        height: 38
        radius: 12
        color: actionRow.theme ? actionRow.theme.getColor("surface") : "#1b1b1b"
        opacity: delMouse.containsMouse ? 0.7 : 1.0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        IconImage {
            anchors.centerIn: parent
            width: 14
            height: 14
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("dismiss.svg")
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: actionRow.theme ? actionRow.theme.getColor("onSurface") : "#f0dede"
            }
        }

        MouseArea {
            id: delMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: actionRow.cardItem.startDismiss()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 38
        radius: 12
        color: actionRow.theme ? actionRow.theme.getColor("surface") : "#1b1b1b"
        opacity: copyMouse.containsMouse ? 0.7 : 1.0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        IconImage {
            anchors.centerIn: parent
            width: 14
            height: 14
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(actionRow.cardItem.copiedFeedback ? "check.svg" : "image-copy.svg")
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: actionRow.cardItem.copiedFeedback ?
                       (actionRow.theme ? actionRow.theme.getColor("primary") : "#ffb3b4") :
                       (actionRow.theme ? actionRow.theme.getColor("onSurface") : "#f0dede")
            }
        }

        MouseArea {
            id: copyMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                var toCopy = (actionRow.cardItem.summaryText + (actionRow.cardItem.bodyText ? "\n" + actionRow.cardItem.bodyText : "")).trim();
                Quickshell.execDetached(["wl-copy", toCopy]);
                actionRow.cardItem.copiedFeedback = true;
                actionRow.cardItem.feedbackTimer.restart();
            }
        }
    }
}
