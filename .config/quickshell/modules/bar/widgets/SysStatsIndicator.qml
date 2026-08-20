import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
Row {
    id: sysStatsRoot
    spacing: 16
    property var theme
    property var sysStats
    property var toggleNotifications
    property var toggleWifi
    property int notifCount: 0
    function getWifiX() { var pos = netClickArea.mapToItem(null, 0, 0); return pos.x + netClickArea.width / 2; }
    function getResourcesX() { var pos = resourcesClickArea.mapToItem(null, 0, 0); return pos.x + resourcesClickArea.width / 2; }
    function getNotifX() { var pos = notifButton.mapToItem(null, 0, 0); return pos.x + notifButton.width / 2; }

    RowLayout {
        spacing: 16
        Layout.alignment: Qt.AlignVCenter
        MouseArea {
            id: netClickArea
            Layout.preferredWidth: netIndicator.implicitWidth
            Layout.preferredHeight: netIndicator.implicitHeight
            Layout.alignment: Qt.AlignVCenter
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: { root.stopLoaderTimerAndActivate(wifiLoader, statusBar.getWifiX()); root.setLoaderInactive(calendarLoader); root.setLoaderInactive(notifsLoader); root.setLoaderInactive(resourcesLoader); }
            onExited: root.restartLoaderTimer(wifiLoader)
            onClicked: root.toggleLoaderActive(wifiLoader, statusBar.getWifiX())
            NetworkIndicator { id: netIndicator; theme: sysStatsRoot.theme; sysStats: sysStatsRoot.sysStats }
        }
        MouseArea {
            id: resourcesClickArea
            Layout.preferredWidth: resourcesRow.implicitWidth
            Layout.preferredHeight: resourcesRow.implicitHeight
            Layout.alignment: Qt.AlignVCenter
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: { root.stopLoaderTimerAndActivate(resourcesLoader, statusBar.getResourcesX()); root.setLoaderInactive(calendarLoader); root.setLoaderInactive(notifsLoader); root.setLoaderInactive(wifiLoader); }
            onExited: root.restartLoaderTimer(resourcesLoader)
            onClicked: root.toggleLoaderActive(resourcesLoader, statusBar.getResourcesX())

            RowLayout {
                id: resourcesRow
                spacing: 14
                anchors.centerIn: parent

                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter
                    IconImage {
                        width: 15; height: 15
                        Layout.alignment: Qt.AlignVCenter
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getCpuIcon()
                        layer.enabled: true
                        layer.effect: MultiEffect { colorization: 1.0; colorizationColor: sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF" }
                    }
                    Text {
                        text: Math.round(sysStatsRoot.sysStats.cpuUsage) + "%"
                        font.family: "Noto Sans"
                        font.pixelSize: 13
                        font.bold: true
                        color: sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter
                    IconImage {
                        width: 15; height: 15
                        Layout.alignment: Qt.AlignVCenter
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getSwapIcon()
                        layer.enabled: true
                        layer.effect: MultiEffect { colorization: 1.0; colorizationColor: "#FFFFFF" }
                    }
                    Text {
                        text: Math.round(sysStatsRoot.sysStats.swapUsage || 0) + "%"
                        font.family: "Noto Sans"
                        font.pixelSize: 13
                        font.bold: true
                        color: sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter
                    IconImage {
                        width: 15; height: 15
                        Layout.alignment: Qt.AlignVCenter
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getMemoryIcon()
                        layer.enabled: true
                        layer.effect: MultiEffect { colorization: 1.0; colorizationColor: sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF" }
                    }
                    Text {
                        text: Math.round(sysStatsRoot.sysStats.memUsage) + "%"
                        font.family: "Noto Sans"
                        font.pixelSize: 13
                        font.bold: true
                        color: sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter
            IconImage {
                width: 22
                height: 22
                Layout.alignment: Qt.AlignVCenter
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getBatteryIcon(
                    sysStatsRoot.sysStats.batteryPercentage,
                    sysStatsRoot.sysStats.batteryIsCharging
                )
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: sysStatsRoot.sysStats.batteryPercentage < 20
                        ? (sysStatsRoot.theme ? sysStatsRoot.theme.getColor("error") : "#ff5555")
                        : (sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF")
                }
            }
            Text {
                text: sysStatsRoot.sysStats.batteryPercentage + "%"
                font.family: "Noto Sans"
                font.pixelSize: 13
                font.bold: true
                color: sysStatsRoot.sysStats.batteryPercentage < 20
                    ? (sysStatsRoot.theme ? sysStatsRoot.theme.getColor("error") : "#ff5555")
                    : (sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF")
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
    Row {
        spacing: 12
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: trayItemDelegate
                width: 20; height: 20
                IconImage { anchors.fill: parent; source: modelData.icon || "" }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onEntered: { var pos = trayItemDelegate.mapToItem(null, 0, 0); root.showTrayMenu(modelData, pos.x + trayItemDelegate.width / 2); }
                    onExited: root.hideTrayMenu()
                    onClicked: {
                        modelData.activate();
                        var scriptPath = (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getScript("focus_tray_window.py");
                        Quickshell.execDetached([
                            "python", scriptPath,
                            modelData.id || "",
                            modelData.title || "",
                            modelData.icon || ""
                        ]);
                    }
                }
            }
        }
    }
    Item {
        id: notifButton
        width: 20; height: 20
        Layout.alignment: Qt.AlignVCenter
        IconImage {
            anchors.centerIn: parent; width: 18; height: 18
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getNotificationIcon(
                (typeof root !== "undefined" && root.dndEnabled),
                sysStatsRoot.notifCount > 0
            )
            layer.enabled: true
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: sysStatsRoot.theme ? sysStatsRoot.theme.getColor("primary") : "#ffb3b4" }
        }
        MouseArea {
            anchors.fill: parent; anchors.rightMargin: -20; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onEntered: { root.stopLoaderTimerAndActivate(notifsLoader, sysStatsRoot.getNotifX()); root.setLoaderInactive(calendarLoader); root.setLoaderInactive(wifiLoader); }
            onExited: root.restartLoaderTimer(notifsLoader)
            onClicked: root.toggleLoaderActive(notifsLoader, sysStatsRoot.getNotifX())
        }
    }
}
