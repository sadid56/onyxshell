import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../../components/feedback" as UIFeedback

Row {
    id: sysStatsRoot
    spacing: 16

    property var theme
    property var sysStats
    property var toggleNotifications
    property var toggleWifi
    property int notifCount: 0

    function getWifiX() {
        var pos = wifiIcon.mapToItem(null, 0, 0);
        return pos.x + wifiIcon.width / 2;
    }

    function getNotifX() {
        var pos = notifButton.mapToItem(null, 0, 0);
        return pos.x + notifButton.width / 2;
    }

    RowLayout {
        spacing: 16
        Layout.alignment: Qt.AlignVCenter

        MouseArea {
            id: netClickArea
            Layout.preferredWidth: netRow.implicitWidth
            Layout.preferredHeight: netRow.implicitHeight
            Layout.alignment: Qt.AlignVCenter
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onEntered: {
                root.stopLoaderTimerAndActivate(wifiLoader, statusBar.getWifiX());
                root.setLoaderInactive(calendarLoader);
                root.setLoaderInactive(notifsLoader);
            }

            onExited: {
                root.restartLoaderTimer(wifiLoader);
            }

            onClicked: {
                root.toggleLoaderActive(wifiLoader, statusBar.getWifiX());
            }

            RowLayout {
                id: netRow
                spacing: 12
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    IconImage {
                        width: 10
                        height: 10
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("arrow-down.svg")
                        Layout.alignment: Qt.AlignVCenter
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: netDownText.color
                        }
                    }

                    Text {
                        id: netDownText
                        text: sysStatsRoot.sysStats.networkDown
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                        color: {
                            var s = sysStatsRoot.sysStats.networkDown;
                            if (s.indexOf("MB/s") !== -1) {
                                var valMb = parseFloat(s);
                                if (valMb >= 5.0) return sysStatsRoot.theme.getColor("error");
                                return sysStatsRoot.theme.getColor("secondary");
                            }
                            if (s.indexOf("KB/s") !== -1) {
                                var valKb = parseFloat(s);
                                if (valKb >= 500.0) return sysStatsRoot.theme.getColor("secondary");
                                if (valKb >= 100.0) return sysStatsRoot.theme.getColor("primary");
                            }
                            return sysStatsRoot.theme.getColor("onSurface");
                        }
                    }
                }

                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    IconImage {
                        width: 10
                        height: 10
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("arrow-up.svg")
                        Layout.alignment: Qt.AlignVCenter
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: netUpText.color
                        }
                    }

                    Text {
                        id: netUpText
                        text: sysStatsRoot.sysStats.networkUp
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                        color: {
                            var s = sysStatsRoot.sysStats.networkUp;
                            if (s.indexOf("MB/s") !== -1) {
                                var valMb = parseFloat(s);
                                if (valMb >= 5.0) return sysStatsRoot.theme.getColor("error");
                                return sysStatsRoot.theme.getColor("secondary");
                            }
                            if (s.indexOf("KB/s") !== -1) {
                                var valKb = parseFloat(s);
                                if (valKb >= 500.0) return sysStatsRoot.theme.getColor("secondary");
                                if (valKb >= 100.0) return sysStatsRoot.theme.getColor("primary");
                            }
                            return sysStatsRoot.theme.getColor("onSurface");
                        }
                    }
                }

                IconImage {
                    id: wifiIcon
                    width: 20
                    height: 20
                    Layout.alignment: Qt.AlignVCenter
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getWifiIcon(
                        sysStatsRoot.sysStats.wifiSignal,
                        sysStatsRoot.sysStats.networkSsid !== "Disconnected",
                        true
                    )
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: sysStatsRoot.sysStats.networkSsid === "Disconnected"
                            ? (sysStatsRoot.theme ? sysStatsRoot.theme.getColor("error") : "#ff5555")
                            : (sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF")
                    }
                }
            }
        }

        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                width: 15
                height: 15
                Layout.alignment: Qt.AlignVCenter
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getCpuIcon()
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF"
                }
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
                width: 15
                height: 15
                Layout.alignment: Qt.AlignVCenter
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getMemoryIcon()
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: sysStatsRoot.theme ? sysStatsRoot.theme.getColor("onSurface") : "#FFFFFF"
                }
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

        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                id: batterySvgIcon
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
                width: 20
                height: 20

                IconImage {
                    anchors.fill: parent
                    source: modelData.icon || ""
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        var pos = trayItemDelegate.mapToItem(null, 0, 0);
                        var centerX = pos.x + trayItemDelegate.width / 2;
                        root.showTrayMenu(modelData, centerX);
                    }

                    onExited: {
                        root.hideTrayMenu();
                    }

                    onClicked: {
                        modelData.activate();
                    }
                }
            }
        }
    }

    Item {
        id: notifButton
        width: 20
        height: 20
        Layout.alignment: Qt.AlignVCenter

        IconImage {
            anchors.centerIn: parent
            width: 18
            height: 18
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getNotificationIcon(false)
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: sysStatsRoot.theme ? sysStatsRoot.theme.getColor("primary") : "#ffb3b4"
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: -5
            anchors.right: parent.right
            anchors.rightMargin: -5
            width: 14
            height: 14
            radius: 7
            color: sysStatsRoot.theme.getColor("error")
            visible: sysStatsRoot.notifCount > 0

            Text {
                anchors.centerIn: parent
                text: String(sysStatsRoot.notifCount)
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 9
                font.bold: true
                color: "black"
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: -20
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                root.stopLoaderTimerAndActivate(notifsLoader, sysStatsRoot.getNotifX());
                root.setLoaderInactive(calendarLoader);
                root.setLoaderInactive(wifiLoader);
            }
            onExited: {
                root.restartLoaderTimer(notifsLoader);
            }
            onClicked: {
                root.toggleLoaderActive(notifsLoader, sysStatsRoot.getNotifX());
            }
        }
    }
}
