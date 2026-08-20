import QtQuick
import Quickshell.Io

Item {
    id: statsService
    property var notifWindow

    Process {
        id: statsFetcher
        command: ["sh", "-c", "echo \"VOL: $(wpctl get-volume @DEFAULT_AUDIO_SINK@)\"; echo \"MIC: $(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)\"; echo \"BRI: $(brightnessctl -m)\"; echo \"WIFI: $(nmcli radio wifi 2>/dev/null)\"; echo \"PPD: $(powerprofilesctl get 2>/dev/null)\"; echo \"UP: $(uptime -p 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split('\n');
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.indexOf("VOL:") === 0) {
                        var vStr = line.substring(4).trim();
                        var match = vStr.match(/Volume:\s+([0-9.]+)/);
                        var rawVol = match ? Math.round(parseFloat(match[1]) * 100) : 50;
                        var isMute = vStr.indexOf("[MUTED]") !== -1;
                        if (isMute) {
                            notifWindow.isMuted = true;
                            if (rawVol > 0) notifWindow.lastUnmutedVolume = rawVol;
                            notifWindow.volumeValue = 0;
                        } else {
                            notifWindow.isMuted = false;
                            notifWindow.volumeValue = rawVol;
                            if (rawVol > 0) notifWindow.lastUnmutedVolume = rawVol;
                        }
                    } else if (line.indexOf("MIC:") === 0) {
                        var mStr = line.substring(4).trim();
                        var matchM = mStr.match(/Volume:\s+([0-9.]+)/);
                        if (matchM) notifWindow.micValue = Math.round(parseFloat(matchM[1]) * 100);
                        notifWindow.isMicMuted = mStr.indexOf("[MUTED]") !== -1;
                    } else if (line.indexOf("BRI:") === 0) {
                        var bStr = line.substring(4).trim();
                        var parts = bStr.split(',');
                        if (parts.length >= 4) {
                            var val = parseInt(parts[3].replace('%', ''));
                            if (!isNaN(val)) notifWindow.brightnessValue = val;
                        }
                    } else if (line.indexOf("WIFI:") === 0) {
                        notifWindow.wifiEnabled = (line.substring(5).trim().indexOf("enabled") !== -1);
                    } else if (line.indexOf("PPD:") === 0) {
                        var ppd = line.substring(4).trim();
                        if (ppd !== "") notifWindow.currentProfile = ppd;
                    } else if (line.indexOf("UP:") === 0) {
                        var up = line.substring(3).trim();
                        if (up !== "") {
                            var str = up.replace(/^up\s+/i, "").trim().replace(/,\s*/g, " ");
                            str = str.replace(/\bhours?\b/gi, "h").replace(/\bminutes?\b/gi, "m").replace(/\bdays?\b/gi, "d");
                            notifWindow.uptimeStr = "Up " + str.replace(/(\d+)\s+([hmd])/gi, "$1$2").trim();
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 2000
        running: notifWindow.active
        repeat: true
        onTriggered: fetch()
    }

    function fetch() {
        statsFetcher.running = false;
        statsFetcher.running = true;
    }
}
