import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property list<string> entries: []
    property var imagePreviews: ({})

    function shellEscape(str) {
        return str.replace(/'/g, "'\\''");
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
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | cliphist delete", "cliphist-delete", entry]);
        refreshTimer.restart();
    }

    function wipe() {
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

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Clipboard readProc stderr:", this.text);
                }
            }
        }
    }

    property var imgProc: Process {
        id: imgProc
        command: ["python3", shellConfig.getScript("decode_clip_images.py")]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text);
                    root.imagePreviews = parsed;
                } catch(e) {
                    console.error("Failed to parse image previews:", e);
                }
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

    Component.onCompleted: refresh()
}
