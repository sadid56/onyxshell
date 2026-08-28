import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../modules/bar/widgets"

PanelWindow {
    id: popupWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    visible: active || contentRect.opacity > 0.0 || (slideFromRight && slideTranslate.x < (popupWidth + 30))

    property var theme
    property real targetX: -1
    property alias closeTimer: closeTimer
    property alias contentRect: contentRect
    property alias contentX: contentRect.x

    property int popupWidth: 380
    property int popupHeight: 420
    property int topOverlap: 40
    property bool flatBottom: false
    property bool slideFromRight: false
    property bool showCorners: true
    property bool showTopCorners: showCorners
    property bool closeOnHoverOutside: true
    property int contentMargin: 16

    readonly property int safeWidth: popupWindow.width > 0 ? popupWindow.width : 1920

    property real contentRectX: targetX > 0 ? Math.max(10, Math.min(targetX - popupWidth / 2, safeWidth - popupWidth - 10)) : ((safeWidth - popupWidth) / 2)
    property real contentRectY: popupWindow.showCorners ? (popupWindow.active ? -popupWindow.topOverlap : -(popupWindow.topOverlap + 80)) : (popupWindow.active ? 46 : 20)

    default property alias contentData: columnLayout.data

    Timer {
        id: closeTimer
        interval: 80
        running: false
        repeat: false
        onTriggered: {
            popupWindow.active = false;
        }
    }

    Timer {
        id: openGuard
        interval: 100
        running: false
        repeat: false
    }

    onActiveChanged: {
        if (active) {
            openGuard.running = true;
            popupWindow.closeTimer.stop();
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            if (popupWindow.closeOnHoverOutside && !openGuard.running) {
                popupWindow.closeTimer.restart();
            }
        }
        onClicked: popupWindow.active = false
    }

    Rectangle {
        id: contentRect
        anchors.right: popupWindow.slideFromRight ? parent.right : undefined
        anchors.rightMargin: popupWindow.slideFromRight ? (popupWindow.showCorners ? 0 : 10) : 0
        x: popupWindow.slideFromRight ? 0 : (popupWindow.contentRectX !== undefined ? popupWindow.contentRectX : 0)
        y: popupWindow.slideFromRight ? (popupWindow.showCorners ? -popupWindow.topOverlap : 10) : popupWindow.contentRectY

        width: popupWindow.popupWidth
        height: popupWindow.popupHeight

        Behavior on height { enabled: !popupWindow.flatBottom; NumberAnimation { duration: 340; easing.type: Easing.OutQuint } }
        radius: (root && root.settingsService && root.settingsService.cornerRadius !== undefined) ? root.settingsService.cornerRadius : ((root && root.shellConfig) ? root.shellConfig.cornerRadius : 16)

        color: popupWindow.theme.getColor("surface")
        border.width: 0

        MouseArea {
            id: contentMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                popupWindow.closeTimer.stop();
            }
            onClicked: {}
        }

        opacity: popupWindow.active ? 1.0 : 0.0
        scale: popupWindow.slideFromRight ? 1.0 : (popupWindow.active ? 1.0 : 0.88)
        transformOrigin: Item.Top

        transform: Translate {
            id: slideTranslate
            x: popupWindow.slideFromRight ? (popupWindow.active ? 0 : (popupWindow.popupWidth + 40)) : 0
            Behavior on x {
                NumberAnimation { duration: 340; easing.type: Easing.OutQuint }
            }
        }

        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
        Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }

        Corner {
            anchors.top: parent.top
            anchors.topMargin: popupWindow.topOverlap
            anchors.right: parent.left
            anchors.rightMargin: -0.5
            alignRight: true
            cornerRadius: contentRect.radius
            color: popupWindow.theme.getColor("surface")
            visible: popupWindow.showTopCorners && (contentRect.x > 0)
        }

        Corner {
            anchors.top: parent.top
            anchors.topMargin: popupWindow.topOverlap
            anchors.left: parent.right
            anchors.leftMargin: -0.5
            alignRight: false
            cornerRadius: contentRect.radius
            color: popupWindow.theme.getColor("surface")
            visible: popupWindow.showTopCorners && !popupWindow.slideFromRight
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.radius
            height: parent.radius
            color: parent.color
            visible: popupWindow.showCorners && !popupWindow.flatBottom && (contentRect.x <= 0)
        }

        Canvas {
            id: bottomLeftCornerCanvas
            width: contentRect.radius
            height: contentRect.radius
            anchors.top: parent.bottom
            anchors.left: parent.left
            antialiasing: true
            renderTarget: Canvas.FramebufferObject
            visible: popupWindow.showCorners && !popupWindow.flatBottom && (contentRect.x <= 0)

            Connections {
                target: popupWindow.theme
                function onColorsChanged() { bottomLeftCornerCanvas.requestPaint(); }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = popupWindow.theme ? popupWindow.theme.getColor("surface") : "#1b1111";
                ctx.beginPath();
                ctx.moveTo(0, height);
                ctx.lineTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.arc(width, height, width, Math.PI * 1.5, Math.PI, true);
                ctx.closePath();
                ctx.fill();
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.radius
            height: parent.radius
            color: parent.color
            visible: popupWindow.showCorners && !popupWindow.flatBottom && popupWindow.slideFromRight
        }

        Canvas {
            id: bottomRightCornerCanvas
            width: contentRect.radius
            height: contentRect.radius
            anchors.top: parent.bottom
            anchors.right: parent.right
            antialiasing: true
            renderTarget: Canvas.FramebufferObject
            visible: popupWindow.showCorners && !popupWindow.flatBottom && popupWindow.slideFromRight

            Connections {
                target: popupWindow.theme
                function onColorsChanged() { bottomRightCornerCanvas.requestPaint(); }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = popupWindow.theme ? popupWindow.theme.getColor("surface") : "#1b1111";
                ctx.beginPath();
                ctx.moveTo(width, height);
                ctx.lineTo(width, 0);
                ctx.lineTo(0, 0);
                ctx.arc(0, height, width, Math.PI * 1.5, Math.PI * 2, false);
                ctx.closePath();
                ctx.fill();
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.radius
            color: parent.color
            visible: popupWindow.flatBottom
        }

        Corner {
            anchors.bottom: parent.bottom
            anchors.right: parent.left
            anchors.rightMargin: -0.5
            alignRight: true
            alignBottom: true
            cornerRadius: contentRect.radius
            color: popupWindow.theme.getColor("surface")
            visible: popupWindow.flatBottom && popupWindow.showCorners
        }

        ColumnLayout {
            id: columnLayout
            anchors.fill: parent
            anchors.leftMargin: popupWindow.contentMargin
            anchors.rightMargin: popupWindow.contentMargin
            anchors.bottomMargin: popupWindow.contentMargin
            anchors.topMargin: popupWindow.showCorners ? (popupWindow.topOverlap + 12) : popupWindow.contentMargin
            spacing: 12
        }

    }
}
