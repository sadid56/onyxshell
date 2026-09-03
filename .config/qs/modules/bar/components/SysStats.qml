import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.UPower
import "../../../core"

Item {
    id: sysStats

    property double cpuUsage: 0.0
    property double memUsage: 0.0
    property double swapUsage: 0.0
    property int batteryPercentage: (UPower.displayDevice && UPower.displayDevice.ready) ? Math.round(UPower.displayDevice.percentage * 100) : 100
    property bool batteryIsCharging: (UPower.displayDevice && UPower.displayDevice.ready) ? (UPower.displayDevice.state === 1) : false

    property string networkSsid: "Disconnected"
    property string networkDown: "0 B/s"
    property string networkUp: "0 B/s"
    property int wifiSignal: -1
    property bool wifiEnabled: Networking.wifiEnabled

    function updateNativeNetwork() {
        if (!Networking.wifiEnabled) {
            sysStats.networkSsid = "Disconnected";
            sysStats.wifiSignal = -1;
            return;
        }

        var found = false;
        if (Networking.devices && Networking.devices.values) {
            for (var i = 0; i < Networking.devices.values.length; i++) {
                var dev = Networking.devices.values[i];
                if (dev && dev.connected) {
                    if (dev.type === 1) { // WifiDevice
                        if (dev.networks && dev.networks.values) {
                            for (var j = 0; j < dev.networks.values.length; j++) {
                                var net = dev.networks.values[j];
                                if (net && net.connected) {
                                    sysStats.networkSsid = net.name || "Connected";
                                    sysStats.wifiSignal = Math.round((net.signalStrength || 0) * 100);
                                    found = true;
                                    break;
                                }
                            }
                        }
                        if (!found) {
                            sysStats.networkSsid = "Connected";
                            sysStats.wifiSignal = 100;
                            found = true;
                        }
                        break;
                    } else if (dev.type === 2) { // WiredDevice
                        sysStats.networkSsid = "Ethernet";
                        sysStats.wifiSignal = 100;
                        found = true;
                        break;
                    }
                }
            }
        }

        if (!found) {
            sysStats.networkSsid = "Disconnected";
            sysStats.wifiSignal = -1;
        }
    }

    Connections {
        target: Networking
        function onWifiEnabledChanged() { sysStats.updateNativeNetwork(); }
        function onConnectivityChanged() { sysStats.updateNativeNetwork(); }
    }

    Connections {
        target: Networking.devices
        function onValuesChanged() { sysStats.updateNativeNetwork(); }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sysStats.updateNativeNetwork()
    }

    Paths { id: paths }

    property var telemetryProc: Process {
        id: telemetryProc
        command: [paths.sysTelemetry]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var parsed = JSON.parse(data.trim());
                    if (!parsed) return;

                    if (parsed.cpu !== undefined) sysStats.cpuUsage = parsed.cpu;
                    if (parsed.memory !== undefined) sysStats.memUsage = parsed.memory;
                    if (parsed.swap !== undefined) sysStats.swapUsage = parsed.swap;

                    if (parsed.network) {
                        sysStats.networkDown = parsed.network.down || "0 B/s";
                        sysStats.networkUp = parsed.network.up || "0 B/s";
                    }
                } catch(e) {}
            }
        }
    }
}
