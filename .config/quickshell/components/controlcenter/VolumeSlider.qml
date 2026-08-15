import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: volumeRoot
    Layout.fillWidth: true
    spacing: 4

    property var theme
    property int volumeValue: 50
    signal volumeMoved(int value)

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: volumeRoot.volumeValue === 0 ? "󰝟" : (volumeRoot.volumeValue < 33 ? "󰕿" : (volumeRoot.volumeValue < 66 ? "󰖀" : "󰕾"))
            font.family: "Noto Sans"
            font.pixelSize: 16
            color: volumeRoot.theme.getColor("primary")
        }
        Text {
            text: "Volume"
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 12
            font.bold: true
            color: volumeRoot.theme.getColor("onSurface")
            Layout.fillWidth: true
        }
        Text {
            text: volumeRoot.volumeValue + "%"
            font.family: "Noto Sans"
            font.pixelSize: 12
            color: volumeRoot.theme.getColor("outline")
        }
    }

    Slider {
        id: volSlider
        Layout.fillWidth: true
        from: 0
        to: 100
        value: volumeRoot.volumeValue
        onMoved: {
            volumeRoot.volumeValue = Math.round(value);
            volumeRoot.volumeMoved(volumeRoot.volumeValue);
        }

        background: Rectangle {
            x: volSlider.leftPadding
            y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 8
            width: volSlider.availableWidth
            height: implicitHeight
            radius: 4
            color: volumeRoot.theme.getColor("surfaceVariant")

            Rectangle {
                width: volSlider.visualPosition * parent.width
                height: parent.height
                color: volumeRoot.theme.getColor("primary")
                radius: 4
            }
        }

        handle: Rectangle {
            x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
            y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
            implicitWidth: 16
            implicitHeight: 16
            radius: 8
            color: volSlider.pressed ? volumeRoot.theme.getColor("primary") : volumeRoot.theme.getColor("onPrimary")
            border.color: volumeRoot.theme.getColor("primary")
            border.width: 2
        }
    }
}
