import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

Item {
    id: actionColWrapper
    Layout.fillWidth: true
    implicitHeight: cardItem.expanded ? (actionColContent.implicitHeight + 4) : 0
    Layout.preferredHeight: implicitHeight
    clip: true
    opacity: cardItem.expanded ? 1.0 : 0.0

    property var cardItem
    property var theme

    Behavior on implicitHeight { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

    ColumnLayout {
        id: actionColContent
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 10
                color: actionColWrapper.theme ? actionColWrapper.theme.getColor("surface") : "#1b1b1b"
                opacity: copyMouse.containsMouse ? 0.7 : 1.0
                Behavior on opacity { NumberAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    IconImage {
                        width: 13
                        height: 13
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(actionColWrapper.cardItem.copiedFeedback ? "actions/check.svg" : "actions/image-copy.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: actionColWrapper.cardItem.copiedFeedback ?
                                   (actionColWrapper.theme ? actionColWrapper.theme.getColor("primary") : "#ffb3b4") :
                                   (actionColWrapper.theme ? actionColWrapper.theme.getColor("onSurface") : "#f0dede")
                        }
                    }

                    Text {
                        text: actionColWrapper.cardItem.copiedFeedback ? "Copied" : "Copy"
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: actionColWrapper.cardItem.copiedFeedback ?
                               (actionColWrapper.theme ? actionColWrapper.theme.getColor("primary") : "#ffb3b4") :
                               (actionColWrapper.theme ? actionColWrapper.theme.getColor("onSurface") : "#f0dede")
                    }
                }

                MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        var toCopy = (actionColWrapper.cardItem.summaryText + (actionColWrapper.cardItem.bodyText ? "\n" + actionColWrapper.cardItem.bodyText : "")).trim();
                        Quickshell.execDetached(["wl-copy", toCopy]);
                        actionColWrapper.cardItem.copiedFeedback = true;
                        actionColWrapper.cardItem.feedbackTimer.restart();
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 10
                color: actionColWrapper.theme ? actionColWrapper.theme.getColor("surface") : "#1b1b1b"
                opacity: delMouse.containsMouse ? 0.7 : 1.0
                Behavior on opacity { NumberAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    IconImage {
                        width: 13
                        height: 13
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/dismiss.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: actionColWrapper.theme ? actionColWrapper.theme.getColor("onSurface") : "#f0dede"
                        }
                    }

                    Text {
                        text: "Dismiss"
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: actionColWrapper.theme ? actionColWrapper.theme.getColor("onSurface") : "#f0dede"
                    }
                }

                MouseArea {
                    id: delMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: actionColWrapper.cardItem.startDismiss()
                }
            }
        }
    }
}
