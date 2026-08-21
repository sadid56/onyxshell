import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

RowLayout {
    id: netRow
    spacing: 12
    Layout.alignment: Qt.AlignVCenter

    property var theme
    property var sysStats

    RowLayout {
        spacing: 4
        Layout.alignment: Qt.AlignVCenter

        IconImage {
            width: 10
            height: 10
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/arrow-down.svg")
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: netDownText.color
            }
        }

        Text {
            id: netDownText
            text: netRow.sysStats.networkDown
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
            color: {
                var s = netRow.sysStats.networkDown;
                if (s.indexOf("MB/s") !== -1) {
                    var valMb = parseFloat(s);
                    if (valMb >= 5.0) return netRow.theme.getColor("error");
                    return netRow.theme.getColor("secondary");
                }
                if (s.indexOf("KB/s") !== -1) {
                    var valKb = parseFloat(s);
                    if (valKb >= 500.0) return netRow.theme.getColor("secondary");
                    if (valKb >= 100.0) return netRow.theme.getColor("primary");
                }
                return netRow.theme.getColor("onSurface");
            }
        }
    }

    RowLayout {
        spacing: 4
        Layout.alignment: Qt.AlignVCenter

        IconImage {
            width: 10
            height: 10
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/arrow-up.svg")
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: netUpText.color
            }
        }

        Text {
            id: netUpText
            text: netRow.sysStats.networkUp
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
            color: {
                var s = netRow.sysStats.networkUp;
                if (s.indexOf("MB/s") !== -1) {
                    var valMb = parseFloat(s);
                    if (valMb >= 5.0) return netRow.theme.getColor("error");
                    return netRow.theme.getColor("secondary");
                }
                if (s.indexOf("KB/s") !== -1) {
                    var valKb = parseFloat(s);
                    if (valKb >= 500.0) return netRow.theme.getColor("secondary");
                    if (valKb >= 100.0) return netRow.theme.getColor("primary");
                }
                return netRow.theme.getColor("onSurface");
            }
        }
    }

    IconImage {
        id: wifiIcon
        width: 20
        height: 20
        Layout.alignment: Qt.AlignVCenter
        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getWifiIcon(
            netRow.sysStats.wifiSignal,
            netRow.sysStats.networkSsid !== "Disconnected" && netRow.sysStats.wifiSignal >= 0,
            true
        )
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: (netRow.sysStats.networkSsid === "Disconnected" || netRow.sysStats.wifiSignal < 0)
                ? (netRow.theme ? netRow.theme.getColor("error") : "#ff5555")
                : (netRow.theme ? netRow.theme.getColor("onSurface") : "#FFFFFF")
        }
    }
}
