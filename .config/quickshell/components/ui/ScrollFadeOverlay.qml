import QtQuick
import QtQuick.Layouts

Item {
    id: fadeOverlayRoot
    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    height: fadeHeight
    z: 99
    enabled: false // Transparent to mouse events so user can click through

    property var targetView: parent
    property var theme: null
    property color fadeColor: theme ? theme.getColor("surface") : "#1b1b1b"
    property real fadeHeight: 38
    property real cornerRadius: 20
    property bool autoHide: true
    property bool topFade: false

    readonly property bool isVisible: {
        if (!autoHide) return true;
        if (!targetView) return false;
        if (topFade) {
            var cY = targetView.contentY || 0;
            return cY > 6;
        } else {
            var cHeight = targetView.contentHeight || targetView.height;
            var vHeight = targetView.height;
            var cY = targetView.contentY || 0;
            return (cHeight - vHeight - cY) > 6;
        }
    }

    opacity: isVisible ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        bottomLeftRadius: fadeOverlayRoot.topFade ? 0 : fadeOverlayRoot.cornerRadius
        bottomRightRadius: fadeOverlayRoot.topFade ? 0 : fadeOverlayRoot.cornerRadius
        topLeftRadius: fadeOverlayRoot.topFade ? fadeOverlayRoot.cornerRadius : 0
        topRightRadius: fadeOverlayRoot.topFade ? fadeOverlayRoot.cornerRadius : 0

        gradient: Gradient {
            GradientStop {
                position: fadeOverlayRoot.topFade ? 0.0 : 1.0
                color: fadeOverlayRoot.fadeColor
            }
            GradientStop {
                position: fadeOverlayRoot.topFade ? 0.5 : 0.5
                color: Qt.rgba(fadeOverlayRoot.fadeColor.r, fadeOverlayRoot.fadeColor.g, fadeOverlayRoot.fadeColor.b, 0.75)
            }
            GradientStop {
                position: fadeOverlayRoot.topFade ? 1.0 : 0.0
                color: "transparent"
            }
        }
    }
}
