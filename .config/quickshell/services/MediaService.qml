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
    readonly property bool hasMedia: mediaStatus !== "Stopped" && mediaTitle !== "" && mediaTitle !== "No media playing"

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
        id: pollTimer
        interval: mediaService.isPlaying ? 1000 : 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            mediaFetcher.running = false;
            mediaFetcher.running = true;
        }
    }

    Process {
        id: mediaFetcher
        command: ["playerctl", "metadata", "--format", "{{status}}::{{title}}::{{artist}}::{{position}}::{{mpris:length}}::{{mpris:artUrl}}"]

        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text ? this.text.trim() : "";
                if (text !== "") {
                    var parts = text.split('::');
                    mediaService.mediaStatus = parts[0] || "Stopped";
                    mediaService.mediaTitle = parts[1] || "No media playing";
                    mediaService.mediaArtist = parts[2] || "";
                    var posUs = parseInt(parts[3]) || 0;
                    var lenUs = parseInt(parts[4]) || 0;
                    mediaService.mediaPosition = Math.round(posUs / 1000000);
                    mediaService.mediaLength = Math.round(lenUs / 1000000);
                    mediaService.mediaArtUrl = parts[5] || "";
                } else {
                    mediaService.mediaStatus = "Stopped";
                    mediaService.mediaTitle = "No media playing";
                    mediaService.mediaArtist = "";
                    mediaService.mediaPosition = 0;
                    mediaService.mediaLength = 0;
                    mediaService.mediaArtUrl = "";
                }
            }
        }
    }

    Timer {
        id: postActionFetchTimer
        interval: 350
        repeat: false
        onTriggered: {
            pollTimer.restart();
            mediaFetcher.running = false;
            mediaFetcher.running = true;
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
            pollTimer.restart();
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
        mediaFetcher.running = false;
        mediaFetcher.running = true;
    }
}
