import QtQuick

Canvas {
    width: 16
    height: 16
    antialiasing: true
    
    property bool alignRight: false
    property string color: "black"
    
    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = color;
        ctx.beginPath();
        if (alignRight) {
            ctx.moveTo(16, 0);
            ctx.lineTo(16, 16);
            ctx.arc(0, 16, 16, 0, Math.PI * 1.5, true);
            ctx.lineTo(0, 0);
        } else {
            ctx.moveTo(0, 0);
            ctx.lineTo(16, 0);
            ctx.arc(16, 16, 16, Math.PI * 1.5, Math.PI, true);
            ctx.lineTo(0, 16);
        }
        ctx.closePath();
        ctx.fill();
    }
}
