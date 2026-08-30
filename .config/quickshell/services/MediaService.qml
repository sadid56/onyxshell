import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: mediaService

    property string mediaStatus: "Stopped"
    property string mediaTitle: "No media playing"
    property string mediaArtist: ""
    property string mediaArtUrl: ""
    property int mediaPosition: 0
    property int mediaLength: 0

    readonly property bool isPlaying: mediaStatus === "Playing"
    readonly property bool hasMedia: (mediaStatus === "Playing" || mediaStatus === "Paused") && mediaTitle !== "" && mediaTitle !== "No media playing"

    function resetMedia() {
        mediaStatus = "Stopped";
        mediaTitle = "No media playing";
        mediaArtist = "";
        mediaArtUrl = "";
        mediaPosition = 0;
        mediaLength = 0;
    }

    Timer {
        id: progressTicker
        interval: 1000
        running: mediaService.isPlaying
        repeat: true
        onTriggered: {
            if (mediaService.mediaPosition < mediaService.mediaLength) {
                mediaService.mediaPosition += 1;
            }
        }
    }

    Timer {
        id: sanityCheckTimer
        interval: 2000
        repeat: true
        running: mediaService.hasMedia
        onTriggered: {
            statusChecker.running = false;
            statusChecker.running = true;
        }
    }

    Process {
        id: statusChecker
        command: ["playerctl", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var txt = this.text ? this.text.trim().toLowerCase() : "";
                if (txt === "" || txt === "stopped" || txt.indexOf("no players") !== -1) {
                    mediaService.resetMedia();
                }
            }
        }
    }

    Process {
        id: mediaFollower
        command: ["playerctl", "metadata", "--follow", "--format", "{{status}}::{{title}}::{{artist}}::{{position}}::{{mpris:length}}::{{mpris:artUrl}}"]
        running: true

        onExited: (exitCode, exitStatus) => {
            mediaService.resetMedia();
            restartTimer.restart();
        }

        stdout: SplitParser {
            onRead: data => {
                var text = data ? data.trim() : "";
                if (text === "") {
                    mediaService.resetMedia();
                    return;
                }
                var parts = text.split("::");
                var st = parts[0] || "Stopped";
                if (st === "Stopped") {
                    mediaService.resetMedia();
                    return;
                }
                mediaService.mediaStatus = st;
                mediaService.mediaTitle = parts[1] || "No media playing";
                mediaService.mediaArtist = parts[2] || "";
                var posUs = parseInt(parts[3]) || 0;
                var lenUs = parseInt(parts[4]) || 0;
                mediaService.mediaPosition = Math.round(posUs / 1000000);
                mediaService.mediaLength = Math.round(lenUs / 1000000);
                mediaService.mediaArtUrl = parts[5] || "";
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 3000
        repeat: false
        onTriggered: {
            mediaFollower.running = false;
            mediaFollower.running = true;
        }
    }

    Timer {
        id: postActionFetchTimer
        interval: 350
        repeat: false
        onTriggered: {
            positionFetcher.running = false;
            positionFetcher.running = true;
        }
    }

    Process {
        id: positionFetcher
        command: ["playerctl", "metadata", "--format", "{{status}}::{{title}}::{{artist}}::{{position}}::{{mpris:length}}::{{mpris:artUrl}}"]
        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text ? this.text.trim() : "";
                if (text === "") {
                    mediaService.resetMedia();
                    return;
                }
                var parts = text.split("::");
                var st = parts[0] || "Stopped";
                if (st === "Stopped") {
                    mediaService.resetMedia();
                    return;
                }
                mediaService.mediaStatus = st;
                mediaService.mediaTitle = parts[1] || "No media playing";
                mediaService.mediaArtist = parts[2] || "";
                var posUs = parseInt(parts[3]) || 0;
                var lenUs = parseInt(parts[4]) || 0;
                mediaService.mediaPosition = Math.round(posUs / 1000000);
                mediaService.mediaLength = Math.round(lenUs / 1000000);
                mediaService.mediaArtUrl = parts[5] || "";
            }
        }
    }

    Process {
        id: mediaActionProc
        function execute(cmd) {
            command = ["playerctl", cmd];
            running = false;
            running = true;
            postActionFetchTimer.restart();
        }
    }

    Process {
        id: mediaSeekProc
        function seekTo(seconds) {
            command = ["playerctl", "position", String(seconds)];
            running = false;
            running = true;
            mediaService.mediaPosition = seconds;
            postActionFetchTimer.restart();
        }
    }

    function playPause() {
        mediaService.mediaStatus = (mediaService.mediaStatus === "Playing" ? "Paused" : "Playing");
        mediaActionProc.execute("play-pause");
    }

    function next() {
        mediaActionProc.execute("next");
    }

    function previous() {
        mediaActionProc.execute("previous");
    }

    function seek(seconds) {
        mediaSeekProc.seekTo(seconds);
    }

    function refresh() {
        positionFetcher.running = false;
        positionFetcher.running = true;
    }
}
