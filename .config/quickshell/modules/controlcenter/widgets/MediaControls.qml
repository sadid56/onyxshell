import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

ClippingRectangle {
    id: mediaRoot
    Layout.fillWidth: true
    height: 120
    radius: 18
    color: mediaRoot.theme ? mediaRoot.theme.getColor("surfaceVariant") : "#2b2a27"

    property var theme
    property var mediaService: null

    property string mediaStatus: mediaService ? mediaService.mediaStatus : "Stopped"
    property bool optimisticPlaying: mediaStatus === "Playing"
    onMediaStatusChanged: optimisticPlaying = (mediaStatus === "Playing")

    property string mediaTitle: mediaService ? mediaService.mediaTitle : "No media playing"
    property string mediaArtist: mediaService ? mediaService.mediaArtist : ""
    property string mediaArtUrl: mediaService ? mediaService.mediaArtUrl : ""
    property int mediaPosition: mediaService ? mediaService.mediaPosition : 0
    property int mediaLength: mediaService ? mediaService.mediaLength : 0

    readonly property bool isPlaying: optimisticPlaying
    readonly property bool hasMedia: mediaStatus !== "Stopped" && mediaTitle !== "" && mediaTitle !== "No media playing"

    signal controlAction(string action)

    function formatTime(secs) {
        if (isNaN(secs) || secs < 0) return "0:00";
        var m = Math.floor(secs / 60);
        var s = secs % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    Image {
        id: bgCoverArt
        anchors.fill: parent
        source: mediaRoot.mediaArtUrl
        fillMode: Image.PreserveAspectCrop
        opacity: 0.18
        visible: mediaRoot.hasMedia && mediaRoot.mediaArtUrl !== ""
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: mediaRoot.theme ? mediaRoot.theme.getColor("surfaceVariant") : "#2b2a27"
        opacity: (mediaRoot.hasMedia && mediaRoot.mediaArtUrl !== "") ? 0.65 : 0.0
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        ClippingRectangle {
            id: albumArtRect
            width: 78
            height: 78
            radius: 14
            color: mediaRoot.theme ? mediaRoot.theme.getColor("surface") : "#1b1b1b"
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: albumArtImage
                anchors.fill: parent
                source: mediaRoot.mediaArtUrl
                fillMode: Image.PreserveAspectCrop
                visible: mediaRoot.hasMedia && mediaRoot.mediaArtUrl !== "" && status === Image.Ready
                asynchronous: true
            }

            IconImage {
                anchors.centerIn: parent
                width: 32
                height: 32
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("music.svg")
                visible: !albumArtImage.visible
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: mediaRoot.theme ? mediaRoot.theme.getColor("primary") : "#a8c88e"
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: mediaRoot.mediaTitle
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 14
                        font.bold: true
                        color: mediaRoot.theme ? mediaRoot.theme.getColor("onSurface") : "#ffffff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: mediaRoot.mediaArtist !== "" ? mediaRoot.mediaArtist : (mediaRoot.hasMedia ? "Unknown Artist" : "")
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 11
                        color: mediaRoot.theme ? mediaRoot.theme.getColor("outline") : "#9e9e9e"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: mediaRoot.mediaLength > 0 ?
                              mediaRoot.formatTime(mediaRoot.mediaPosition) + " / " + mediaRoot.formatTime(mediaRoot.mediaLength) :
                              (mediaRoot.hasMedia ? "0:00 / 0:00" : "")
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 11
                        font.bold: true
                        color: mediaRoot.theme ? mediaRoot.theme.getColor("outline") : "#8e8e8e"
                        Layout.topMargin: 2
                    }
                }

                Rectangle {
                    width: 46
                    height: 46
                    radius: 16
                    color: mediaRoot.theme ? mediaRoot.theme.getColor("primary") : "#a8c88e"
                    Layout.alignment: Qt.AlignVCenter

                    IconImage {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(mediaRoot.isPlaying ? "pause.svg" : "play.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: mediaRoot.theme ? mediaRoot.theme.getColor("onPrimary") : "#1b2e11"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scale = 1.08
                        onExited: parent.scale = 1.0
                        onClicked: {
                            mediaRoot.optimisticPlaying = !mediaRoot.optimisticPlaying;
                            if (mediaRoot.mediaService) {
                                mediaRoot.mediaService.playPause();
                            }
                            mediaRoot.controlAction("play-pause");
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                    width: 16
                    height: 16
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("skip-back.svg")
                    opacity: 0.85
                    Layout.alignment: Qt.AlignVCenter
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: mediaRoot.theme ? mediaRoot.theme.getColor("onSurface") : "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            parent.scale = 1.25;
                            parent.opacity = 1.0;
                        }
                        onExited: {
                            parent.scale = 1.0;
                            parent.opacity = 0.85;
                        }
                        onClicked: {
                            if (mediaRoot.mediaService) {
                                mediaRoot.mediaService.previous();
                            }
                            mediaRoot.controlAction("previous");
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 120 } }
                }

                Canvas {
                    id: waveCanvas
                    Layout.fillWidth: true
                    height: 14
                    Layout.alignment: Qt.AlignVCenter

                    property real phase: 0
                    property real progressRatio: mediaRoot.mediaLength > 0 ?
                                                 Math.min(1.0, Math.max(0.0, mediaRoot.mediaPosition / mediaRoot.mediaLength)) : 0
                    property real progressX: width * progressRatio

                    onProgressXChanged: requestPaint()

                    Behavior on progressRatio {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    Timer {
                        id: waveAnimTimer
                        interval: 33
                        running: mediaRoot.isPlaying
                        repeat: true
                        onTriggered: {
                            waveCanvas.phase += 0.14;
                            waveCanvas.requestPaint();
                        }
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.clearRect(0, 0, width, height);

                        var midY = height / 2;
                        var pX = Math.min(width, Math.max(0, width * progressRatio));

                        var waveColor = mediaRoot.theme ? mediaRoot.theme.getColor("primary") : "#a8c88e";
                        var trackColor = mediaRoot.theme ? mediaRoot.theme.getColor("outline") : "#555555";

                        if (pX > 2) {
                            ctx.beginPath();
                            ctx.lineWidth = 2.5;
                            ctx.lineCap = "round";
                            ctx.strokeStyle = waveColor;

                            ctx.moveTo(0, midY);
                            var step = 2;
                            for (var x = 0; x <= pX; x += step) {
                                var wave = Math.sin(x * 0.12 - waveCanvas.phase) * 2.8;
                                ctx.lineTo(x, midY + wave);
                            }
                            ctx.stroke();

                            ctx.beginPath();
                            ctx.lineWidth = 2.5;
                            ctx.strokeStyle = waveColor;
                            ctx.moveTo(pX, midY - 5);
                            ctx.lineTo(pX, midY + 5);
                            ctx.stroke();
                        }

                        if (pX < width) {
                            ctx.beginPath();
                            ctx.lineWidth = 2.0;
                            ctx.strokeStyle = trackColor;
                            ctx.moveTo(Math.max(pX + 3, 0), midY);
                            ctx.lineTo(width - 4, midY);
                            ctx.stroke();

                            ctx.beginPath();
                            ctx.fillStyle = trackColor;
                            ctx.arc(width - 2, midY, 2, 0, 2 * Math.PI);
                            ctx.fill();
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mediaRoot.mediaLength > 0 && mediaRoot.mediaService) {
                                var ratio = Math.max(0, Math.min(1, mouse.x / waveCanvas.width));
                                var seekSec = Math.round(ratio * mediaRoot.mediaLength);
                                mediaRoot.mediaService.seek(seekSec);
                            }
                        }
                    }
                }

                IconImage {
                    width: 16
                    height: 16
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("skip-forward.svg")
                    opacity: 0.85
                    Layout.alignment: Qt.AlignVCenter
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: mediaRoot.theme ? mediaRoot.theme.getColor("onSurface") : "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            parent.scale = 1.25;
                            parent.opacity = 1.0;
                        }
                        onExited: {
                            parent.scale = 1.0;
                            parent.opacity = 0.85;
                        }
                        onClicked: {
                            if (mediaRoot.mediaService) {
                                mediaRoot.mediaService.next();
                            }
                            mediaRoot.controlAction("next");
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 120 } }
                }
            }
        }
    }
}
