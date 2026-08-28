import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../../../components/ui" as UI

Item {
    id: sysStatsRoot

    property var theme
    property var sysStats
    property var toggleNotifications: null
    property var toggleWifi: null
    property int notifCount: 0

    implicitHeight: 32
    implicitWidth: rowLayout.implicitWidth

    function pressureColor(value) {
        if (value >= 90) return sysStatsRoot.theme ? sysStatsRoot.theme.getColor("error") : "#ff5555";
        if (value >= 70) return sysStatsRoot.theme ? sysStatsRoot.theme.getColor("tertiary") : "#ffb74d";
        if (value >= 50) return sysStatsRoot.theme ? sysStatsRoot.theme.getColor("primary") : "#D0BCFF";
        return sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF";
    }

    function getResourcesX() {
        var pos = sysStatsRoot.mapToItem(null, 0, 0);
        return pos.x + sysStatsRoot.width / 2;
    }

    MouseArea {
        id: sysStatsMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            if (typeof root !== "undefined" && root.stopLoaderTimerAndActivate && typeof resourcesLoader !== "undefined" && typeof statusBar !== "undefined") {
                root.stopLoaderTimerAndActivate(resourcesLoader, statusBar.getResourcesX());
                if (typeof powerMenuLoader !== "undefined") root.setLoaderInactive(powerMenuLoader);
                if (typeof wifiLoader !== "undefined") root.setLoaderInactive(wifiLoader);
            }
        }
        onExited: {
            if (typeof root !== "undefined" && root.restartLoaderTimer && typeof resourcesLoader !== "undefined") {
                root.restartLoaderTimer(resourcesLoader);
            }
        }
        onClicked: {
            if (typeof root !== "undefined" && root.toggleLoaderActive && typeof resourcesLoader !== "undefined" && typeof statusBar !== "undefined") {
                root.toggleLoaderActive(resourcesLoader, statusBar.getResourcesX());
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 12

        RowLayout {
            spacing: 5
            Layout.alignment: Qt.AlignVCenter
            UI.Icon {
                size: 15
                icon: ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getCpuIcon()
                color: sysStatsRoot.pressureColor(sysStatsRoot.sysStats.cpuUsage)
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 400 } }
            }
            UI.Typography {
                theme: sysStatsRoot.theme
                text: Math.round(sysStatsRoot.sysStats.cpuUsage) + "%"
                variant: "labelMedium"
                font.weight: Font.Bold
                font.letterSpacing: 0.5
                Layout.preferredWidth: 28
                Layout.minimumWidth: 28
                Layout.maximumWidth: 28
                horizontalAlignment: Text.AlignLeft
                color: sysStatsRoot.pressureColor(sysStatsRoot.sysStats.cpuUsage)
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }

        RowLayout {
            spacing: 5
            Layout.alignment: Qt.AlignVCenter
            UI.Icon {
                size: 15
                icon: ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getSwapIcon()
                color: sysStatsRoot.pressureColor(sysStatsRoot.sysStats.swapUsage || 0)
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 400 } }
            }
            UI.Typography {
                theme: sysStatsRoot.theme
                text: Math.round(sysStatsRoot.sysStats.swapUsage || 0) + "%"
                variant: "labelMedium"
                font.weight: Font.Bold
                font.letterSpacing: 0.5
                Layout.preferredWidth: 28
                Layout.minimumWidth: 28
                Layout.maximumWidth: 28
                horizontalAlignment: Text.AlignLeft
                color: sysStatsRoot.pressureColor(sysStatsRoot.sysStats.swapUsage || 0)
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }

        RowLayout {
            spacing: 5
            Layout.alignment: Qt.AlignVCenter
            UI.Icon {
                size: 15
                icon: ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getMemoryIcon()
                color: sysStatsRoot.pressureColor(sysStatsRoot.sysStats.memUsage)
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 400 } }
            }
            UI.Typography {
                theme: sysStatsRoot.theme
                text: Math.round(sysStatsRoot.sysStats.memUsage) + "%"
                variant: "labelMedium"
                font.weight: Font.Bold
                font.letterSpacing: 0.5
                Layout.preferredWidth: 28
                Layout.minimumWidth: 28
                Layout.maximumWidth: 28
                horizontalAlignment: Text.AlignLeft
                color: sysStatsRoot.pressureColor(sysStatsRoot.sysStats.memUsage)
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }

        RowLayout {
            spacing: 5
            Layout.alignment: Qt.AlignVCenter

            UI.Icon {
                size: 22
                icon: ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getBatteryIcon(
                    sysStatsRoot.sysStats.batteryPercentage,
                    sysStatsRoot.sysStats.batteryIsCharging
                )
                color: sysStatsRoot.sysStats.batteryPercentage < 20
                    ? (sysStatsRoot.theme ? sysStatsRoot.theme.getColor("error") : "#ff5555")
                    : (sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF")
                Layout.alignment: Qt.AlignVCenter
            }

            UI.Typography {
                theme: sysStatsRoot.theme
                text: sysStatsRoot.sysStats.batteryPercentage + "%"
                variant: "labelMedium"
                font.weight: Font.Bold
                Layout.preferredWidth: 28
                Layout.minimumWidth: 28
                Layout.maximumWidth: 28
                horizontalAlignment: Text.AlignLeft
                color: sysStatsRoot.sysStats.batteryPercentage < 20
                    ? (sysStatsRoot.theme ? sysStatsRoot.theme.getColor("error") : "#ff5555")
                    : (sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF")
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
