import QtQuick
import Quickshell
import Quickshell.Io
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

    Process {
        id: browserTitleProc
        property string browserClass: "brave"
        command: [Quickshell.env("HOME") + "/.config/qs/c_tools/bin/alt_tab_clients", "title", browserClass]
        stdout: SplitParser {
            onRead: data => {
                var raw = data.trim();
                if (raw) {
                    var clean = raw.replace(/\s*-\s*(Brave|Google Chrome|Chromium|Firefox).*$/i, "").trim();
                    if (clean && mediaService.hasMedia && (!mediaService.mediaTitle || mediaService.mediaTitle === "Media" || mediaService.mediaTitle === "Playing Media")) {
                        mediaService.mediaTitle = clean;
                    }
                }
            }
        }
    }

    function fetchBrowserFallbackTitle(ident) {
        var cls = "brave";
        var idLower = (ident || "").toLowerCase();
        if (idLower.indexOf("chrome") !== -1) cls = "chrome";
        else if (idLower.indexOf("firefox") !== -1) cls = "firefox";
        else if (idLower.indexOf("chromium") !== -1) cls = "chromium";
        else if (idLower.indexOf("brave") !== -1) cls = "brave";
        else cls = idLower.split(" ")[0] || "brave";

        browserTitleProc.browserClass = cls;
        browserTitleProc.running = false;
        Qt.callLater(() => { browserTitleProc.running = true; });
    }

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
        var pos = (activePlayer.positionSupported && activePlayer.position !== undefined) ? Math.round(activePlayer.position || 0) : 0;

        // 1. Fallback to metadata dictionary if trackTitle is empty
        if (!title && activePlayer.metadata) {
            var meta = activePlayer.metadata;
            title = (meta["xesam:title"] || meta["title"] || "").toString().trim();
            if (!artist) {
                var mArt = meta["xesam:artist"] || meta["artist"];
                if (Array.isArray(mArt) && mArt.length > 0) artist = mArt.join(", ").trim();
                else if (typeof mArt === "string") artist = mArt.trim();
            }
        }

        if (st === "Playing" || st === "Paused") {
            var isBrowser = false;
            var ident = (activePlayer.identity || "").toLowerCase();
            if (ident.indexOf("brave") !== -1 || ident.indexOf("chrome") !== -1 || ident.indexOf("firefox") !== -1 || ident.indexOf("chromium") !== -1) {
                isBrowser = true;
            }

            if (title === "" || title === "Media") {
                if (isBrowser) {
                    fetchBrowserFallbackTitle(activePlayer.identity);
                    title = "Media";
                } else if (activePlayer.identity) {
                    title = activePlayer.identity;
                } else {
                    title = "Media";
                }
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
        if (player && player === activePlayer && player.positionSupported && player.position !== undefined) {
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
            function onMetadataChanged() { mediaService.updateActivePlayer(); }
            function onTrackChanged() { mediaService.updateActivePlayer(); }
            function onLengthChanged() { mediaService.updateActivePlayer(); }
        }
    }

    // Only monitor position changes and real-time updates on the currently active player
    Connections {
        target: mediaService.activePlayer
        function onPlaybackStateChanged() { mediaService.syncMediaData(); }
        function onTrackTitleChanged() { mediaService.syncMediaData(); }
        function onTrackArtistChanged() { mediaService.syncMediaData(); }
        function onTrackArtUrlChanged() { mediaService.syncMediaData(); }
        function onMetadataChanged() { mediaService.syncMediaData(); }
        function onTrackChanged() { mediaService.syncMediaData(); }
        function onPositionChanged() {
            if (mediaService.activePlayer && mediaService.activePlayer.positionSupported) {
                mediaService.onPlayerPositionChanged(mediaService.activePlayer);
            }
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
        if (activePlayer && activePlayer.canSeek && activePlayer.positionSupported) {
            try {
                activePlayer.position = seconds;
                mediaPosition = seconds;
            } catch (e) {}
        }
    }

    function refresh() {
        updateActivePlayer();
    }

    Component.onCompleted: {
        updateActivePlayer();
    }
}
