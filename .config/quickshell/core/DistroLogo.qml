import QtQuick
import QtQuick.Layouts
import "../components/ui" as UI

Item {
    id: distroRoot
    width: 22
    height: 22
    Layout.alignment: Qt.AlignVCenter

    property string distroId: (typeof shellConfig !== "undefined" ? shellConfig.currentDistro : "arch")

    UI.Icon {
        anchors.centerIn: parent
        size: 18
        source: ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getDistroIcon(distroRoot.distroId)
        color: (typeof barWindow !== "undefined" && barWindow.theme) ? barWindow.theme.getColor("primary") : "#ffb3b4"
    }
}
