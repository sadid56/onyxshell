import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UISliders

ColumnLayout {
    id: quickSlidersRoot
    Layout.fillWidth: true
    spacing: 10

    property var theme
    property int volumeValue: 50
    property int brightnessValue: 50
    property var volumeSetter
    property var brightnessSetter

    UISliders.Slider {
        theme: quickSlidersRoot.theme
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getSpeakerIcon(quickSlidersRoot.volumeValue === 0)
        value: quickSlidersRoot.volumeValue
        onMoved: val => {
            quickSlidersRoot.volumeValue = val;
            if (quickSlidersRoot.volumeSetter) {
                quickSlidersRoot.volumeSetter.setVolume(val);
            }
        }
    }

    UISliders.Slider {
        theme: quickSlidersRoot.theme
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("brightness.svg")
        value: quickSlidersRoot.brightnessValue
        onMoved: val => {
            quickSlidersRoot.brightnessValue = val;
            if (quickSlidersRoot.brightnessSetter) {
                quickSlidersRoot.brightnessSetter.setBrightness(val);
            }
        }
    }
}
