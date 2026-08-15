import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

BasePopup {
    id: wifiWindow

    popupWidth: 320
    popupHeight: {
        if (showPasswordPrompt) return 220;
        // topOverlap + padding + header + divider + spacing + list items (48px each, max 6) + bottom padding
        var listCount = Math.min(wifiList.length, 6);
        var listHeight = listCount > 0 ? (listCount * 48 + 12) : 100; // 100 for empty/scanning placeholder
        return 24 + 10 + 30 + 1 + 12 + listHeight + 20;
    }
    topOverlap: 14

    property var wifiList: []
    property bool isScanning: wifiScanner.running
    
    // Connection prompt state
    property string selectedSsid: ""
    property string selectedSecurity: ""
    property bool showPasswordPrompt: false

    // Background periodic Wi-Fi scanner (scans every 30s)
    Timer {
        id: bgScanTimer
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiWindow.refreshWifi()
    }

    function parseWifiList(text) {
        var lines = text.split("\n");
        var list = [];
        var ssidsSeen = {};
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "") continue;
            var parts = line.split(":");
            if (parts.length >= 4) {
                var ssid = parts[0];
                var signal = parseInt(parts[1]) || 0;
                var security = parts[2];
                var active = parts[3] === "yes";
                
                if (ssid !== "" && !ssidsSeen[ssid]) {
                    ssidsSeen[ssid] = true;
                    list.push({ ssid: ssid, signal: signal, security: security, active: active });
                }
            }
        }
        wifiList = list;
    }

    function refreshWifi() {
        wifiScanner.running = false;
        wifiScanner.running = true;
    }

    property var wifiScanner: Process {
        id: wifiScanner
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,ACTIVE", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                wifiWindow.parseWifiList(this.text);
            }
        }
    }

    property var wifiConnector: Process {
        id: wifiConnector
        function connectTo(ssid, password) {
            if (password && password !== "") {
                command = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
            } else {
                command = ["nmcli", "device", "wifi", "connect", ssid];
            }
            running = false;
            running = true;
        }
        onExited: {
            wifiWindow.active = false;
        }
    }

    property var wifiDisconnector: Process {
        id: wifiDisconnector
        command: ["nmcli", "device", "disconnect", "wlan0"]
        onExited: {
            wifiWindow.refreshWifi();
        }
    }

    onActiveChanged: {
        if (active) {
            showPasswordPrompt = false;
            selectedSsid = "";
            selectedSecurity = "";
            refreshWifi();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: wifiWindow.active
        onActivated: wifiWindow.active = false
    }

    // Inside BasePopup, children are automatically loaded into ColumnLayout inside contentRect.

    // --- Network List Page ---
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12
        visible: !wifiWindow.showPasswordPrompt

        // Header Section
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "Wi-Fi Networks"
                font.family: "Noto Sans"
                font.pixelSize: 15
                font.bold: true
                color: wifiWindow.theme.getColor("onSurface")
                Layout.fillWidth: true
            }

            // Refresh Button
            Text {
                text: wifiWindow.isScanning ? "󱑂" : "󰑐"
                font.family: "Noto Sans"
                font.pixelSize: 15
                color: wifiWindow.theme.getColor("primary")
                font.bold: true
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wifiWindow.refreshWifi()
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: wifiWindow.theme.getColor("surfaceVariant")
        }

        // Empty / Loading Placeholder
        ColumnLayout {
            Layout.fillWidth: true
            visible: wifiWindow.wifiList.length === 0
            spacing: 8
            Layout.topMargin: 12

            Text {
                text: "󰤯"
                font.family: "Noto Sans"
                font.pixelSize: 32
                color: wifiWindow.theme.getColor("outline")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: wifiWindow.isScanning ? "Scanning for networks..." : "No networks found"
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 13
                font.bold: true
                color: wifiWindow.theme.getColor("outline")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Network List View
        ListView {
            id: wifiListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: wifiWindow.wifiList.length > 0
            clip: true
            model: wifiWindow.wifiList
            spacing: 6

            delegate: Rectangle {
                id: delegateBg
                width: wifiListView.width
                height: 42
                radius: 8
                color: mouseArea.containsMouse ? wifiWindow.theme.getColor("surfaceVariant") : "transparent"

                property var netInfo: modelData

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: delegateBg.netInfo.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (delegateBg.netInfo.active) return; // Already connected, do nothing
                        wifiWindow.selectedSsid = delegateBg.netInfo.ssid;
                        wifiWindow.selectedSecurity = delegateBg.netInfo.security;
                        if (delegateBg.netInfo.security !== "" && delegateBg.netInfo.security.indexOf("EP") === -1) {
                            wifiWindow.showPasswordPrompt = true;
                            passwordInput.forceFocus();
                        } else {
                            wifiWindow.wifiConnector.connectTo(wifiWindow.selectedSsid, "");
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    // Signal Icon
                    Text {
                        text: {
                            var sig = delegateBg.netInfo.signal;
                            if (sig > 75) return "󰤨";
                            if (sig > 50) return "󰤥";
                            if (sig > 25) return "󰤢";
                            return "󰤟";
                        }
                        font.family: "Noto Sans"
                        font.pixelSize: 14
                        color: delegateBg.netInfo.active ? wifiWindow.theme.getColor("primary") : wifiWindow.theme.getColor("onSurface")
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // SSID Name
                    Text {
                        text: delegateBg.netInfo.ssid
                        font.family: "Noto Sans"
                        font.pixelSize: 12
                        font.bold: delegateBg.netInfo.active
                        color: delegateBg.netInfo.active ? wifiWindow.theme.getColor("primary") : wifiWindow.theme.getColor("onSurface")
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Connected / Secure indicator
                    Text {
                        text: delegateBg.netInfo.active ? "Connected" : (delegateBg.netInfo.security !== "" ? "󰌾" : "")
                        font.family: delegateBg.netInfo.active ? "Google Sans Flex, sans-serif" : "Noto Sans"
                        font.pixelSize: delegateBg.netInfo.active ? 10 : 11
                        font.bold: delegateBg.netInfo.active
                        color: delegateBg.netInfo.active ? wifiWindow.theme.getColor("primary") : wifiWindow.theme.getColor("outline")
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }

    // --- Password Prompt Page ---
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16
        visible: wifiWindow.showPasswordPrompt

        Text {
            text: "Connect to Network"
            font.family: "Noto Sans"
            font.pixelSize: 15
            font.bold: true
            color: wifiWindow.theme.getColor("onSurface")
        }

        Text {
            text: wifiWindow.selectedSsid
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 13
            font.bold: true
            color: wifiWindow.theme.getColor("primary")
        }

        // Password Field Container
        Rectangle {
            Layout.fillWidth: true
            height: 42
            radius: 10
            color: wifiWindow.theme.getColor("surfaceVariant")
            border.color: passwordInput.activeFocus ? wifiWindow.theme.getColor("primary") : "transparent"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                TextInput {
                    id: passwordInput
                    Layout.fillWidth: true
                    color: wifiWindow.theme.getColor("onSurface")
                    font.family: "Noto Sans"
                    font.pixelSize: 13
                    echoMode: TextInput.Password
                    selectByMouse: true
                    Layout.alignment: Qt.AlignVCenter

                    function forceFocus() {
                        passwordInput.forceActiveFocus();
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            wifiWindow.showPasswordPrompt = false;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return) {
                            wifiWindow.wifiConnector.connectTo(wifiWindow.selectedSsid, passwordInput.text);
                            passwordInput.text = "";
                            wifiWindow.showPasswordPrompt = false;
                            event.accepted = true;
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Cancel Button
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: wifiWindow.theme.getColor("surfaceVariant")
                
                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                    font.bold: true
                    color: wifiWindow.theme.getColor("onSurface")
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        passwordInput.text = "";
                        wifiWindow.showPasswordPrompt = false;
                    }
                }
            }

            // Connect Button
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: wifiWindow.theme.getColor("primary")
                
                Text {
                    anchors.centerIn: parent
                    text: "Connect"
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                    font.bold: true
                    color: wifiWindow.theme.getColor("onPrimary")
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wifiWindow.wifiConnector.connectTo(wifiWindow.selectedSsid, passwordInput.text);
                        passwordInput.text = "";
                        wifiWindow.showPasswordPrompt = false;
                    }
                }
            }
        }
    }
}
