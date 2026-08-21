import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../../../components/containers"
import "../../../components/ui" as UI

Popup {
    id: wifiWindow
    popupWidth: 320
    popupHeight: {
        if (showPasswordPrompt) return (pwdPrompt.errorMessage !== "") ? 250 : 220;
        var count = Math.min(wifiList.length, 6);
        return 24 + 10 + 30 + 1 + 12 + (count > 0 ? (count * 48 + 12) : 100) + 20;
    }

    property var wifiList: []
    property var savedSsids: ({})
    property bool isScanning: wifiScanner.running
    property string selectedSsid: ""
    property string selectedSecurity: ""
    property bool showPasswordPrompt: false

    Timer {
        id: bgScanTimer
        interval: 15000
        running: wifiWindow.active
        repeat: true
        triggeredOnStart: false
        onTriggered: wifiWindow.refreshWifi()
    }

    function parseWifiList(text) {
        var lines = text.split("\n"), list = [], ssidsSeen = {}, savedMap = {}, mode = "";
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "SAVED:") { mode = "SAVED"; continue; }
            if (line === "SCANNED:") { mode = "SCANNED"; continue; }
            if (mode === "SAVED" && line !== "") savedMap[line] = true;
            else if (mode === "SCANNED" && line !== "") {
                var parts = line.split(":");
                if (parts.length >= 4 && parts[0] !== "" && !ssidsSeen[parts[0]]) {
                    ssidsSeen[parts[0]] = true;
                    var isActive = parts[3] === "yes";
                    if (isActive) wifiWindow.activeConnectedSsid = parts[0];
                    list.push({ ssid: parts[0], signal: parseInt(parts[1]) || 0, security: parts[2], active: isActive, saved: !!savedMap[parts[0]] });
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
        stdout: StdioCollector { onStreamFinished: wifiWindow.parseWifiList(this.text) }
    }

    property string activeConnectedSsid: ""

    property var wifiConnector: Process {
        id: wifiConnector
        property string errorOutput: ""
        property string targetSsid: ""
        property string fallbackSsid: ""

        function connectTo(ssid, password) {
            targetSsid = ssid;
            fallbackSsid = wifiWindow.activeConnectedSsid;
            errorOutput = "";
            command = (password && password !== "") ? ["nmcli", "device", "wifi", "connect", ssid, "password", password] : ["nmcli", "device", "wifi", "connect", ssid];
            running = false;
            running = true;
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim() !== "") {
                    wifiConnector.errorOutput = this.text.trim();
                }
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.indexOf("Error") !== -1) {
                    wifiConnector.errorOutput = this.text.trim();
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && (!errorOutput || errorOutput.indexOf("Error") === -1)) {
                wifiWindow.showPasswordPrompt = false;
                wifiWindow.active = false;
                wifiWindow.refreshWifi();
            } else {
                if (targetSsid && targetSsid !== "") {
                    Quickshell.execDetached(["nmcli", "connection", "delete", "id", targetSsid]);
                }
                if (fallbackSsid && fallbackSsid !== "" && fallbackSsid !== targetSsid) {
                    Quickshell.execDetached(["nmcli", "connection", "up", "id", fallbackSsid]);
                }

                if (wifiWindow.showPasswordPrompt) {
                    var msg = "Incorrect password. Please try again.";
                    if (errorOutput.indexOf("timeout") !== -1) msg = "Connection timed out. Please try again.";
                    pwdPrompt.showError(msg);
                } else {
                    wifiWindow.active = false;
                }
            }
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

    Shortcut { sequence: "Escape"; enabled: wifiWindow.active; onActivated: wifiWindow.active = false }

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

            IconImage {
                width: 16
                height: 16
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/arrow-clockwise-filled.svg")
                layer.enabled: true
                layer.effect: MultiEffect { colorization: 1.0; colorizationColor: wifiWindow.theme.getColor("primary") }
                RotationAnimation on rotation { running: wifiWindow.isScanning; from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiWindow.refreshWifi() }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: wifiWindow.theme.getColor("surfaceVariant") }

        ColumnLayout {
            Layout.fillWidth: true
            visible: wifiWindow.wifiList.length === 0
            spacing: 8
            Layout.topMargin: 12

            IconImage {
                width: 32
                height: 32
                source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("wifi/wifi-off.svg")
                Layout.alignment: Qt.AlignHCenter
                layer.enabled: true
                layer.effect: MultiEffect { colorization: 1.0; colorizationColor: wifiWindow.theme.getColor("outline") }
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
            theme: wifiWindow.theme
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: wifiWindow.wifiList.length > 0
            clip: true
            pillColor: wifiWindow.theme ? wifiWindow.theme.getColor("surfaceVariant") : "#2b2a27"
            pillRadius: 10
            pillMargin: 4
            spacing: 4
            model: wifiWindow.wifiList
            delegate: WifiItemDelegate {
                parentListView: wifiListView
                theme: wifiWindow.theme
                onItemClicked: info => {
                    if (info.active) return;
                    wifiWindow.selectedSsid = info.ssid;
                    wifiWindow.selectedSecurity = info.security;
                    if (info.saved || info.security === "") wifiWindow.wifiConnector.connectTo(wifiWindow.selectedSsid, "");
                    else { wifiWindow.showPasswordPrompt = true; pwdPrompt.focusInput(); }
                }
            }
        }
    }

    WifiPasswordPrompt {
        id: pwdPrompt
        theme: wifiWindow.theme
        selectedSsid: wifiWindow.selectedSsid
        wifiConnector: wifiWindow.wifiConnector
        visible: wifiWindow.showPasswordPrompt
        onCancelRequested: wifiWindow.showPasswordPrompt = false
        onConnectRequested: pwd => {
            wifiWindow.wifiConnector.connectTo(wifiWindow.selectedSsid, pwd);
        }
    }
}
