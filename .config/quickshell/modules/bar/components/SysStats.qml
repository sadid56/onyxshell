import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: sysStats

    property double cpuUsage: 0.0
    property double memUsage: 0.0
    property int batteryPercentage: 100
    property bool batteryIsCharging: false

    property string networkSsid: "Disconnected"
    property string networkDown: "0 B/s"
    property string networkUp: "0 B/s"
    property int wifiSignal: -1

    property var netProc: Process {
        id: netProc
        command: ["python", shellConfig.getScript("net_telemetry.py")]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var parsed = JSON.parse(data.trim());
                    sysStats.networkSsid = parsed.ssid;
                    sysStats.networkDown = parsed.down;
                    sysStats.networkUp = parsed.up;
                    sysStats.wifiSignal = parsed.signal !== undefined ? parsed.signal : -1;
                } catch(e) {}
            }
        }
    }

    property var lastCpu: ({})

    Process {
        id: statsProc
        command: ["sh", "-c", "cat /proc/meminfo /proc/stat /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT0/status 2>/dev/null"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text;
                if (!text) return;

                var lines = text.split('\n');
                var total = 0, available = 0;
                var cpuLine = "";
                var capacityRead = -1;
                var statusRead = "";

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.indexOf("MemTotal:") === 0) {
                        total = parseInt(line.match(/\d+/)[0]) || 0;
                    } else if (line.indexOf("MemAvailable:") === 0) {
                        available = parseInt(line.match(/\d+/)[0]) || 0;
                    } else if (line.indexOf("cpu ") === 0) {
                        cpuLine = line;
                    } else if (/^\d+$/.test(line)) {
                        capacityRead = parseInt(line);
                    } else if (line === "Charging" || line === "Discharging" || line === "Full" || line === "Not charging") {
                        statusRead = line;
                    }
                }

                if (total > 0) {
                    sysStats.memUsage = ((total - available) / total) * 100;
                }

                if (cpuLine) {
                    var parts = cpuLine.split(/\s+/);
                    var user = parseInt(parts[1]) || 0;
                    var nice = parseInt(parts[2]) || 0;
                    var system = parseInt(parts[3]) || 0;
                    var idle = parseInt(parts[4]) || 0;
                    var iowait = parseInt(parts[5]) || 0;
                    var irq = parseInt(parts[6]) || 0;
                    var softirq = parseInt(parts[7]) || 0;
                    var steal = parseInt(parts[8]) || 0;

                    var totalCpu = user + nice + system + idle + iowait + irq + softirq + steal;
                    var totalIdle = idle + iowait;

                    if (sysStats.lastCpu.total !== undefined) {
                        var diffTotal = totalCpu - sysStats.lastCpu.total;
                        var diffIdle = totalIdle - sysStats.lastCpu.idle;
                        if (diffTotal > 0) {
                            sysStats.cpuUsage = ((diffTotal - diffIdle) / diffTotal) * 100;
                        }
                    }

                    sysStats.lastCpu = { "total": totalCpu, "idle": totalIdle };
                }

                if (capacityRead >= 0) {
                    sysStats.batteryPercentage = capacityRead;
                }
                if (statusRead !== "") {
                    sysStats.batteryIsCharging = (statusRead === "Charging" || statusRead === "Full");
                }
            }
        }
    }

    property var statsTimer: Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statsProc.running = false;
            statsProc.running = true;
        }
    }
}
