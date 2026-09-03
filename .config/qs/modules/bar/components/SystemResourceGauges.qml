import QtQuick
import QtQuick.Layouts
import "./"

ColumnLayout {
    id: gaugesRoot

    property var theme
    property var telemetryData: ({})

    spacing: 8
    Layout.fillWidth: true

    ResourceGaugeCard {
        theme: gaugesRoot.theme
        title: "CPU"
        iconSource: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/cpu.svg")
        progress: (gaugesRoot.telemetryData && gaugesRoot.telemetryData.cpu) ? gaugesRoot.telemetryData.cpu.usage : 0
        valueText: Math.round(progress) + "%"
        subText: (gaugesRoot.telemetryData && gaugesRoot.telemetryData.cpu) ? (gaugesRoot.telemetryData.cpu.freq + " GHz") : ""
        barColor: gaugesRoot.theme ? gaugesRoot.theme.getColor("primary") : "#adc6ff"
    }

    ResourceGaugeCard {
        theme: gaugesRoot.theme
        title: "RAM"
        iconSource: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/memory.svg")
        progress: (gaugesRoot.telemetryData && gaugesRoot.telemetryData.memory) ? gaugesRoot.telemetryData.memory.usage : 0
        valueText: Math.round(progress) + "%"
        subText: (gaugesRoot.telemetryData && gaugesRoot.telemetryData.memory) ? (gaugesRoot.telemetryData.memory.used_gb + " / " + gaugesRoot.telemetryData.memory.total_gb + " GB") : ""
        barColor: gaugesRoot.theme ? (gaugesRoot.theme.getColor("secondary") || "#b4befe") : "#b4befe"
    }

    ResourceGaugeCard {
        theme: gaugesRoot.theme
        title: "SWAP"
        iconSource: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/swap.svg")
        progress: (gaugesRoot.telemetryData && gaugesRoot.telemetryData.swap) ? gaugesRoot.telemetryData.swap.usage : 0
        valueText: Math.round(progress) + "%"
        subText: (gaugesRoot.telemetryData && gaugesRoot.telemetryData.swap) ? (gaugesRoot.telemetryData.swap.used_gb + " / " + gaugesRoot.telemetryData.swap.total_gb + " GB") : ""
        barColor: gaugesRoot.theme ? (gaugesRoot.theme.getColor("tertiary") || "#cba6f7") : "#cba6f7"
    }
}
