import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

Item {
    id: distroRoot
    width: 22
    height: 22
    Layout.alignment: Qt.AlignVCenter

    property string distroId: (typeof shellConfig !== "undefined" ? shellConfig.currentDistro : "arch")

    IconImage {
        id: distroIconImage
        anchors.centerIn: parent
        width: 18
        height: 18
        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getDistroIcon(distroRoot.distroId)
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: (typeof barWindow !== "undefined" && barWindow.theme) ? barWindow.theme.getColor("primary") : "#ffb3b4"
        }
    }
}
