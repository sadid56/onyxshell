import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

RowLayout {
    id: netRow
    spacing: 8
    Layout.alignment: Qt.AlignVCenter

    property var theme
    property var sysStats

    function formatSpeed(raw) {
        if (!raw) return "0.0K";
        var s = raw.toString().trim();
        s = s.replace(/\/s/i, "").trim();
        var match = s.match(/^([\d.]+)\s*([a-zA-Z]+)?$/);
        if (!match) return "0.0K";
        var num = parseFloat(match[1]);
        var unit = (match[2] || "B").toUpperCase();
        if (isNaN(num) || num <= 0) return "0.0K";

        if (unit === "B") {
            num = num / 1024.0;
            unit = "K";
        } else if (unit.startsWith("K")) {
            unit = "K";
        } else if (unit.startsWith("M")) {
            unit = "M";
        } else if (unit.startsWith("G")) {
            unit = "G";
        }

        if (num < 10) {
            return num.toFixed(1) + unit;
        } else if (num < 1000) {
            return Math.round(num).toString() + unit;
        } else {
            return (num / 1024.0).toFixed(1) + (unit === "K" ? "M" : "G");
        }
    }

    RowLayout {
        spacing: 3
        Layout.alignment: Qt.AlignVCenter

        IconImage {
            width: 11
            height: 11
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/arrow-down.svg")
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: netDownText.color
            }
        }

        UI.Typography {
            id: netDownText
            theme: netRow.theme
            text: netRow.formatSpeed(netRow.sysStats.networkDown)
            variant: "labelMedium"
            font.weight: Font.Bold
            Layout.alignment: Qt.AlignVCenter
            color: {
                var s = netRow.sysStats.networkDown;
                if (s.indexOf("MB") !== -1) {
                    var valMb = parseFloat(s);
                    if (valMb >= 5.0) return netRow.theme.getColor("error");
                    return netRow.theme.getColor("secondary");
                }
                if (s.indexOf("KB") !== -1) {
                    var valKb = parseFloat(s);
                    if (valKb >= 500.0) return netRow.theme.getColor("secondary");
                    if (valKb >= 100.0) return netRow.theme.getColor("primary");
                }
                return netRow.theme.getColor("onSurface");
            }
        }
    }

    RowLayout {
        spacing: 3
        Layout.alignment: Qt.AlignVCenter

        IconImage {
            width: 11
            height: 11
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("actions/arrow-up.svg")
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: netUpText.color
            }
        }

        UI.Typography {
            id: netUpText
            theme: netRow.theme
            text: netRow.formatSpeed(netRow.sysStats.networkUp)
            variant: "labelMedium"
            font.weight: Font.Bold
            Layout.alignment: Qt.AlignVCenter
            color: {
                var s = netRow.sysStats.networkUp;
                if (s.indexOf("MB") !== -1) {
                    var valMb = parseFloat(s);
                    if (valMb >= 5.0) return netRow.theme.getColor("error");
                    return netRow.theme.getColor("secondary");
                }
                if (s.indexOf("KB") !== -1) {
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
        width: 16
        height: 16
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
