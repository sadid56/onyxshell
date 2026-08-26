import QtQuick

Canvas {
    id: progressBarCanvas
    anchors.fill: parent
    antialiasing: true
    renderTarget: Canvas.Image

    property var theme
    property real progress: 0.0
    property alias progressAnim: progressAnim

    onProgressChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.clearRect(0, 0, width, height);
        if (progress <= 0) return;

        var cx = width / 2;
        var cy = height / 2;
        var strokeW = 2.5;
        var radius = Math.min(cx, cy) - strokeW;
        if (radius <= 0) return;

        var primColor = progressBarCanvas.theme ? progressBarCanvas.theme.getColor("primary") : "#ffb3b4";

        ctx.strokeStyle = Qt.rgba(primColor.r, primColor.g, primColor.b, 0.18);
        ctx.lineWidth = strokeW;
        ctx.beginPath();
        ctx.arc(cx, cy, radius, 0, Math.PI * 2, false);
        ctx.stroke();

        var startAngle = -Math.PI / 2;
        var endAngle = startAngle + (progress * Math.PI * 2);

        ctx.strokeStyle = primColor;
        ctx.lineWidth = strokeW;
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.arc(cx, cy, radius, startAngle, endAngle, false);
        ctx.stroke();
    }

    NumberAnimation {
        id: progressAnim
        target: progressBarCanvas
        property: "progress"
        from: 1.0
        to: 0.0
        duration: 4000
        running: false
        easing.type: Easing.Linear
    }
}
