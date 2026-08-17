import QtQuick

Canvas {
    id: cornerCanvas
    property int cornerRadius: (typeof root !== "undefined" && root && root.shellConfig) ? root.shellConfig.cornerRadius : 16
    width: cornerRadius
    height: cornerRadius
    antialiasing: true
    renderTarget: Canvas.FramebufferObject

    property bool alignRight: false
    property bool alignBottom: false
    property string color: "black"

    onColorChanged: requestPaint()
    onAlignRightChanged: requestPaint()
    onAlignBottomChanged: requestPaint()
    onCornerRadiusChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.clearRect(0, 0, width, height);
        ctx.fillStyle = color;
        ctx.beginPath();
        if (alignBottom) {
            if (alignRight) {
                // Bottom-left inverted corner (outside left edge of bottom-pinned panel)
                ctx.moveTo(width, 0);
                ctx.lineTo(width, height);
                ctx.lineTo(0, height);
                ctx.arc(0, 0, width, Math.PI * 0.5, 0, true);
            } else {
                // Bottom-right inverted corner (outside right edge of bottom-pinned panel)
                ctx.moveTo(0, 0);
                ctx.lineTo(0, height);
                ctx.lineTo(width, height);
                ctx.arc(width, 0, width, Math.PI * 0.5, Math.PI, false);
            }
        } else {
            if (alignRight) {
                // Top-left inverted corner (outside left edge of top-pinned panel)
                ctx.moveTo(width, 0);
                ctx.lineTo(width, height);
                ctx.arc(0, height, height, 0, Math.PI * 1.5, true);
                ctx.lineTo(0, 0);
            } else {
                // Top-right inverted corner (outside right edge of top-pinned panel)
                ctx.moveTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.arc(width, height, width, Math.PI * 1.5, Math.PI, true);
                ctx.lineTo(0, height);
            }
        }
        ctx.closePath();
        ctx.fill();
    }
}
