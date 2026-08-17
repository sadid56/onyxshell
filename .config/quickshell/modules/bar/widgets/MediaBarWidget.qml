import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: mediaBarRoot

    property var theme
    property var mediaService
    property var toggleMedia

    property var targetBars: []
    property var smoothBars: []

    readonly property bool isPlaying: mediaBarRoot.mediaService ? Boolean(mediaBarRoot.mediaService.isPlaying) : false
    readonly property bool hasMedia: mediaBarRoot.mediaService ? Boolean(mediaBarRoot.mediaService.hasMedia) : false

    implicitHeight: 24
    implicitWidth: 215
    Layout.maximumWidth: 230
    Layout.alignment: Qt.AlignVCenter

    Process {
        id: cavaProcess
        command: ["cava", "-p", shellConfig.quickshellDir + "/scripts/cava_bar.conf"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var clean = data.trim();
                if (!clean) return;
                var parts = clean.split(';');
                var vals = [];
                for (var i = 0; i < parts.length; i++) {
                    if (parts[i] !== "") {
                        vals.push(parseInt(parts[i]) || 0);
                    }
                }
                if (vals.length > 0) {
                    mediaBarRoot.targetBars = vals;
                }
            }
        }
    }

    Timer {
        id: smoothTimer
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            var targets = mediaBarRoot.targetBars;
            if (!targets || targets.length === 0) return;

            if (!mediaBarRoot.smoothBars || mediaBarRoot.smoothBars.length !== targets.length) {
                var initArr = [];
                for (var k = 0; k < targets.length; k++) initArr.push(0);
                mediaBarRoot.smoothBars = initArr;
            }

            var current = mediaBarRoot.smoothBars.slice();
            var changed = false;

            for (var i = 0; i < targets.length; i++) {
                var targetVal = (mediaBarRoot.isPlaying && mediaBarRoot.hasMedia) ? (targets[i] || 0) : 0;
                var diff = targetVal - (current[i] || 0);
                if (Math.abs(diff) > 0.1) {
                    current[i] += diff * 0.42;
                    changed = true;
                } else {
                    current[i] = targetVal;
                }
            }

            if (changed) {
                mediaBarRoot.smoothBars = current;
                barVisualizerCanvas.requestPaint();
            }
        }
    }

    MouseArea {
        id: pillMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            if (typeof root !== "undefined" && root.stopLoaderTimerAndActivate && typeof mediaLoader !== "undefined" && typeof statusBar !== "undefined") {
                root.stopLoaderTimerAndActivate(mediaLoader, statusBar.getMediaX());
                root.setLoaderInactive(calendarLoader);
                root.setLoaderInactive(wifiLoader);
                root.setLoaderInactive(notifsLoader);
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

    Canvas {
        id: barVisualizerCanvas
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 22

        onVisibleChanged: requestPaint()
        onWidthChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            var baselineY = height - 2;
            var primaryColor = mediaBarRoot.theme ? mediaBarRoot.theme.getColor("primary") : "#3574d4";
            var outlineColor = mediaBarRoot.theme ? mediaBarRoot.theme.getColor("outline") : "#757680";

            var bars = mediaBarRoot.smoothBars || [];
            var maxAmplitude = height - 4;

            var hasSignal = false;
            for (var b = 0; b < bars.length; b++) {
                if (bars[b] > 1.0) {
                    hasSignal = true;
                    break;
                }
            }

            if (hasSignal && mediaBarRoot.isPlaying && bars.length > 1) {
                var points = [];
                var step = (width - 4) / (bars.length - 1);

                for (var i = 0; i < bars.length; i++) {
                    var normalized = Math.min(1.0, Math.max(0.0, (bars[i] || 0) / 100.0));
                    var yVal = baselineY - (normalized * maxAmplitude);
                    points.push({ x: 2 + i * step, y: yVal });
                }

                ctx.beginPath();
                ctx.moveTo(points[0].x, baselineY);
                ctx.lineTo(points[0].x, points[0].y);

                for (var j = 0; j < points.length - 1; j++) {
                    var xc = (points[j].x + points[j + 1].x) / 2;
                    var yc = (points[j].y + points[j + 1].y) / 2;
                    ctx.quadraticCurveTo(points[j].x, points[j].y, xc, yc);
                }
                ctx.lineTo(points[points.length - 1].x, points[points.length - 1].y);
                ctx.lineTo(points[points.length - 1].x, baselineY);
                ctx.closePath();

                var grad = ctx.createLinearGradient(0, 0, 0, baselineY);
                grad.addColorStop(0.0, primaryColor);
                grad.addColorStop(1.0, primaryColor);
                ctx.fillStyle = grad;
                ctx.globalAlpha = 0.35;
                ctx.fill();

                ctx.beginPath();
                ctx.lineWidth = 2.2;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.strokeStyle = primaryColor;
                ctx.globalAlpha = 1.0;

                ctx.moveTo(points[0].x, points[0].y);
                for (var k = 0; k < points.length - 1; k++) {
                    var xck = (points[k].x + points[k + 1].x) / 2;
                    var yck = (points[k].y + points[k + 1].y) / 2;
                    ctx.quadraticCurveTo(points[k].x, points[k].y, xck, yck);
                }
                ctx.lineTo(points[points.length - 1].x, points[points.length - 1].y);
                ctx.stroke();

            } else {

                ctx.beginPath();
                ctx.lineWidth = 2.0;
                ctx.lineCap = "round";
                ctx.strokeStyle = mediaBarRoot.isPlaying ? primaryColor : outlineColor;
                ctx.globalAlpha = 0.6;
                ctx.moveTo(2, baselineY);
                ctx.lineTo(width - 2, baselineY);
                ctx.stroke();
            }

            ctx.globalAlpha = 1.0;
        }
    }
}
