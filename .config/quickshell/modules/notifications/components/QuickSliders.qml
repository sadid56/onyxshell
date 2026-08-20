import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UISliders

ColumnLayout {
    id: quickSlidersRoot
    Layout.fillWidth: true
    spacing: 10

    property var theme
    property int volumeValue: 50
    property int micValue: 50
    property int brightnessValue: 50
    property int nightLightValue: 0
    property var volumeSetter
    property var brightnessSetter
    property var nightLightSetter

    signal volumeMoved(int val)
    signal brightnessMoved(int val)
    signal nightLightMoved(int val)

    UISliders.Slider {
        theme: quickSlidersRoot.theme
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getSpeakerIcon(quickSlidersRoot.volumeValue === 0)
        value: quickSlidersRoot.volumeValue
        onMoved: val => {
            quickSlidersRoot.volumeMoved(val);
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
            quickSlidersRoot.brightnessMoved(val);
            if (quickSlidersRoot.brightnessSetter) {
                quickSlidersRoot.brightnessSetter.setBrightness(val);
            }
        }
    }

    UISliders.Slider {
        theme: quickSlidersRoot.theme
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("moon.svg")
        value: quickSlidersRoot.nightLightValue
        onMoved: val => {
            quickSlidersRoot.nightLightMoved(val);
            if (quickSlidersRoot.nightLightSetter) {
                quickSlidersRoot.nightLightSetter.setNightLight(val);
            }
        }
    }
}
