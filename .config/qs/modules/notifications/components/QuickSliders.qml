import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UISliders

ColumnLayout {
    id: quickSlidersRoot
    Layout.fillWidth: true
    spacing: 8

    property var theme
    property int volumeValue: 50
    property int brightnessValue: 50
    property var volumeSetter
    property var brightnessSetter

    signal volumeMoved(int val)
    signal brightnessMoved(int val)

    UISliders.Slider {
        theme: quickSlidersRoot.theme
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getSpeakerIcon(quickSlidersRoot.volumeValue === 0)
        value: quickSlidersRoot.volumeValue
        max: 150
        onMoved: val => {
            quickSlidersRoot.volumeMoved(val);
            if (quickSlidersRoot.volumeSetter) {
                quickSlidersRoot.volumeSetter.setVolume(val);
            }
        }
    }

    UISliders.Slider {
        theme: quickSlidersRoot.theme
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/brightness.svg")
        value: quickSlidersRoot.brightnessValue
        onMoved: val => {
            quickSlidersRoot.brightnessMoved(val);
            if (quickSlidersRoot.brightnessSetter) {
                quickSlidersRoot.brightnessSetter.setBrightness(val);
            }
        }
    }
}
