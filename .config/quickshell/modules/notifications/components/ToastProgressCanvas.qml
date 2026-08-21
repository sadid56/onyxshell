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
        if (progress <= 0) return;

        var arcLength = Math.PI * 14.5 / 2;
        var totalLength = arcLength + (parent.width - 16);
        var L = progress * totalLength;

        ctx.strokeStyle = progressBarCanvas.theme ? progressBarCanvas.theme.getColor("primary") : "#ffb3b4";
        ctx.lineCap = "round";

        var activeAngle = L / 14.5;
        var taperLimit = Math.min(Math.PI / 2, activeAngle);
        var steps = 15;
        var stepSize = taperLimit / steps;

        for (var i = 0; i < steps; i++) {
            var a1 = Math.PI - (i * stepSize);
            var a2 = Math.PI - ((i + 1) * stepSize);

            ctx.lineWidth = 3.0 * ((i + 0.5) / steps);
            ctx.beginPath();
            ctx.arc(16, parent.height - 16, 14.5, a1, a2, true);
            ctx.stroke();
        }

        if (activeAngle > Math.PI / 2) {
            ctx.lineWidth = 3.0;
            ctx.beginPath();
            ctx.moveTo(16, parent.height - 1.5);
            ctx.lineTo(16 + (L - arcLength), parent.height - 1.5);
            ctx.stroke();
        }
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
