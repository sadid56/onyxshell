import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../components/containers"
import "../../../components/ui" as UI

Popup {
    id: wifiWindow

    popupWidth: 320
    popupHeight: {
        if (showPasswordPrompt) return 220;
        var listCount = Math.min(wifiList.length, 6);
        var listHeight = listCount > 0 ? (listCount * 48 + 12) : 100;
        return 24 + 10 + 30 + 1 + 12 + listHeight + 20;
    }
    topOverlap: 14

    property var wifiList: []
    property var savedSsids: ({})
    property bool isScanning: wifiScanner.running
    
    property string selectedSsid: ""
    property string selectedSecurity: ""
    property bool showPasswordPrompt: false

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
        var savedMap = {};
        var mode = "";

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "SAVED:") {
                mode = "SAVED";
                continue;
            } else if (line === "SCANNED:") {
                mode = "SCANNED";
                continue;
            }

            if (mode === "SAVED" && line !== "") {
                savedMap[line] = true;
            } else if (mode === "SCANNED" && line !== "") {
                var parts = line.split(":");
                if (parts.length >= 4) {
                    var ssid = parts[0];
                    var signal = parseInt(parts[1]) || 0;
                    var security = parts[2];
                    var active = parts[3] === "yes";
                    
                    if (ssid !== "" && !ssidsSeen[ssid]) {
                        ssidsSeen[ssid] = true;
                        list.push({
                            ssid: ssid,
                            signal: signal,
                            security: security,
                            active: active,
                            saved: !!savedMap[ssid]
                        });
                    }
                }
            }
        }
        savedSsids = savedMap;
        wifiList = list;
    }

    function refreshWifi() {
        wifiScanner.running = false;
        wifiScanner.running = true;
    }

    property var wifiScanner: Process {
        id: wifiScanner
        command: ["sh", "-c", "echo 'SAVED:'; nmcli -t -f NAME,TYPE connection show | grep '802-11-wireless' | cut -d: -f1; echo 'SCANNED:'; nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE device wifi list"]
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

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12
        visible: !wifiWindow.showPasswordPrompt

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

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: wifiWindow.theme.getColor("surfaceVariant")
        }

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

        UI.AnimatedListView {
            id: wifiListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: wifiWindow.wifiList.length > 0
            clip: true
            pillColor: wifiWindow.theme.getColor("surfaceVariant")
            pillRadius: 10
            pillMargin: 4
            spacing: 4

            model: wifiWindow.wifiList

            delegate: Item {
                id: delegateWrapper
                width: wifiListView.width
                height: 42
                z: 1

                readonly property var netInfo: modelData
                readonly property bool isHighlighted: wifiListView.isItemHighlighted(index)

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: delegateWrapper.netInfo.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onEntered: {
                        wifiListView.hoverItem(index, delegateWrapper.y, delegateWrapper.height);
                    }
                    onExited: {
                        wifiListView.unhoverItem(index);
                    }
                    onClicked: {
                        if (delegateWrapper.netInfo.active) return;
                        wifiWindow.selectedSsid = delegateWrapper.netInfo.ssid;
                        wifiWindow.selectedSecurity = delegateWrapper.netInfo.security;
                        if (delegateWrapper.netInfo.saved || delegateWrapper.netInfo.security === "") {
                            wifiWindow.wifiConnector.connectTo(wifiWindow.selectedSsid, "");
                        } else {
                            wifiWindow.showPasswordPrompt = true;
                            passwordInput.forceFocus();
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: {
                            var sig = delegateWrapper.netInfo.signal;
                            if (sig > 75) return "󰤨";
                            if (sig > 50) return "󰤥";
                            if (sig > 25) return "󰤢";
                            return "󰤟";
                        }
                        font.family: "Noto Sans"
                        font.pixelSize: 15
                        color: delegateWrapper.netInfo.active ? wifiWindow.theme.getColor("primary") : (delegateWrapper.isHighlighted ? wifiWindow.theme.getColor("primary") : wifiWindow.theme.getColor("onSurface"))
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        text: delegateWrapper.netInfo.ssid
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 13
                        font.bold: delegateWrapper.netInfo.active || delegateWrapper.netInfo.saved
                        color: delegateWrapper.netInfo.active ? wifiWindow.theme.getColor("primary") : (delegateWrapper.isHighlighted ? wifiWindow.theme.getColor("primary") : wifiWindow.theme.getColor("onSurface"))
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        text: {
                            if (delegateWrapper.netInfo.active) return "Connected";
                            if (delegateWrapper.netInfo.saved) return "Saved";
                            if (delegateWrapper.netInfo.security !== "") return "󰌾";
                            return "";
                        }
                        font.family: (delegateWrapper.netInfo.active || delegateWrapper.netInfo.saved) ? "Google Sans Flex, sans-serif" : "Noto Sans"
                        font.pixelSize: (delegateWrapper.netInfo.active || delegateWrapper.netInfo.saved) ? 10 : 12
                        font.bold: delegateWrapper.netInfo.active || delegateWrapper.netInfo.saved
                        color: delegateWrapper.netInfo.active ? wifiWindow.theme.getColor("primary") : (delegateWrapper.netInfo.saved ? wifiWindow.theme.getColor("primary") : wifiWindow.theme.getColor("outline"))
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }

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

        UI.Input {
            id: passwordInput
            theme: wifiWindow.theme
            placeholder: "Enter password..."
            icon: "󰌾"
            echoMode: TextInput.Password
            onEscapePressed: {
                wifiWindow.showPasswordPrompt = false;
            }
            onReturnPressed: {
                wifiWindow.wifiConnector.connectTo(wifiWindow.selectedSsid, passwordInput.text);
                passwordInput.text = "";
                wifiWindow.showPasswordPrompt = false;
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

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
