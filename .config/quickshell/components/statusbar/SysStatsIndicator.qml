import QtQuick
import QtQuick.Layouts
import Quickshell

Row {
    id: sysStatsRoot
    spacing: 16
    
    property var theme
    property var sysStats
    property var toggleNotifications
    property var toggleControlCenter
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

    // System Stats
    Row {
        spacing: 16
        Layout.alignment: Qt.AlignVCenter

        // Network SSID and Speeds
        MouseArea {
            id: netClickArea
            width: netRow.implicitWidth
            height: netRow.implicitHeight
            Layout.alignment: Qt.AlignVCenter
            cursorShape: Qt.PointingHandCursor
            
            hoverEnabled: true

            onEntered: {
                wifiPopup.targetX = statusBar.getWifiX();
                wifiPopup.closeTimer.stop();
                wifiPopup.active = true;
                calendarPopup.active = false;
                notifs.active = false;
            }

            onExited: {
                wifiPopup.closeTimer.restart();
            }

            onClicked: {
                wifiPopup.active = !wifiPopup.active;
            }

            Row {
                id: netRow
                spacing: 12

                // Network Speeds - Download
                Text {
                    text: "󰁅 " + sysStatsRoot.sysStats.networkDown
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                    color: {
                        var s = sysStatsRoot.sysStats.networkDown;
                        if (s.indexOf("MB/s") !== -1) return sysStatsRoot.theme.getColor("primary");
                        if (s.indexOf("KB/s") !== -1) {
                            var val = parseFloat(s);
                            if (val > 100) return sysStatsRoot.theme.getColor("primary");
                        }
                        return sysStatsRoot.theme.getColor("onSurface");
                    }
                }

                // Network Speeds - Upload
                Text {
                    text: "󰁝 " + sysStatsRoot.sysStats.networkUp
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                    color: {
                        var s = sysStatsRoot.sysStats.networkUp;
                        if (s.indexOf("MB/s") !== -1) return sysStatsRoot.theme.getColor("primary");
                        if (s.indexOf("KB/s") !== -1) {
                            var val = parseFloat(s);
                            if (val > 100) return sysStatsRoot.theme.getColor("primary");
                        }
                        return sysStatsRoot.theme.getColor("onSurface");
                    }
                }

                // Wifi Icon Second
                Text {
                    id: wifiIcon
                    text: sysStatsRoot.sysStats.networkSsid === "Disconnected" ? "󰤮" : ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                    color: sysStatsRoot.sysStats.networkSsid === "Disconnected" ? sysStatsRoot.theme.getColor("error") : sysStatsRoot.theme.getColor("primary")
                }
            }
        }

        // CPU
        Text {
            text: " " + Math.round(sysStatsRoot.sysStats.cpuUsage) + "%"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
            color: sysStatsRoot.theme.getColor("onSurface")
        }

        // RAM
        Text {
            text: "󰾆 " + Math.round(sysStatsRoot.sysStats.memUsage) + "%"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
            color: sysStatsRoot.theme.getColor("onSurface")
        }

        // Battery (SysFS battery percentage with dynamic icon)
        Text {
            text: getBatteryIcon(sysStatsRoot.sysStats.batteryPercentage, sysStatsRoot.sysStats.batteryIsCharging) + " " + sysStatsRoot.sysStats.batteryPercentage + "%"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
            color: sysStatsRoot.sysStats.batteryPercentage < 20 ? sysStatsRoot.theme.getColor("error") : sysStatsRoot.theme.getColor("onSurface")
        }
    }

    // Notification Center Button with Dynamic Count Badge
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

        // Badge showing count of notifications
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
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                notifs.targetX = sysStatsRoot.getNotifX();
                notifs.closeTimer.stop();
                notifs.active = true;
                calendarPopup.active = false;
                wifiPopup.active = false;
            }
            onExited: {
                notifs.closeTimer.restart();
            }
            onClicked: {
                notifs.active = !notifs.active;
            }
        }
    }

}
