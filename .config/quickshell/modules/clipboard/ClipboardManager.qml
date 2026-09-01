import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./components"
import "../../components/containers"
import "../../components/ui" as UI

Popup {
    id: clipWindow

    popupWidth: 480

    readonly property int chromeHeight: 140
    readonly property int itemRowHeight: 52
    readonly property int maxVisibleItems: 7

    property var clipService
    property string searchQuery: ""
    property var filteredEntriesList: []

    function updateFilteredList() {
        filteredEntriesList = getFilteredEntries();
    }

    popupHeight: (filteredEntriesList.length === 0)
        ? 310
        : (chromeHeight + Math.min(maxVisibleItems, filteredEntriesList.length) * itemRowHeight)

    closeOnHoverOutside: false

    function getFilteredEntries() {
        if (!clipService || !clipService.entries) return [];
        var rawQuery = searchQuery.trim();
        var lowerRaw = rawQuery.toLowerCase();

        var isPinSearch = lowerRaw.startsWith(">pin") || lowerRaw.startsWith(">p") || lowerRaw.startsWith("pin:");
        var pinQuery = "";
        if (isPinSearch) {
            if (lowerRaw.startsWith(">pin")) pinQuery = lowerRaw.substring(4).trim();
            else if (lowerRaw.startsWith(">p")) pinQuery = lowerRaw.substring(2).trim();
            else if (lowerRaw.startsWith("pin:")) pinQuery = lowerRaw.substring(4).trim();
        }

        var source = clipService.entries;
        var scored = [];

        if (isPinSearch) {
            for (var k = 0; k < source.length; k++) {
                var pEntry = source[k];
                if (!clipService.isPinned(pEntry)) continue;

                var pClean = pEntry.indexOf("\t") !== -1 ? pEntry.substring(pEntry.indexOf("\t") + 1).toLowerCase() : pEntry.toLowerCase();
                if (pinQuery === "" || pClean.indexOf(pinQuery) !== -1) {
                    scored.push({ entry: pEntry, score: 1000 - k });
                }
            }
            scored.sort((a, b) => b.score - a.score);
            var pinRes = [];
            for (var p = 0; p < scored.length; p++) {
                pinRes.push(scored[p].entry);
            }
            return pinRes;
        }

        if (rawQuery === "") {
            var pinned = [];
            var unpinned = [];
            for (var i = 0; i < source.length; i++) {
                var e = source[i];
                if (clipService.isPinned(e)) pinned.push(e);
                else unpinned.push(e);
            }
            return pinned.concat(unpinned);
        }

        var query = lowerRaw;
        for (var j = 0; j < source.length; j++) {
            var entry = source[j];
            var cleanText = entry.indexOf("\t") !== -1 ? entry.substring(entry.indexOf("\t") + 1).toLowerCase() : entry.toLowerCase();
            var isP = clipService.isPinned(entry);

            var score = 0;
            if (cleanText === query) {
                score += 1000;
            } else if (cleanText.indexOf(query) === 0) {
                score += 500;
            } else if (cleanText.indexOf(" " + query) !== -1) {
                score += 300;
            } else if (cleanText.indexOf(query) !== -1) {
                score += 150;
            }

            if (score > 0) {
                if (isP) score += 2000;
                score += Math.max(0, 50 - Math.abs(cleanText.length - query.length)) + Math.max(0, 30 - j);
                scored.push({ entry: entry, score: score });
            }
        }

        scored.sort((a, b) => b.score - a.score);
        var res = [];
        for (var m = 0; m < scored.length; m++) {
            res.push(scored[m].entry);
        }
        return res;
    }

    Connections {
        target: clipService ? clipService : null
        function onEntriesChanged() { clipWindow.updateFilteredList(); }
        function onPinnedEntriesChanged() { clipWindow.updateFilteredList(); }
    }

    onActiveChanged: {
        if (active) {
            searchQuery = "";
            searchInput.text = "";
            if (clipService) clipService.refresh();
            updateFilteredList();
            Qt.callLater(() => searchInput.forceFocus());
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: clipWindow.active
        onActivated: clipWindow.active = false
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8

        UI.Input {
            id: searchInput
            Layout.fillWidth: true
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            theme: clipWindow.theme
            placeholder: "Search clipboard... (type >pin for pin item)"
            icon: ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getIcon("actions/search.svg")

            onTextChanged: {
                clipWindow.searchQuery = text;
                clipWindow.updateFilteredList();
            }
            onEscapePressed: clipWindow.active = false

            onDownPressed: {
                if (entriesList.count > 0) {
                    entriesList.currentIndex = Math.min(entriesList.count - 1, (entriesList.currentIndex < 0 ? 0 : entriesList.currentIndex + 1));
                    entriesList.forceActiveFocus();
                }
            }

            onUpPressed: {
                if (entriesList.count > 0) {
                    entriesList.currentIndex = Math.max(0, entriesList.currentIndex - 1);
                }
            }

            onReturnPressed: {
                if (entriesList.count > 0) {
                    var targetIdx = (entriesList.currentIndex >= 0 && entriesList.currentIndex < entriesList.count) ? entriesList.currentIndex : 0;
                    var entry = entriesList.getEntryAt(targetIdx);
                    if (entry) {
                        clipWindow.clipService.copyEntry(entry);
                        clipWindow.active = false;
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: -2
            Layout.rightMargin: -2
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            height: 1
            color: clipWindow.theme ? clipWindow.theme.getColor("outlineVariant") : "#20FFFFFF"
            opacity: 0.35
        }

        UI.EmptyState {
            id: emptyState
            Layout.fillWidth: true
            Layout.fillHeight: true
            theme: clipWindow.theme
            searchQuery: clipWindow.searchQuery
            defaultIcon: clipWindow.searchQuery === "" ? "actions/image-copy.svg" : "actions/search.svg"
            title: clipWindow.searchQuery === "" ? "Clipboard is empty" : "No matching items found"
            subtitle: clipWindow.searchQuery !== "" ? "Try searching for a different keyword" : ""
            visible: clipWindow.filteredEntriesList.length === 0
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: clipWindow.filteredEntriesList.length > 0

            EntriesList {
                id: entriesList
                anchors.fill: parent
                theme: clipWindow.theme
                clipService: clipWindow.clipService
                searchQuery: clipWindow.searchQuery
                entriesModel: clipWindow.filteredEntriesList

                onEntryClicked: entryText => {
                    clipWindow.clipService.copyEntry(entryText);
                    clipWindow.active = false;
                }

                onDeleteClicked: entryText => {
                    clipWindow.clipService.deleteEntry(entryText);
                    clipWindow.updateFilteredList();
                }

                onPinClicked: entryText => {
                    clipWindow.clipService.togglePin(entryText);
                    clipWindow.updateFilteredList();
                }

                onUpPressedAtStart: searchInput.forceFocus()
                onEscapePressed: clipWindow.active = false
            }
        }
    }
}
