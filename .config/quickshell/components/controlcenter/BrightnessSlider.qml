import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: brightnessRoot
    Layout.fillWidth: true
    spacing: 4

    property var theme
    property int brightnessValue: 50
    signal brightnessMoved(int value)

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "󰖨"
            font.family: "Noto Sans"
            font.pixelSize: 16
            color: brightnessRoot.theme.getColor("primary")
        }
        Text {
            text: "Brightness"
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 12
            font.bold: true
            color: brightnessRoot.theme.getColor("onSurface")
            Layout.fillWidth: true
        }
        Text {
            text: brightnessRoot.brightnessValue + "%"
            font.family: "Noto Sans"
            font.pixelSize: 12
            color: brightnessRoot.theme.getColor("outline")
        }
    }

    Slider {
        id: briSlider
        Layout.fillWidth: true
        from: 5
        to: 100
        value: brightnessRoot.brightnessValue
        onMoved: {
            brightnessRoot.brightnessValue = Math.round(value);
            brightnessRoot.brightnessMoved(brightnessRoot.brightnessValue);
        }

        background: Rectangle {
            x: briSlider.leftPadding
            y: briSlider.topPadding + briSlider.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 8
            width: briSlider.availableWidth
            height: implicitHeight
            radius: 4
            color: brightnessRoot.theme.getColor("surfaceVariant")

            Rectangle {
                width: briSlider.visualPosition * parent.width
                height: parent.height
                color: brightnessRoot.theme.getColor("primary")
                radius: 4
            }
        }

        handle: Rectangle {
            x: briSlider.leftPadding + briSlider.visualPosition * (briSlider.availableWidth - width)
            y: briSlider.topPadding + briSlider.availableHeight / 2 - height / 2
            implicitWidth: 16
            implicitHeight: 16
            radius: 8
            color: briSlider.pressed ? brightnessRoot.theme.getColor("primary") : brightnessRoot.theme.getColor("onPrimary")
            border.color: brightnessRoot.theme.getColor("primary")
            border.width: 2
        }
    }
}
