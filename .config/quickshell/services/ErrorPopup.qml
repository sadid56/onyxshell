import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../components/containers"

Popup {
    id: errorWindow

    popupWidth: 420
    popupHeight: Math.min(500, mainLayout.implicitHeight + 44)

    contentRectX: 30

    closeOnHoverOutside: false
    showCorners: true

    property string errorText: ""
    property bool isCopied: false

    Connections {
        target: Quickshell

        function onReloadFailed(error) {
            Quickshell.inhibitReloadPopup();
            errorWindow.errorText = error || "Failed to load configuration.";
            errorWindow.active = true;
        }

        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
            errorWindow.active = false;
        }
    }

    Timer {
        id: copyTimer
        interval: 1800
        running: false
        repeat: false
        onTriggered: {
            errorWindow.isCopied = false;
        }
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: Qt.rgba(errorWindow.theme.getColor("error").r, errorWindow.theme.getColor("error").g, errorWindow.theme.getColor("error").b, 0.15)
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("alert.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: errorWindow.theme.getColor("error")
                    }
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Configuration Error"
                    font.family: "Noto Sans"
                    font.pixelSize: 13
                    font.bold: true
                    color: errorWindow.theme.getColor("onSurface")
                }

                Text {
                    text: "Reload failed, system reverted to last safe config."
                    font.family: "Noto Sans"
                    font.pixelSize: 9
                    color: errorWindow.theme.getColor("outline")
                }
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: closeHoverArea.containsMouse ? Qt.rgba(errorWindow.theme.getColor("outline").r, errorWindow.theme.getColor("outline").g, errorWindow.theme.getColor("outline").b, 0.1) : "transparent"
                Layout.alignment: Qt.AlignTop
                Behavior on color { ColorAnimation { duration: 150 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("dismiss.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: errorWindow.theme.getColor("outline")
                    }
                }

                MouseArea {
                    id: closeHoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: errorWindow.active = false
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(300, errorMsgText.implicitHeight + 24)
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.25)
            border.width: 1
            border.color: Qt.rgba(errorWindow.theme.getColor("outline").r, errorWindow.theme.getColor("outline").g, errorWindow.theme.getColor("outline").b, 0.15)
            clip: true

            ScrollView {
                anchors.fill: parent
                anchors.margins: 12
                clip: true

                Text {
                    id: errorMsgText
                    width: parent.width - 24
                    text: errorWindow.errorText
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 11
                    color: errorWindow.theme.getColor("onErrorContainer") || "#ffb4ab"
                    wrapMode: Text.WrapAnywhere
                    textFormat: Text.PlainText
                    lineHeight: 1.2
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                id: copyBtn
                Layout.fillWidth: true
                height: 34
                radius: 8
                color: copyBtnHover.containsMouse
                    ? Qt.rgba(errorWindow.theme.getColor("surfaceVariant").r, errorWindow.theme.getColor("surfaceVariant").g, errorWindow.theme.getColor("surfaceVariant").b, 0.8)
                    : errorWindow.theme.getColor("surfaceVariant")
                border.width: 1
                border.color: errorWindow.theme.getColor("outline")
                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    IconImage {
                        width: 14
                        height: 14
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(errorWindow.isCopied ? "check.svg" : "image-copy.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: errorWindow.isCopied ? errorWindow.theme.getColor("primary") : errorWindow.theme.getColor("onSurface")
                        }
                    }

                    Text {
                        text: errorWindow.isCopied ? "Copied!" : "Copy Error"
                        font.family: "Noto Sans"
                        font.pixelSize: 11
                        font.bold: true
                        color: errorWindow.isCopied ? errorWindow.theme.getColor("primary") : errorWindow.theme.getColor("onSurface")
                    }
                }

                MouseArea {
                    id: copyBtnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy", "copy-error", errorWindow.errorText]);
                        errorWindow.isCopied = true;
                        copyTimer.restart();
                    }
                }
            }

            Rectangle {
                id: dismissBtn
                Layout.preferredWidth: 100
                height: 34
                radius: 8
                color: dismissBtnHover.containsMouse
                    ? Qt.rgba(errorWindow.theme.getColor("error").r, errorWindow.theme.getColor("error").g, errorWindow.theme.getColor("error").b, 0.8)
                    : errorWindow.theme.getColor("error")
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "Dismiss"
                    font.family: "Noto Sans"
                    font.pixelSize: 11
                    font.bold: true
                    color: errorWindow.theme.getColor("onError") || "white"
                }

                MouseArea {
                    id: dismissBtnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: errorWindow.active = false
                }
            }
        }
    }
}
