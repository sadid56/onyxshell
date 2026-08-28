import QtQuick
import QtQuick.Layouts
import "../components" as SettingsUI
import "../../../components/ui" as UI

ColumnLayout {
    id: specsRoot

    property var theme
    property var sysInfo: ({})

    readonly property bool isLoaded: Boolean(specsRoot.sysInfo && specsRoot.sysInfo.host && specsRoot.sysInfo.host.indexOf("Loading") === -1 && specsRoot.sysInfo.cpu && specsRoot.sysInfo.cpu.indexOf("Loading") === -1)

    spacing: 10
    Layout.fillWidth: true

    SettingsUI.SettingsCard {
        theme: specsRoot.theme

        UI.SkeletonLoader {
            width: parent.width
            theme: specsRoot.theme
            count: 5
            itemHeight: 38
            iconSize: 22
            visible: !specsRoot.isLoaded
        }

        Column {
            width: parent.width
            visible: specsRoot.isLoaded

            SettingsUI.SettingsRow {
                theme: specsRoot.theme
                title: "Device"
                subtitle: (specsRoot.sysInfo && specsRoot.sysInfo.host) ? specsRoot.sysInfo.host : "Linux System"
                icon: "system/monitor.svg"
            }

            Rectangle { width: parent.width; height: 1; color: specsRoot.theme.getColor("outlineVariant") + "15" }

            SettingsUI.SettingsRow {
                theme: specsRoot.theme
                title: "Processor"
                subtitle: (specsRoot.sysInfo && specsRoot.sysInfo.cpu) ? specsRoot.sysInfo.cpu : "Detecting CPU..."
                icon: "system/cpu.svg"
            }

            Rectangle { width: parent.width; height: 1; color: specsRoot.theme.getColor("outlineVariant") + "15" }

            SettingsUI.SettingsRow {
                theme: specsRoot.theme
                title: "Graphics"
                subtitle: (specsRoot.sysInfo && specsRoot.sysInfo.gpus && specsRoot.sysInfo.gpus.length > 0) ? specsRoot.sysInfo.gpus.join(" / ") : "Detecting GPU..."
                icon: "system/gpu.svg"
            }

            Rectangle { width: parent.width; height: 1; color: specsRoot.theme.getColor("outlineVariant") + "15" }

            SettingsUI.SettingsRow {
                theme: specsRoot.theme
                title: "Memory (RAM)"
                subtitle: (specsRoot.sysInfo && specsRoot.sysInfo.ram) ? (specsRoot.sysInfo.ramUsed ? (specsRoot.sysInfo.ramUsed + " / " + specsRoot.sysInfo.ram) : specsRoot.sysInfo.ram) : "Loading..."
                icon: "system/memory.svg"
            }

            Rectangle { width: parent.width; height: 1; color: specsRoot.theme.getColor("outlineVariant") + "15" }

            SettingsUI.SettingsRow {
                theme: specsRoot.theme
                title: "Storage (Root)"
                subtitle: (specsRoot.sysInfo && specsRoot.sysInfo.disk) ? specsRoot.sysInfo.disk : "Loading..."
                icon: "system/swap.svg"
            }
        }
    }

    SettingsUI.SettingsCard {
        theme: specsRoot.theme

        UI.SkeletonLoader {
            width: parent.width
            theme: specsRoot.theme
            count: 4
            itemHeight: 38
            iconSize: 22
            visible: !specsRoot.isLoaded
        }

        Column {
            width: parent.width
            visible: specsRoot.isLoaded

            SettingsUI.SettingsRow {
                theme: specsRoot.theme
                title: "Operating System"
                subtitle: (specsRoot.sysInfo && specsRoot.sysInfo.osName) ? (specsRoot.sysInfo.osName + " (" + (specsRoot.sysInfo.arch || "x86_64") + ")") : "Linux"
                icon: "system/globe.svg"
            }

            Rectangle { width: parent.width; height: 1; color: specsRoot.theme.getColor("outlineVariant") + "15" }

            SettingsUI.SettingsRow {
                theme: specsRoot.theme
                title: "Linux Kernel"
                subtitle: (specsRoot.sysInfo && specsRoot.sysInfo.kernel) ? specsRoot.sysInfo.kernel : "Linux"
                icon: "system/leaf-two.svg"
            }

            Rectangle { width: parent.width; height: 1; color: specsRoot.theme.getColor("outlineVariant") + "15" }

            SettingsUI.SettingsRow {
                theme: specsRoot.theme
                title: "Compositor & Shell"
                subtitle: ((specsRoot.sysInfo && specsRoot.sysInfo.hyprlandVersion) ? specsRoot.sysInfo.hyprlandVersion : "Hyprland") + " • " + ((specsRoot.sysInfo && specsRoot.sysInfo.quickshellVersion) ? specsRoot.sysInfo.quickshellVersion : "Quickshell")
                icon: "system/app-window.svg"
            }

            Rectangle { width: parent.width; height: 1; color: specsRoot.theme.getColor("outlineVariant") + "15" }

            SettingsUI.SettingsRow {
                theme: specsRoot.theme
                title: "System Uptime"
                subtitle: (specsRoot.sysInfo && specsRoot.sysInfo.uptime) ? specsRoot.sysInfo.uptime : "Active"
                icon: "system/clock.svg"
            }
        }
    }
}
