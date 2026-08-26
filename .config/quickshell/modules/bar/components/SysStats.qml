import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: sysStats

    property double cpuUsage: 0.0
    property double memUsage: 0.0
    property double swapUsage: 0.0
    property int batteryPercentage: 100
    property bool batteryIsCharging: false

    property string networkSsid: "Disconnected"
    property string networkDown: "0 B/s"
    property string networkUp: "0 B/s"
    property int wifiSignal: -1

    property var telemetryProc: Process {
        id: telemetryProc
        command: ["python", ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getScript("sys_telemetry.py")]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var parsed = JSON.parse(data.trim());
                    if (!parsed) return;

                    if (parsed.cpu !== undefined) sysStats.cpuUsage = parsed.cpu;
                    if (parsed.memory !== undefined) sysStats.memUsage = parsed.memory;
                    if (parsed.swap !== undefined) sysStats.swapUsage = parsed.swap;

                    if (parsed.battery) {
                        sysStats.batteryPercentage = parsed.battery.percentage;
                        sysStats.batteryIsCharging = parsed.battery.charging;
                    }

                    if (parsed.network) {
                        sysStats.networkSsid = parsed.network.ssid || "Disconnected";
                        sysStats.networkDown = parsed.network.down || "0 B/s";
                        sysStats.networkUp = parsed.network.up || "0 B/s";
                        sysStats.wifiSignal = parsed.network.signal !== undefined ? parsed.network.signal : -1;
                    }
                } catch(e) {}
            }
        }
    }
}
