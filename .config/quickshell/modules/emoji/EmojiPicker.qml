import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "./components"
import "../../components/containers"
import "../../components/ui" as UIInputs

Popup {
    id: emojiWindow
    popupWidth: 520
    popupHeight: 500
    closeOnHoverOutside: false

    property string searchQuery: ""
    property var allEmojis: []
    property var hoveredEmojiInfo: null

    property var emojiProc: Process {
        id: emojiProc
        command: ["cat", (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).assetsDir + "/emojis.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var txt = this.text ? this.text.trim() : "";
                    if (txt) {
                        var parsed = JSON.parse(txt);
                        if (parsed && parsed.length > 0) emojiWindow.allEmojis = parsed;
                    }
                } catch(e) {}
            }
        }
    }

    Component.onCompleted: emojiProc.running = true

    Process {
        id: copyProc
    }

    function copyEmoji(emojiChar, emojiName) {
        copyProc.command = ["sh", "-c", "echo -n '" + emojiChar + "' | wl-copy"];
        copyProc.running = true;
        if (typeof popupManager !== "undefined" && popupManager.toastPopup) {
            popupManager.toastPopup.showToast({
                summary: "Emoji Copied " + emojiChar,
                body: "Copied \"" + emojiName + "\" to clipboard."
            });
        }
        emojiWindow.active = false;
    }

    function getFilteredEmojis() {
        if (searchQuery === "") return allEmojis;
        var q = searchQuery.trim().toLowerCase();
        var res = [];
        for (var i = 0; i < allEmojis.length; i++) {
            var item = allEmojis[i];
            if (item.n.toLowerCase().indexOf(q) !== -1 || (item.k && item.k.toLowerCase().indexOf(q) !== -1)) {
                res.push(item);
            }
        }
        return res;
    }

    onActiveChanged: {
        if (active) {
            searchInput.forceFocus();
            if (allEmojis.length === 0) {
                emojiProc.running = false;
                emojiProc.running = true;
            }
        } else {
            searchInput.text = "";
            searchQuery = "";
        }
    }

    UIInputs.Input {
        id: searchInput
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        theme: emojiWindow.theme
        placeholder: "Search emojis..."
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("search.svg")
        onTextChanged: {
            emojiWindow.searchQuery = text;
            emojiGrid.currentIndex = emojiGrid.count > 0 ? 0 : -1;
        }
        onEscapePressed: emojiWindow.active = false
        onDownPressed: {
            if (emojiGrid.count > 0) {
                if (emojiGrid.currentIndex < 0) emojiGrid.currentIndex = 0;
                emojiGrid.focus = true;
            }
        }
        onReturnPressed: {
            var list = emojiWindow.getFilteredEmojis();
            var idx = emojiGrid.currentIndex >= 0 && emojiGrid.currentIndex < list.length ? emojiGrid.currentIndex : 0;
            if (list.length > 0) emojiWindow.copyEmoji(list[idx].e, list[idx].n);
        }
    }

    EmojiEmptyState {
        theme: emojiWindow.theme
        searchQuery: emojiWindow.searchQuery
        visible: emojiGrid.count === 0
    }

    GridView {
        id: emojiGrid
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        readonly property int columns: 8
        cellWidth: Math.floor(width / columns)
        cellHeight: cellWidth
        currentIndex: count > 0 ? 0 : -1
        boundsBehavior: Flickable.StopAtBounds
        model: emojiWindow.getFilteredEmojis()
        visible: count > 0

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down) {
                if (currentIndex + columns < count) currentIndex += columns;
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                if (currentIndex - columns >= 0) {
                    currentIndex -= columns;
                } else {
                    searchInput.forceFocus();
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                if (currentIndex > 0) currentIndex--;
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                if (currentIndex < count - 1) currentIndex++;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                var list = emojiWindow.getFilteredEmojis();
                if (currentIndex >= 0 && currentIndex < list.length) {
                    emojiWindow.copyEmoji(list[currentIndex].e, list[currentIndex].n);
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                emojiWindow.active = false;
                event.accepted = true;
            }
        }

        delegate: EmojiTile {
            theme: emojiWindow.theme
            emojiData: modelData
            isSelected: emojiGrid.currentIndex === index
            onClicked: (char, name) => {
                emojiGrid.currentIndex = index;
                emojiWindow.copyEmoji(char, name);
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 36
            z: 10
            enabled: false
            visible: emojiGrid.count > 30
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(emojiWindow.theme ? emojiWindow.theme.getColor("surface").r : 0.11, emojiWindow.theme ? emojiWindow.theme.getColor("surface").g : 0.11, emojiWindow.theme ? emojiWindow.theme.getColor("surface").b : 0.11, 0.0) }
                GradientStop { position: 1.0; color: emojiWindow.theme ? emojiWindow.theme.getColor("surface") : "#1b1b1b" }
            }
        }
    }
}
