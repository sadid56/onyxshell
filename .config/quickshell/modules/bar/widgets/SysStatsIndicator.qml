import QtQuick
import QtQuick.Layouts
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

    function getBatteryIcon(percentage, isCharging) {
        if (isCharging) return "󰂄";
        var icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        var idx = Math.floor(percentage / 10);
        if (idx < 0) idx = 0;
        if (idx >= icons.length) idx = icons.length - 1;
        return icons[idx];
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

                Text {
                    text: "󰁅 " + sysStatsRoot.sysStats.networkDown
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

                Text {
                    text: "󰁝 " + sysStatsRoot.sysStats.networkUp
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

                Text {
                    id: wifiIcon
                    text: sysStatsRoot.sysStats.networkSsid === "Disconnected" ? "" : ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                    color: sysStatsRoot.sysStats.networkSsid === "Disconnected" ? sysStatsRoot.theme.getColor("error") : sysStatsRoot.theme.getColor("onSurface")
                    opacity: {
                        if (sysStatsRoot.sysStats.networkSsid === "Disconnected") return 1.0;
                        var sig = sysStatsRoot.sysStats.wifiSignal;
                        if (sig < 0) return 1.0;
                        if (sig > 75) return 1.0;
                        if (sig > 50) return 0.75;
                        if (sig > 25) return 0.50;
                        return 0.35;
                    }
                }
            }
        }

        UIFeedback.StatsItem {
            theme: sysStatsRoot.theme
            icon: ""
            value: Math.round(sysStatsRoot.sysStats.cpuUsage) + "%"
        }

        UIFeedback.StatsItem {
            theme: sysStatsRoot.theme
            icon: "󰾆"
            value: Math.round(sysStatsRoot.sysStats.memUsage) + "%"
        }

        UIFeedback.StatsItem {
            theme: sysStatsRoot.theme
            icon: getBatteryIcon(sysStatsRoot.sysStats.batteryPercentage, sysStatsRoot.sysStats.batteryIsCharging)
            value: sysStatsRoot.sysStats.batteryPercentage + "%"
            customColor: sysStatsRoot.sysStats.batteryPercentage < 20 ? sysStatsRoot.theme.getColor("error") : ""
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
        
        Text {
            anchors.centerIn: parent
            text: sysStatsRoot.notifCount > 0 ? "󰂚" : "󰂜"
            font.pixelSize: 15
            color: sysStatsRoot.theme.getColor("primary")
            font.family: "JetBrainsMono Nerd Font"
            font.bold: true
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
