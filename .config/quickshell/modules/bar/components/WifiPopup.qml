import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import "../../../components/ui" as UI

PanelWindow {
    id: wifiWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    visible: active || morphContainer.opacity > 0.01

    property var theme
    property real targetX: -1

    readonly property int safeWidth: wifiWindow.width > 0 ? wifiWindow.width : 1920
    readonly property int expandedWidth: 320
    readonly property int collapsedWidth: 140
    readonly property int expandedHeight: {
        if (showPasswordPrompt) return (pwdPrompt.errorMessage !== "") ? 260 : 230;
        var count = Math.min(wifiList.length, 6);
        if (count === 0 && isScanning) count = 3;
        return 40 + 1 + 12 + (count > 0 ? (count * 48 + 12) : 100) + 16;
    }

    property var wifiList: []
    property var savedSsids: ({})
    property bool isScanning: wifiScanner.running
    property string selectedSsid: ""
    property string selectedSecurity: ""
    property bool showPasswordPrompt: false
    property string activeConnectedSsid: ""

    property alias closeTimer: closeTimer
    readonly property var pwdPromptRef: pwdPrompt

    Timer {
        id: closeTimer
        interval: 80
        repeat: false
        onTriggered: wifiWindow.active = false
    }

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
                if (this.text && this.text.trim() !== "") wifiConnector.errorOutput = this.text.trim();
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.indexOf("Error") !== -1) wifiConnector.errorOutput = this.text.trim();
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && (!errorOutput || errorOutput.indexOf("Error") === -1)) {
                wifiWindow.showPasswordPrompt = false;
                wifiWindow.active = false;
                wifiWindow.refreshWifi();
            } else {
                if (targetSsid && targetSsid !== "") Quickshell.execDetached(["nmcli", "connection", "delete", "id", targetSsid]);
                if (fallbackSsid && fallbackSsid !== "" && fallbackSsid !== targetSsid) Quickshell.execDetached(["nmcli", "connection", "up", "id", fallbackSsid]);

                if (wifiWindow.showPasswordPrompt) {
                    var msg = "Incorrect password. Please try again.";
                    if (errorOutput.indexOf("timeout") !== -1) msg = "Connection timed out. Please try again.";
                    pwdPrompt.showError(msg);
                } else wifiWindow.active = false;
            }
        }
    }

    onActiveChanged: {
        if (active) {
            showPasswordPrompt = false;
            selectedSsid = "";
            selectedSecurity = "";
            closeTimer.stop();
            refreshWifi();
        }
    }

    Shortcut { sequence: "Escape"; enabled: wifiWindow.active; onActivated: wifiWindow.active = false }

    MouseArea {
        anchors.fill: parent
        enabled: wifiWindow.active
        hoverEnabled: true
        onClicked: wifiWindow.active = false
        onEntered: closeTimer.restart()
    }

    Rectangle {
        id: morphContainer
        x: targetX > 0 ? Math.max(10, Math.min(targetX - width, safeWidth - width - 10)) : (safeWidth - expandedWidth - 10)
        y: 6
        width: wifiWindow.active ? wifiWindow.expandedWidth : wifiWindow.collapsedWidth
        height: wifiWindow.active ? wifiWindow.expandedHeight : 34
        radius: wifiWindow.active ? 20 : 16
        color: wifiWindow.theme ? wifiWindow.theme.getColor("surface") : "#1e1e2e"
        clip: true
        opacity: wifiWindow.active ? 1.0 : 0.0

        Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on radius { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: wifiWindow.active
            shadowColor: "#60000000"
            shadowBlur: 1.0
            shadowVerticalOffset: 8
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: closeTimer.stop()
            onPositionChanged: closeTimer.stop()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                height: 24

                RowLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    IconImage {
                        width: 16
                        height: 16
                        source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/globe.svg")
                        layer.enabled: true
                        layer.effect: MultiEffect { colorization: 1.0; colorizationColor: wifiWindow.theme ? wifiWindow.theme.getColor("primary") : "#adc6ff" }
                    }

                    UI.Typography {
                        theme: wifiWindow.theme
                        text: "Wi-Fi Networks"
                        variant: "titleMedium"
                        font.pixelSize: 14
                        font.bold: true
                        colorRole: "onSurface"
                    }
                }

                Item { Layout.fillWidth: true }

                IconImage {
                    width: 16
                    height: 16
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/arrow-clockwise-filled.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect { colorization: 1.0; colorizationColor: wifiWindow.theme ? wifiWindow.theme.getColor("primary") : "#adc6ff" }
                    RotationAnimation on rotation { running: wifiWindow.isScanning; from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiWindow.refreshWifi() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: wifiWindow.theme ? wifiWindow.theme.getColor("outlineVariant") : "#20FFFFFF"
                opacity: 0.35
            }

            WifiNetworksList {
                wifiWindow: wifiWindow
                theme: wifiWindow.theme
                visible: !wifiWindow.showPasswordPrompt
                opacity: wifiWindow.active ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
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
    }
}
