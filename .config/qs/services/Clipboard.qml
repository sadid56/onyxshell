import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

QtObject {
    id: root

    property Paths paths: Paths {}
    property list<string> entries: []
    property var imagePreviews: ({})
    property var pinnedEntries: []

    function getEntryContent(entryText) {
        if (!entryText) return "";
        var tabIdx = entryText.indexOf("\t");
        return tabIdx !== -1 ? entryText.substring(tabIdx + 1) : entryText;
    }

    function isPinned(entryText) {
        if (!entryText) return false;
        var content = getEntryContent(entryText);
        return root.pinnedEntries.indexOf(content) !== -1;
    }

    function togglePin(entryText) {
        if (!entryText) return;
        var content = getEntryContent(entryText);
        var arr = root.pinnedEntries.slice();
        var idx = arr.indexOf(content);
        if (idx !== -1) {
            arr.splice(idx, 1);
        } else {
            arr.push(content);
        }
        root.pinnedEntries = arr;
        savePinned();
    }

    readonly property string cacheDir: (paths && paths.cacheDir) ? paths.cacheDir : ((Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/qs")
    readonly property string pinnedFilePath: cacheDir + "/pinned_clips.json"

    function savePinned() {
        var jsonStr = JSON.stringify(root.pinnedEntries);
        Quickshell.execDetached(["bash", "-c", "mkdir -p \"$2\" && printf '%s' \"$1\" > \"$2/pinned_clips.json\"", "save-pinned", jsonStr, root.cacheDir]);
    }

    property var pinnedFile: FileView {
        id: pinnedFile
        path: root.pinnedFilePath
        watchChanges: true
        onTextChanged: {
            var txt = (typeof pinnedFile.text === "function") ? pinnedFile.text() : pinnedFile.text;
            if (txt && txt.trim().length > 0) {
                try {
                    var parsed = JSON.parse(txt);
                    if (Array.isArray(parsed)) {
                        root.pinnedEntries = parsed;
                    }
                } catch(e) {}
            }
        }
    }

    function refresh() {
        readProc.running = false;
        readProc.running = true;
    }

    function refreshImages() {
        imgProc.running = false;
        imgProc.running = true;
    }

    function copyEntry(entry) {
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "cliphist-copy", entry]);
    }

    function deleteEntry(entry) {
        if (isPinned(entry)) {
            togglePin(entry);
        }
        var arr = root.entries.slice();
        var idx = arr.indexOf(entry);
        if (idx !== -1) {
            arr.splice(idx, 1);
            root.entries = arr;
        }
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | cliphist delete", "cliphist-delete", entry]);
        refreshTimer.restart();
    }

    function wipe() {
        root.entries = [];
        root.imagePreviews = ({});
        Quickshell.execDetached(["cliphist", "wipe"]);
        refreshTimer.restart();
    }

    function getImagePreview(entryText) {
        var tabIdx = entryText.indexOf("\t");
        if (tabIdx === -1) return "";
        var entryId = entryText.substring(0, tabIdx).trim();
        if (root.imagePreviews && root.imagePreviews[entryId]) {
            return root.imagePreviews[entryId];
        }
        return "";
    }

    function isImageEntry(entryText) {
        return entryText.indexOf("[[ binary data") !== -1;
    }

    property var readProc: Process {
        id: readProc
        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var arr = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line !== "") {
                        arr.push(line);
                    }
                }
                root.entries = arr;
                root.refreshImages();
            }
        }
    }

    property var imgProc: Process {
        id: imgProc
        command: [root.paths.decodeClip]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text);
                    root.imagePreviews = parsed;
                } catch(e) {}
            }
        }
    }

    property var clipboardConnection: Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            refreshTimer.restart();
        }
    }

    property var refreshTimer: Timer {
        id: refreshTimer
        interval: 300
        running: false
        repeat: false
        onTriggered: refresh()
    }

    Component.onCompleted: {
        var txt = (typeof pinnedFile.text === "function") ? pinnedFile.text() : pinnedFile.text;
        if (txt && txt.trim().length > 0) {
            try {
                var parsed = JSON.parse(txt);
                if (Array.isArray(parsed)) {
                    root.pinnedEntries = parsed;
                }
            } catch(e) {}
        }
        refresh();
    }
}
