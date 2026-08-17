import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    property int radius: 16
    property color color: "black"

    PanelWindow {
        implicitWidth: root.radius
        implicitHeight: root.radius
        anchors { top: true; left: true }
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = root.color;
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(root.radius, 0);
                ctx.arc(root.radius, root.radius, root.radius, Math.PI * 1.5, Math.PI, true);
                ctx.lineTo(0, root.radius);
                ctx.closePath();
                ctx.fill();
            }
        }
    }

    PanelWindow {
        implicitWidth: root.radius
        implicitHeight: root.radius
        anchors { top: true; right: true }
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = root.color;
                ctx.beginPath();
                ctx.moveTo(root.radius, 0);
                ctx.lineTo(root.radius, root.radius);
                ctx.arc(0, root.radius, root.radius, 0, Math.PI * 1.5, true);
                ctx.lineTo(0, 0);
                ctx.closePath();
                ctx.fill();
            }
        }
    }
}
