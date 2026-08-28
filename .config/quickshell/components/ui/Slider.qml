import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Item {
    id: sliderRoot
    Layout.fillWidth: true
    implicitHeight: 32
    height: 32

    property var theme
    property string title: ""
    property string icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/brightness.svg")
    property int value: 50
    property int min: 0
    property int max: 100

    signal moved(int val)
    signal released(int val)

    Rectangle {
        id: track
        anchors.fill: parent
        radius: 14
        color: sliderRoot.theme.getColor("surfaceVariant")
        clip: true

        Rectangle {
            id: fillBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, Math.min(track.width, ((sliderRoot.value - sliderRoot.min) / (sliderRoot.max - sliderRoot.min)) * track.width))
            radius: 14
            opacity: sliderMouse.containsMouse ? 0.95 : 0.85

            gradient: sliderRoot.value > 100 ? alertGradient : null
            color: sliderRoot.value > 100 ? "transparent" : (sliderRoot.theme ? sliderRoot.theme.getColor("primary") : "#ffb3b4")

            Gradient {
                id: alertGradient
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: sliderRoot.theme ? sliderRoot.theme.getColor("primary") : "#ffb3b4"
                }
                GradientStop {
                    position: Math.max(0.2, Math.min(0.75, (100.0 - sliderRoot.min) / (sliderRoot.value - sliderRoot.min)))
                    color: sliderRoot.theme ? (sliderRoot.theme.getColor("tertiary") || "#ffb875") : "#ffb875"
                }
                GradientStop {
                    position: 1.0
                    color: "#ff5252"
                }
            }

            Behavior on width {
                enabled: !sliderMouse.pressed
                NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 10

            IconImage {
                width: 19
                height: 19
                source: sliderRoot.icon.length > 2 ? sliderRoot.icon : ""
                visible: sliderRoot.icon !== "" && sliderRoot.icon.length > 2
                Layout.alignment: Qt.AlignVCenter
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: fillBar.width > 36
                        ? (sliderRoot.theme ? sliderRoot.theme.getColor("onPrimary") : "#000000")
                        : (sliderRoot.theme ? sliderRoot.theme.getColor("primary") : "#FFFFFF")
                }
            }

            Typography {
                theme: sliderRoot.theme
                text: sliderRoot.icon
                mono: true
                font.pixelSize: 19
                color: fillBar.width > 36 ? sliderRoot.theme.getColor("onPrimary") : sliderRoot.theme.getColor("primary")
                visible: sliderRoot.icon !== "" && sliderRoot.icon.length <= 2
                Layout.alignment: Qt.AlignVCenter
            }

            Typography {
                theme: sliderRoot.theme
                text: sliderRoot.title
                variant: "bodyMedium"
                font.bold: true
                color: fillBar.width > 120 ? sliderRoot.theme.getColor("onPrimary") : sliderRoot.theme.getColor("onSurface")
                visible: sliderRoot.title !== ""
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }

            Typography {
                theme: sliderRoot.theme
                text: sliderRoot.value + "%"
                variant: "labelMedium"
                font.bold: true
                color: fillBar.width > (track.width - 45)
                    ? (sliderRoot.theme ? sliderRoot.theme.getColor("onPrimary") : "#FFFFFF")
                    : (sliderRoot.value > 100 ? "#ff5252" : (sliderRoot.theme ? sliderRoot.theme.getColor("outline") : "#a58a8a"))
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function updateValue(mouseX) {
                var ratio = Math.max(0.0, Math.min(1.0, mouseX / track.width));
                var newVal = Math.round(sliderRoot.min + ratio * (sliderRoot.max - sliderRoot.min));
                if (newVal !== sliderRoot.value) {
                    sliderRoot.value = newVal;
                    sliderRoot.moved(newVal);
                }
            }

            onPressed: mouse => {
                updateValue(mouse.x);
            }

            onPositionChanged: mouse => {
                if (pressed) {
                    updateValue(mouse.x);
                }
            }

            onReleased: mouse => {
                var ratio = Math.max(0.0, Math.min(1.0, mouse.x / track.width));
                var newVal = Math.round(sliderRoot.min + ratio * (sliderRoot.max - sliderRoot.min));
                sliderRoot.value = newVal;
                sliderRoot.released(newVal);
            }

        }
    }
}
