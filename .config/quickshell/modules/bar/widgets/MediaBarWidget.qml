import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../components/ui" as UI

Item {
    id: mediaBarRoot

    property var theme
    property var mediaService
    property var toggleMedia
    property bool showDivider: false

    readonly property bool isPlaying: mediaBarRoot.mediaService ? Boolean(mediaBarRoot.mediaService.isPlaying) : false
    readonly property bool hasMedia: mediaBarRoot.mediaService ? Boolean(mediaBarRoot.mediaService.hasMedia) : false

    implicitHeight: 28
    implicitWidth: hasMedia ? Math.min(240, contentRow.implicitWidth + 12) : 0
    visible: opacity > 0.001
    opacity: hasMedia ? 1.0 : 0.0
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

    Layout.alignment: Qt.AlignVCenter

    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            if (typeof root !== "undefined" && root.stopLoaderTimerAndActivate && typeof mediaLoader !== "undefined" && typeof statusBar !== "undefined") {
                root.stopLoaderTimerAndActivate(mediaLoader, statusBar.getMediaX());
            }
        }
        onExited: {
            if (typeof root !== "undefined" && root.restartLoaderTimer && typeof mediaLoader !== "undefined") {
                root.restartLoaderTimer(mediaLoader);
            }
        }
        onClicked: {
            if (mediaBarRoot.toggleMedia) {
                mediaBarRoot.toggleMedia();
            } else if (typeof root !== "undefined" && root.toggleLoaderActive && typeof mediaLoader !== "undefined" && typeof statusBar !== "undefined") {
                root.toggleLoaderActive(mediaLoader, statusBar.getMediaX());
            }
        }
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 4
        spacing: 8

        Rectangle {
            visible: mediaBarRoot.showDivider
            width: 1
            height: 16
            radius: 0.5
            color: mediaBarRoot.theme ? mediaBarRoot.theme.getColor("outline") : "#9f8c8c"
            opacity: 0.45
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 2
        }

        Row {
            spacing: 2
            height: 14
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: [
                    { minH: 3, maxH: 13, dur: 450 },
                    { minH: 5, maxH: 15, dur: 360 },
                    { minH: 3, maxH: 12, dur: 520 },
                    { minH: 4, maxH: 14, dur: 410 }
                ]
                delegate: Rectangle {
                    id: eqBar
                    width: 3
                    radius: 1.5
                    anchors.bottom: parent.bottom
                    color: mediaBarRoot.theme
                        ? (mediaBarRoot.isPlaying ? mediaBarRoot.theme.getColor("primary") : mediaBarRoot.theme.getColor("outline"))
                        : "#adc6ff"
                    opacity: mediaBarRoot.isPlaying ? 1.0 : 0.5

                    height: mediaBarRoot.isPlaying ? modelData.maxH : 3

                    SequentialAnimation on height {
                        loops: Animation.Infinite
                        running: mediaBarRoot.isPlaying
                        NumberAnimation { from: modelData.minH; to: modelData.maxH; duration: modelData.dur; easing.type: Easing.InOutSine }
                        NumberAnimation { from: modelData.maxH; to: modelData.minH; duration: modelData.dur; easing.type: Easing.InOutSine }
                    }

                    Behavior on height {
                        enabled: !mediaBarRoot.isPlaying
                        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        UI.Typography {
            theme: mediaBarRoot.theme
            Layout.fillWidth: true
            Layout.maximumWidth: 170
            Layout.alignment: Qt.AlignVCenter
            text: {
                if (!mediaBarRoot.mediaService) return "";
                var t = mediaBarRoot.mediaService.mediaTitle || "";
                var a = mediaBarRoot.mediaService.mediaArtist || "";
                if (t === "No media playing" || t === "") return "";
                return a ? (t + " • " + a) : t;
            }
            variant: "bodyMedium"
            font.bold: true
            colorRole: mediaBarRoot.isPlaying ? "onSurface" : "outline"
            opacity: mediaBarRoot.isPlaying ? 1.0 : 0.65
            elide: Text.ElideRight
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
