import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root

    property int radius: (typeof shellConfig !== "undefined" && shellConfig) ? shellConfig.cornerRadius : 16
    property color color: "black"
    property bool showTop: true
    property bool showBottom: true
    readonly property bool isFullscreen: (Hyprland.focusedWorkspace && Boolean(Hyprland.focusedWorkspace.hasfullscreen || Hyprland.focusedWorkspace.hasFullscreen))

    visible: !isFullscreen

    PanelWindow {
        implicitWidth: root.radius
        implicitHeight: root.radius
        anchors { top: true; left: true }
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        visible: root.visible && root.showTop && !root.isFullscreen

        Canvas {
            id: topLeftCanvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            Connections {
                target: root
                function onRadiusChanged() { topLeftCanvas.requestPaint() }
                function onColorChanged() { topLeftCanvas.requestPaint() }
            }
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);
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
        visible: root.visible && root.showTop && !root.isFullscreen

        Canvas {
            id: topRightCanvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            Connections {
                target: root
                function onRadiusChanged() { topRightCanvas.requestPaint() }
                function onColorChanged() { topRightCanvas.requestPaint() }
            }
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);
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

    PanelWindow {
        implicitWidth: root.radius
        implicitHeight: root.radius
        anchors { bottom: true; left: true }
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        visible: root.visible && root.showBottom && !root.isFullscreen

        Canvas {
            id: bottomLeftCanvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            Connections {
                target: root
                function onRadiusChanged() { bottomLeftCanvas.requestPaint() }
                function onColorChanged() { bottomLeftCanvas.requestPaint() }
            }
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = root.color;
                ctx.beginPath();
                ctx.moveTo(0, root.radius);
                ctx.lineTo(root.radius, root.radius);
                ctx.arc(root.radius, 0, root.radius, Math.PI * 0.5, Math.PI, false);
                ctx.closePath();
                ctx.fill();
            }
        }
    }

    PanelWindow {
        implicitWidth: root.radius
        implicitHeight: root.radius
        anchors { bottom: true; right: true }
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        visible: root.visible && root.showBottom && !root.isFullscreen

        Canvas {
            id: bottomRightCanvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            Connections {
                target: root
                function onRadiusChanged() { bottomRightCanvas.requestPaint() }
                function onColorChanged() { bottomRightCanvas.requestPaint() }
            }
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = root.color;
                ctx.beginPath();
                ctx.moveTo(root.radius, root.radius);
                ctx.lineTo(0, root.radius);
                ctx.arc(0, 0, root.radius, Math.PI * 0.5, 0, true);
                ctx.closePath();
                ctx.fill();
            }
        }
    }
}
