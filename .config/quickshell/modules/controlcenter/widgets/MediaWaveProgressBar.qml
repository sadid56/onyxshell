import QtQuick

Canvas {
    id: waveCanvas
    property var theme
    property var mediaService
    property bool isPlaying: false
    property int mediaLength: 0
    property int mediaPosition: 0

    property real phase: 0
    property real progressRatio: mediaLength > 0 ? Math.min(1.0, Math.max(0.0, mediaPosition / mediaLength)) : 0
    property real progressX: width * progressRatio

    onProgressXChanged: requestPaint()

    Behavior on progressRatio {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    Timer {
        id: waveAnimTimer
        interval: 33
        running: waveCanvas.isPlaying
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
        var waveColor = waveCanvas.theme ? waveCanvas.theme.getColor("primary") : "#a8c88e";
        var trackColor = waveCanvas.theme ? waveCanvas.theme.getColor("outline") : "#555555";

        if (pX > 2) {
            ctx.beginPath();
            ctx.lineWidth = 2.5;
            ctx.lineCap = "round";
            ctx.strokeStyle = waveColor;
            ctx.moveTo(0, midY);
            for (var x = 0; x <= pX; x += 2) {
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
            if (waveCanvas.mediaLength > 0 && waveCanvas.mediaService) {
                var ratio = Math.max(0, Math.min(1, mouse.x / waveCanvas.width));
                waveCanvas.mediaService.seek(Math.round(ratio * waveCanvas.mediaLength));
            }
        }
    }
}
