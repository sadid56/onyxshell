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
    readonly property bool rawHasMedia: (mediaStatus === "Playing" || mediaStatus === "Paused") && mediaTitle !== "" && mediaTitle !== "No media playing"

    property bool hasMedia: false

    onRawHasMediaChanged: {
        if (rawHasMedia) {
            gracePeriodTimer.stop();
            hasMedia = true;
        } else if (hasMedia) {
            gracePeriodTimer.restart();
        }
    }

    Timer {
        id: gracePeriodTimer
        interval: 2800
        repeat: false
        onTriggered: {
            if (!mediaService.rawHasMedia) {
                mediaService.hasMedia = false;
                mediaService.mediaTitle = "No media playing";
                mediaService.mediaArtist = "";
                mediaService.mediaArtUrl = "";
                mediaService.mediaPosition = 0;
                mediaService.mediaLength = 0;
            }
        }
    }

    function resetMedia() {
        mediaStatus = "Stopped";
        if (hasMedia) {
            gracePeriodTimer.restart();
        } else {
            mediaTitle = "No media playing";
            mediaArtist = "";
            mediaArtUrl = "";
            mediaPosition = 0;
            mediaLength = 0;
        }
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
        interval: 3000
        repeat: true
        running: mediaService.hasMedia && !mediaService.isPlaying
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
                var title = (parts[1] || "").trim();
                var artist = (parts[2] || "").trim();
                if (title === "" && st === "Playing") {
                    title = "Media";
                }

                mediaService.mediaStatus = st;
                if (title !== "") {
                    mediaService.mediaTitle = title;
                }
                mediaService.mediaArtist = artist;
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
                var title = (parts[1] || "").trim();
                var artist = (parts[2] || "").trim();
                if (title === "" && st === "Playing") {
                    title = "Media";
                }

                mediaService.mediaStatus = st;
                if (title !== "") {
                    mediaService.mediaTitle = title;
                }
                mediaService.mediaArtist = artist;
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
