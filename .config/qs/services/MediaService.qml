import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: mediaService

    property var activePlayer: null

    property string mediaStatus: "Stopped"
    property string mediaTitle: "No media playing"
    property string mediaArtist: ""
    property string mediaArtUrl: ""
    property int mediaPosition: 0
    property int mediaLength: 0

    readonly property bool isPlaying: mediaStatus === "Playing"
    readonly property bool rawHasMedia: (mediaStatus === "Playing" || mediaStatus === "Paused") && mediaTitle !== "" && mediaTitle !== "No media playing"

    property bool hasMedia: false

    function findActivePlayer() {
        var list = Mpris.players.values;
        if (!list || list.length === 0) return null;

        // 1. Keep currently active player if it is still playing
        if (activePlayer && list.indexOf(activePlayer) !== -1 && activePlayer.playbackState === MprisPlaybackState.Playing) {
            return activePlayer;
        }

        // 2. Find any player that is currently Playing
        for (var i = 0; i < list.length; i++) {
            var p = list[i];
            if (p && p.playbackState === MprisPlaybackState.Playing) {
                return p;
            }
        }

        // 3. Find any player that is Paused with a valid track title
        for (var j = 0; j < list.length; j++) {
            var q = list[j];
            if (q && q.playbackState === MprisPlaybackState.Paused && q.trackTitle) {
                return q;
            }
        }

        // 4. Retain active player if it still exists in the player list
        if (activePlayer && list.indexOf(activePlayer) !== -1) {
            return activePlayer;
        }

        // 5. Fallback to first player
        return list[0];
    }

    function updateActivePlayer() {
        activePlayer = findActivePlayer();
        syncMediaData();
    }

    function syncMediaData() {
        if (!activePlayer) {
            if (hasMedia) {
                gracePeriodTimer.restart();
            } else {
                resetMedia();
            }
            return;
        }

        var st = MprisPlaybackState.toString(activePlayer.playbackState) || "Stopped";
        var title = (activePlayer.trackTitle || "").trim();
        var artist = (activePlayer.trackArtist || "").trim();
        var artUrl = activePlayer.trackArtUrl || "";
        var len = Math.round(activePlayer.length || 0);
        var pos = Math.round(activePlayer.position || 0);

        if (st === "Playing" || st === "Paused") {
            if (title === "") {
                title = "Media";
            }
            gracePeriodTimer.stop();
            hasMedia = true;
            mediaStatus = st;
            mediaTitle = title;
            mediaArtist = artist;
            mediaArtUrl = artUrl;
            mediaLength = len;
            mediaPosition = pos;
        } else {
            mediaStatus = st;
            if (hasMedia) {
                gracePeriodTimer.restart();
            } else {
                resetMedia();
            }
        }
    }

    function onPlayerPositionChanged(player) {
        if (player === activePlayer && player.position !== undefined) {
            mediaPosition = Math.round(player.position);
        }
    }

    // Instantiator watches all players and connects to their state changes dynamically
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            target: modelData
            function onPlaybackStateChanged() { mediaService.updateActivePlayer(); }
            function onTrackTitleChanged() { mediaService.updateActivePlayer(); }
            function onTrackArtistChanged() { mediaService.updateActivePlayer(); }
            function onTrackArtUrlChanged() { mediaService.updateActivePlayer(); }
            function onLengthChanged() { mediaService.updateActivePlayer(); }
            function onPositionChanged() { mediaService.onPlayerPositionChanged(modelData); }
        }
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            mediaService.updateActivePlayer();
        }
    }

    Timer {
        id: gracePeriodTimer
        interval: 2800
        repeat: false
        onTriggered: {
            if (!mediaService.rawHasMedia) {
                mediaService.resetMedia();
            }
        }
    }

    function resetMedia() {
        hasMedia = false;
        mediaStatus = "Stopped";
        mediaTitle = "No media playing";
        mediaArtist = "";
        mediaArtUrl = "";
        mediaPosition = 0;
        mediaLength = 0;
    }

    // Smooth position increment ticker while playing
    Timer {
        id: progressTicker
        interval: 1000
        running: mediaService.isPlaying && mediaService.mediaLength > 0
        repeat: true
        onTriggered: {
            if (mediaService.mediaPosition < mediaService.mediaLength) {
                mediaService.mediaPosition += 1;
            }
        }
    }

    function playPause() {
        if (activePlayer) {
            activePlayer.togglePlaying();
        }
    }

    function next() {
        if (activePlayer && activePlayer.canGoNext) {
            activePlayer.next();
        }
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious) {
            activePlayer.previous();
        }
    }

    function seek(seconds) {
        if (activePlayer && activePlayer.canSeek) {
            activePlayer.position = seconds;
            mediaPosition = seconds;
        }
    }

    function refresh() {
        updateActivePlayer();
    }

    Component.onCompleted: {
        updateActivePlayer();
    }
}
